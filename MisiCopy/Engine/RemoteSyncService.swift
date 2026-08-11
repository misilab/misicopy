//
//  RemoteSyncService.swift
//  MisiCopy
//
//  Owns the "iPhone Remote" feature. Wraps a `LocalChannelServer` (local
//  Wi-Fi over Bonjour) and — in a future session — a CloudKit channel for
//  remote-from-anywhere monitoring.
//
//  The service exposes two knobs:
//    • `isEnabled` — persisted via UserDefaults, drives the listener
//    • `sharedSecret` — random 256-bit token, stored in Keychain, used by
//      both the pairing QR code (later) and the auth handshake
//
//  It observes the bound `CopyEngine` and pushes a `SessionSnapshot` every
//  `Self.broadcastInterval`. Commands received from the iPhone are routed
//  back into the engine on the main actor.
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class RemoteSyncService: LocalChannelServerDelegate {

    // MARK: - Observable state

    /// Master switch. Persisted to UserDefaults so the choice survives
    /// relaunches.
    var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: Self.enabledKey)
            if isEnabled { startIfNeeded() } else { stopIfRunning() }
        }
    }

    /// Number of currently-authenticated iPhone clients.
    private(set) var connectedClientsCount: Int = 0

    /// TCP port the local server is listening on (nil when stopped).
    var listeningPort: UInt16? { localServer?.listeningPort }

    /// Surfaces the CloudKit publisher's current state so Réglages can
    /// show the user whether iCloud is reachable, what the last error
    /// was (e.g. schema missing on the production environment), and when
    /// the last successful upload happened.
    var cloudStatus: CloudChannelPublisher.Status {
        cloudPublisher?.status ?? .idle
    }
    var cloudLastUploadAt: Date? {
        cloudPublisher?.lastUploadAt
    }

    /// First-resolved non-loopback IPv4 address of the Mac. Displayed in
    /// Réglages to help the user check what to type on the iPhone side.
    private(set) var displayHostname: String = Host.current().localizedName ?? "MisiCopy"

    /// Returns the current pairing token. Lazily generated on first read.
    var sharedSecret: String {
        if let cached = cachedSecret { return cached }
        if let stored = keychain.get(Self.keychainAccount) {
            cachedSecret = stored
            return stored
        }
        let fresh = Self.generateSecret()
        keychain.set(fresh, for: Self.keychainAccount)
        cachedSecret = fresh
        return fresh
    }

    // MARK: - Private

    private static let enabledKey = "remote_sync_enabled"
    private static let machineIDKey = "remote_sync_machine_id"
    private static let keychainAccount = "remote_sync_secret"
    private static let broadcastInterval: TimeInterval = 0.5

    private let keychain = KeychainStore()
    private var cachedSecret: String?

    private var localServer: LocalChannelServer?
    private var cloudPublisher: CloudChannelPublisher?
    private weak var engine: CopyEngine?
    private var observationTimer: Timer?

    // MARK: - Live Activity push relay

    private let pushRelay = LiveActivityPushRelay()
    /// APNs push tokens for active iPhone Live Activities, keyed by token,
    /// valued by the sessionID the activity tracks. A token for a newer
    /// session supersedes older ones.
    private var liveActivityTokens: [String: String] = [:]
    /// Throttle gate for progress pushes — APNs budgets Live Activity
    /// updates, so we relay at most ~1 every 1.5 s (terminal pushes are
    /// always sent immediately).
    private var lastLiveActivityPush: Date = .distantPast
    /// `"token|sessionID"` keys already sent their terminal `end` push, so
    /// we don't repeat it every tick after a job finishes.
    private var endedLiveActivityKeys: Set<String> = []

    /// Stable per-installation identifier. Used as CloudKit recordName so
    /// the iPhone reads the right Mac's session. Generated once and kept.
    private(set) var machineID: String

    init() {
        self.isEnabled = UserDefaults.standard.bool(forKey: Self.enabledKey)
        if let existing = UserDefaults.standard.string(forKey: Self.machineIDKey) {
            self.machineID = existing
        } else {
            let fresh = UUID().uuidString
            UserDefaults.standard.set(fresh, forKey: Self.machineIDKey)
            self.machineID = fresh
        }
    }

    // MARK: - Wiring

    /// Called once by `AppModel` after both engine and service exist.
    func bind(engine: CopyEngine) {
        self.engine = engine
        if isEnabled { startIfNeeded() }
    }

    /// Returns the JSON payload that should be encoded into the pairing
    /// QR code shown to the user. Reads (and lazily creates) the secret.
    func pairingPayload() -> PairingPayload {
        PairingPayload(machineName: displayHostname,
                       machineID: machineID,
                       sharedSecret: sharedSecret)
    }

    /// Replaces the current secret with a fresh one (any paired iPhone
    /// must be re-paired).
    func regenerateSecret() {
        let fresh = Self.generateSecret()
        keychain.set(fresh, for: Self.keychainAccount)
        cachedSecret = fresh
        // Restart the listener so new connections use the new secret.
        if isEnabled {
            stopIfRunning()
            startIfNeeded()
        }
    }

    // MARK: - Server lifecycle

    private func startIfNeeded() {
        guard localServer == nil else { return }
        let server = LocalChannelServer(
            sharedSecret: { [weak self] in self?.sharedSecret ?? "" },
            machineID: { [weak self] in self?.machineID ?? "" }
        )
        server.delegate = self
        server.start()
        localServer = server

        let publisher = CloudChannelPublisher(machineID: machineID)
        publisher.start()
        cloudPublisher = publisher

        startBroadcastTimer()
    }

    private func stopIfRunning() {
        observationTimer?.invalidate()
        observationTimer = nil
        localServer?.stop()
        localServer = nil
        cloudPublisher?.stop()
        cloudPublisher = nil
        connectedClientsCount = 0
        liveActivityTokens.removeAll()
        endedLiveActivityKeys.removeAll()
    }

    private func startBroadcastTimer() {
        observationTimer?.invalidate()
        let timer = Timer(timeInterval: Self.broadcastInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.broadcastTick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        observationTimer = timer
    }

    private func broadcastTick() {
        guard let engine, let server = localServer, server.isRunning else { return }
        let snapshot = makeSnapshot(from: engine)
        // Always feed CloudKit while the remote toggle is on. Without a
        // single write, the `ActiveSession` record type is never created
        // on a brand-new container and the iPhone polling sees
        // `.unknownItem` forever — chicken-and-egg. Privacy is bounded
        // by the user's explicit opt-in: `stop()` deletes the record.
        cloudPublisher?.update(snapshot)
        // Drive the iPhone Live Activity via APNs (through the relay) so
        // the lock-screen tile keeps ticking even when the companion app
        // is suspended. Independent of the WebSocket — the whole point is
        // to reach a suspended/locked iPhone.
        pushLiveActivityIfNeeded(snapshot)
        // Skip the WebSocket broadcast when nobody is listening on Wi-Fi.
        guard connectedClientsCount > 0 else { return }
        server.broadcast(.snapshot(snapshot))
    }

    /// Relays the current snapshot to every iPhone Live Activity registered
    /// for the active session. Progress pushes are throttled; the terminal
    /// (`finished` / `failed`) push is sent once, immediately, with an
    /// 8 s dismissal so the tile lingers on its final state before fading.
    private func pushLiveActivityIfNeeded(_ snapshot: SessionSnapshot) {
        guard !liveActivityTokens.isEmpty else { return }
        // Only push to tokens whose activity tracks the session currently
        // running on the Mac — stale tokens from a previous job are left
        // alone (their tile already ended).
        let activeTokens = liveActivityTokens.filter { $0.value == snapshot.sessionID }
        guard !activeTokens.isEmpty else { return }

        let liveStatus: String
        switch snapshot.status {
        case .running:  liveStatus = "running"
        case .paused:   liveStatus = "paused"
        case .finished: liveStatus = "finished"
        case .failed:   liveStatus = "failed"
        case .idle:     return   // nothing meaningful to show
        }
        let isTerminal = (snapshot.status == .finished || snapshot.status == .failed)

        let now = Date()
        if !isTerminal {
            guard now.timeIntervalSince(lastLiveActivityPush) >= 1.5 else { return }
        }
        lastLiveActivityPush = now

        let state = LiveActivityPushRelay.ContentState(
            status: liveStatus,
            progress: snapshot.progress,
            copiedCount: snapshot.copiedCount,
            failedCount: snapshot.failedCount,
            currentFile: snapshot.currentFile,
            bytesPerSecond: snapshot.bytesPerSecond,
            etaSeconds: snapshot.etaSeconds
        )
        // 5 minutes: covers slow copies (large RAW files, spinning archives)
        // where updates come infrequently. At 2 min the tile was going grey
        // mid-copy and looking "stuck" even though the Mac was still working.
        let staleDate = now.addingTimeInterval(300)

        // On the terminal push, attach a lock-screen banner (+ sound) so
        // the user gets a real notification the copy is done / failed even
        // while the iPhone is asleep. Text is localized to the Mac's UI
        // language via the engine's l10n.
        let terminalAlert: LiveActivityPushRelay.Alert? = {
            guard isTerminal, let l = engine?.l10n else { return nil }
            if snapshot.status == .finished {
                let bytes = engine?.formatBytes(snapshot.bytesTotal) ?? ""
                return .init(title: l.flashSuccessTitle,
                             body: l.flashSuccessSubtitle(verified: snapshot.verifiedCount, bytes: bytes))
            } else {
                return .init(title: l.flashFailureTitle,
                             body: l.flashFailureSubtitle(failed: snapshot.failedCount))
            }
        }()

        var tokensToDrop: [String] = []
        for (token, _) in activeTokens {
            if isTerminal {
                let key = "\(token)|\(snapshot.sessionID)"
                if endedLiveActivityKeys.contains(key) { continue }
                endedLiveActivityKeys.insert(key)
                tokensToDrop.append(token)   // token is invalid once it ends
                let relay = pushRelay
                let dismissal = now.addingTimeInterval(8)
                Task.detached { await relay.send(token: token, event: "end", state: state,
                                                 staleDate: staleDate, dismissalDate: dismissal,
                                                 priority: 10, alert: terminalAlert) }
            } else {
                let relay = pushRelay
                Task.detached { await relay.send(token: token, event: "update", state: state,
                                                 staleDate: staleDate, dismissalDate: nil,
                                                 priority: 5) }
            }
        }
        for token in tokensToDrop { liveActivityTokens.removeValue(forKey: token) }
    }

    // MARK: - Snapshot building

    private func makeSnapshot(from engine: CopyEngine) -> SessionSnapshot {
        var snap = SessionSnapshot(
            generatedAt: Date(),
            machineName: displayHostname,
            sessionID: makeSessionID(engine: engine),
            status: computeStatus(engine: engine),
            startedAt: engine.startDate,
            endedAt: engine.endDate,
            bytesProcessed: 0,
            bytesTotal: 0,
            filesProcessed: 0,
            filesTotal: 0,
            bytesPerSecond: 0,
            etaSeconds: nil,
            foundCount: 0,
            copiedCount: 0,
            verifiedCount: 0,
            failedCount: 0,
            currentFile: nil,
            mode: engine.l10n.modeTitle(engine.mode),
            algorithm: engine.algorithm.displayName,
            sourceNames: engine.sources.map { $0.displayName },
            destinationNames: engine.destinations.map { $0.displayName },
            recentErrors: collectRecentErrors(engine: engine)
        )
        let stats = engine.stats
        snap.bytesProcessed = stats.bytesProcessed
        snap.bytesTotal = stats.totalBytes
        snap.workBudget = stats.workBudget
        snap.workDone = stats.workDone
        snap.filesProcessed = stats.copied
        snap.filesTotal = stats.found
        snap.bytesPerSecond = Int64(stats.bytesPerSecond)
        snap.foundCount = stats.found
        snap.copiedCount = stats.copied
        snap.verifiedCount = stats.verified
        snap.failedCount = stats.failed
        snap.etaSeconds = computeETA(engine: engine)
        snap.currentFile = findCurrentFile(engine: engine)
        snap.recentLogs = collectRecentLogs(engine: engine)
        let (free, total) = collectDestinationCapacities(engine: engine)
        snap.destinationFreeBytes = free
        snap.destinationTotalBytes = total
        // Cascade phase: the cards are already released — tell the DIT
        // from their pocket. Pre-localized on the Mac side like `mode`.
        if engine.isCascading {
            snap.phaseLabel = engine.l10n.remotePhaseCascade
        }
        return snap
    }

    /// Reads free + total capacity for each destination so the iPhone can
    /// show "X GB free of Y GB" next to each drive. Returns parallel
    /// arrays — index N pairs with `destinationNames[N]`.
    ///
    /// `volumeAvailableCapacityForImportantUsageKey` is APFS/boot-volume
    /// oriented (it accounts for purgeable space) and returns 0 or nil on
    /// many external / exFAT drives — exactly the drives DITs use as
    /// destinations, which showed "0 KB free". So we fall back to the
    /// classic `volumeAvailableCapacityKey`, which is reliable on every
    /// filesystem, whenever the important-usage figure is missing or zero.
    private func collectDestinationCapacities(engine: CopyEngine) -> ([Int64], [Int64]) {
        var free: [Int64] = []
        var total: [Int64] = []
        let keys: Set<URLResourceKey> = [.volumeAvailableCapacityForImportantUsageKey,
                                         .volumeAvailableCapacityKey,
                                         .volumeTotalCapacityKey]
        for destination in engine.destinations {
            let values = try? destination.url.resourceValues(forKeys: keys)
            let importantUsage = Int64(values?.volumeAvailableCapacityForImportantUsage ?? 0)
            let classic = Int64(values?.volumeAvailableCapacity ?? 0)
            // Prefer the important-usage figure (matches Finder on APFS),
            // but fall back to the classic available capacity when it's
            // zero/unavailable (external + exFAT volumes).
            free.append(importantUsage > 0 ? importantUsage : classic)
            total.append(Int64(values?.volumeTotalCapacity ?? 0))
        }
        return (free, total)
    }

    /// Returns up to the last 30 journal entries, oldest → newest, ready to
    /// be displayed in chronological order on the iPhone.
    private func collectRecentLogs(engine: CopyEngine) -> [SnapshotLogLine] {
        let tail = engine.logs.suffix(30)
        return tail.map { entry in
            SnapshotLogLine(date: entry.date,
                            level: Self.wireLevel(for: entry.level),
                            message: String(entry.message.prefix(280)))
        }
    }

    private static func wireLevel(for level: LogLevel) -> SnapshotLogLine.Level {
        switch level {
        case .info:    return .info
        case .success: return .success
        case .warning: return .warning
        case .error:   return .error
        }
    }

    private func findCurrentFile(engine: CopyEngine) -> String? {
        for file in engine.files {
            switch file.status {
            case .copying, .verifying: return file.displayName
            default: continue
            }
        }
        return nil
    }

    private func makeSessionID(engine: CopyEngine) -> String {
        guard let start = engine.startDate else { return "—" }
        return "\(Int(start.timeIntervalSince1970))"
    }

    private func computeStatus(engine: CopyEngine) -> SessionSnapshot.Status {
        if engine.isPaused { return .paused }
        if engine.isRunning { return .running }
        if engine.endDate != nil {
            return engine.stats.failed > 0 ? .failed : .finished
        }
        return .idle
    }

    private func computeETA(engine: CopyEngine) -> Int? {
        let stats = engine.stats
        guard engine.isRunning, stats.bytesPerSecond > 0 else { return nil }
        // Use workBudget/workDone so the ETA accounts for the full pipeline
        // (copy + verification passes), matching what the progress bar tracks.
        let remaining: Int64
        if stats.workBudget > 0 {
            remaining = max(0, stats.workBudget - stats.workDone)
        } else {
            remaining = max(0, stats.totalBytes - stats.bytesProcessed)
        }
        return Int(Double(remaining) / stats.bytesPerSecond)
    }

    private func collectRecentErrors(engine: CopyEngine) -> [String] {
        let recent = engine.logs.suffix(50)
        let errorsOnly = recent.filter { $0.level == .error }
        return errorsOnly.suffix(5).map { String($0.message.prefix(200)) }
    }

    // MARK: - LocalChannelServerDelegate

    func localChannelDidAcceptClient() {
        connectedClientsCount += 1
    }

    func localChannelDidDropClient() {
        connectedClientsCount = max(0, connectedClientsCount - 1)
    }

    func localChannel(didReceive command: RemoteCommand) {
        guard let engine else { return }
        switch command {
        case .pause:
            if engine.isRunning && !engine.isPaused { engine.togglePause() }
        case .resume:
            if engine.isRunning && engine.isPaused { engine.togglePause() }
        case .cancel:
            if engine.isRunning { engine.cancel() }
        case .ping:
            break // server replies with .pong on its own (autoReplyPing handles WS ping)
        case .retryFailed:
            // The engine's own guards (no-op when running, no-op when zero
            // failed files) cover the race where the user hits retry on
            // the iPhone right as another command starts a new run on the
            // Mac, so we can call it unconditionally here.
            engine.retryFailedFiles()
        }
    }

    func localChannel(didReceiveLiveActivityToken token: String, sessionID: String) {
        // A token for a newer session supersedes tokens for older sessions
        // — the iPhone starts a fresh activity (and emits a new token) for
        // each job, so we never need to keep stale ones around.
        liveActivityTokens = liveActivityTokens.filter { $0.value == sessionID }
        liveActivityTokens[token] = sessionID
        endedLiveActivityKeys.remove("\(token)|\(sessionID)")
    }

    // MARK: - Helpers

    private static func generateSecret() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64EncodedString()
    }
}
