//
//  RemoteSession.swift
//  MisiCopyRemote
//
//  Drives the dashboard. Owns BOTH the local Wi-Fi WebSocket client and
//  the CloudKit subscriber, and picks the freshest snapshot to expose to
//  the UI. Local is preferred when available (sub-second latency); cloud
//  is used as a fallback so the iPhone keeps showing data even when off
//  the Mac's network.
//

import Foundation
import UserNotifications
import ActivityKit

@MainActor
@Observable
final class RemoteSession {
    enum ActiveChannel: Sendable {
        case none
        case local
        case cloud
    }

    enum Preference: String, Codable, Sendable, CaseIterable, Identifiable {
        case auto, localOnly, cloudOnly
        var id: String { rawValue }
        var displayName: String {
            switch self {
            case .auto: return "Automatique"
            case .localOnly: return "Local Wi-Fi"
            case .cloudOnly: return "iCloud"
            }
        }
        var icon: String {
            switch self {
            case .auto: return "arrow.triangle.2.circlepath"
            case .localOnly: return "wifi"
            case .cloudOnly: return "icloud"
            }
        }
    }

    let client = LocalChannelClient()
    let cloud = CloudChannelSubscriber()
    let demo = DemoSnapshotProvider()

    /// When true, both real channels are disconnected and `snapshot` is
    /// driven by a synthetic stream. Lets users (and the App Store
    /// reviewer) explore the full Dashboard / Stats / Journal / Controls
    /// UI without owning a Mac running MisiCopy.
    private(set) var isDemoMode: Bool = false

    /// User-controlled channel selection. Persisted across launches.
    var preference: Preference {
        didSet {
            UserDefaults.standard.set(preference.rawValue, forKey: Self.preferenceKey)
            // Reapply: if user switched to cloud-only, drop the WebSocket;
            // if switched to local-only, drop the cloud poller.
            applyPreferenceSideEffects()
        }
    }

    private static let preferenceKey = "remote_transport_preference"

    init() {
        if let raw = UserDefaults.standard.string(forKey: Self.preferenceKey),
           let pref = Preference(rawValue: raw) {
            self.preference = pref
        } else {
            self.preference = .auto
        }
        // Re-adopt any Live Activity that survived a previous launch so
        // the next snapshot updates the existing tile in place instead
        // of stacking a duplicate. Without this, force-quitting and
        // re-opening the app mid-job orphans the lock-screen tile.
        if let existing = Activity<CopyActivityAttributes>.activities.first {
            currentActivity = existing
            currentActivitySessionID = existing.attributes.sessionID
        }
        // Kick off the observation loops that keep `snapshot` in sync.
        watchLocalChannel()
        watchCloudChannel()
        watchDemoChannel()
        updateSnapshot()
    }

    private(set) var activeChannel: ActiveChannel = .none

    /// Stores the `(sessionID, terminalStatus)` key for which a local
    /// notification has already been delivered. Without this, a session
    /// that flips `finished -> failed -> finished` (e.g. user triggered
    /// a retry from the iPhone) would fire 3 notifications instead of
    /// just the terminal one.
    private var notifiedTerminalKeys: Set<String> = []

    /// Tracks the currently-displayed Live Activity so we update it in
    /// place instead of stacking duplicates. Cleared when the snapshot
    /// transitions to a terminal state.
    private var currentActivity: Activity<CopyActivityAttributes>?
    private var currentActivitySessionID: String?

    /// SessionIDs for which `Activity.request(...)` already threw. Without
    /// this guard we would re-fire the request on every snapshot tick
    /// (twice per second) for the whole copy job. Cleared whenever the
    /// Mac starts a new session.
    private var liveActivityFailedSessionIDs: Set<String> = []

    /// Latest ActivityKit push token + its session, cached so we can
    /// re-deliver it to the Mac after a WebSocket reconnect (the token
    /// itself doesn't change on reconnect, so ActivityKit won't re-emit
    /// it — we have to resend it ourselves).
    private var cachedLiveActivityToken: (token: String, sessionID: String)?

    /// Snapshot exposed to the view layer. Stored (not computed) so SwiftUI
    /// observes it directly on RemoteSession rather than through a multi-level
    /// @Observable chain. Updated by watchLocalChannel / watchCloudChannel /
    /// watchDemoChannel whenever the underlying channel data changes.
    private(set) var snapshot: SessionSnapshot?

    var status: LocalChannelClient.Status { client.status }

    /// Snapshot of the wire/discovery context, captured by `wire(...)` so
    /// preference changes after pairing can re-evaluate which channels
    /// should be live without the view layer having to pass the args
    /// back in.
    private var lastWireContext: (mac: PairedMac, discovery: LocalDiscovery, store: PairedMacStore)?

    func wire(mac: PairedMac, discovery: LocalDiscovery, store: PairedMacStore) {
        lastWireContext = (mac, discovery, store)
        // Cloud
        let cloudAllowed = preference != .localOnly
        if cloudAllowed, let id = mac.machineID {
            cloud.connect(machineID: id)
        } else {
            cloud.disconnect()
        }
        // Local
        let localAllowed = preference != .cloudOnly
        if localAllowed,
           let endpoint = discovery.endpoint(matching: mac),
           let secret = store.sharedSecret(for: mac), !secret.isEmpty {
            client.connect(to: endpoint, sharedSecret: secret)
            // Re-deliver any cached push token once the handshake has had
            // time to complete, so a token minted during a network blip
            // still reaches the Mac and the lock-screen tile resumes.
            Task { [weak self] in
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                await MainActor.run { self?.resendCachedLiveActivityToken() }
            }
        } else {
            client.disconnect()
        }
        refreshActiveChannel()
        updateSnapshot()
    }

    private func applyPreferenceSideEffects() {
        guard let ctx = lastWireContext else { return }
        // Re-resolve the currently active Mac from the store: the user may
        // have switched Macs since `wire(...)` was last called, and we
        // mustn't reconnect to a stale machineID.
        let liveMac = ctx.store.activeMac ?? ctx.mac
        wire(mac: liveMac, discovery: ctx.discovery, store: ctx.store)
    }

    func send(_ command: RemoteCommand) {
        // Commands only work over the local channel for now — CloudKit
        // is read-only in this version. Show a notice on the UI in a
        // future iteration if the user tries to send while only on cloud.
        if isDemoMode {
            demo.handle(command)
            return
        }
        client.send(command: command)
    }

    // MARK: - Demo mode

    func enableDemoMode() {
        isDemoMode = true
        client.disconnect()
        cloud.disconnect()
        demo.start()
        activeChannel = .none
        updateSnapshot()
    }

    func disableDemoMode() {
        demo.stop()
        isDemoMode = false
        if let ctx = lastWireContext {
            wire(mac: ctx.mac, discovery: ctx.discovery, store: ctx.store)
        }
    }

    func refreshActiveChannel() {
        if case .connected = client.status {
            activeChannel = .local
        } else if cloud.lastSnapshot != nil {
            activeChannel = .cloud
        } else {
            activeChannel = .none
        }
    }

    // MARK: - Snapshot observation

    /// Watches `client.lastSnapshot` and `client.status`. Fires `updateSnapshot()`
    /// on every change, then re-arms itself so the loop continues for the
    /// lifetime of the session. Using `withObservationTracking` here bypasses
    /// the multi-level @Observable chain that SwiftUI can miss when the
    /// intermediate reference (`client`) is a `let` constant.
    private func watchLocalChannel() {
        withObservationTracking {
            _ = client.lastSnapshot
            _ = client.status
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.updateSnapshot()
                self.watchLocalChannel()
            }
        }
    }

    private func watchCloudChannel() {
        withObservationTracking {
            _ = cloud.lastSnapshot
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.updateSnapshot()
                self.watchCloudChannel()
            }
        }
    }

    private func watchDemoChannel() {
        withObservationTracking {
            _ = isDemoMode
            _ = demo.snapshot
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.updateSnapshot()
                self.watchDemoChannel()
            }
        }
    }

    private func updateSnapshot() {
        if isDemoMode {
            snapshot = demo.snapshot
            return
        }
        switch preference {
        case .localOnly:
            snapshot = client.lastSnapshot
        case .cloudOnly:
            snapshot = cloud.lastSnapshot
        case .auto:
            if case .connected = client.status, let s = client.lastSnapshot {
                snapshot = s
            } else {
                snapshot = cloud.lastSnapshot
            }
        }
    }

    /// Should be called from the view layer whenever the snapshot changes
    /// so end-of-session notifications fire reliably AND the Live Activity
    /// stays in sync with the Mac's progress on the locked screen.
    func checkForCompletionNotification() {
        guard let snap = snapshot else { return }
        // Live Activity always tracks the latest snapshot, regardless of
        // status. The helper handles start / update / end internally.
        updateLiveActivity(for: snap)
        // The local notification only fires on the terminal transition,
        // and once per (sessionID, terminalStatus) pair so a retry that
        // flips the same session from .failed → .finished still triggers
        // a single fresh notification.
        let shouldNotify = (snap.status == .finished || snap.status == .failed)
        guard shouldNotify else { return }
        let key = "\(snap.sessionID)|\(snap.status.rawValue)"
        guard !notifiedTerminalKeys.contains(key) else { return }
        notifiedTerminalKeys.insert(key)
        // Always fire a local notification as a safety net. The Mac's
        // terminal APNs push (via the Live Activity end banner) may also
        // arrive independently, but network issues or Worker outages can
        // silently swallow that push — the local notification guarantees
        // the user is always alerted. iOS deduplicates by identifier
        // (`session_<sessionID>`), so a second call for the same session
        // is a no-op.
        fireLocalNotification(for: snap)
    }

    // MARK: - Live Activity

    /// Mirrors the Mac's session into an iOS Live Activity so the locked
    /// screen and the Dynamic Island stay in sync without the user
    /// unlocking the iPhone. The activity is started when a `running` /
    /// `paused` snapshot arrives without one already in flight, updated
    /// on every subsequent snapshot, and ended a few seconds after the
    /// session reaches `finished` or `failed`. Falls back silently when
    /// the device doesn't support Live Activities (simulator + old iOS).
    private func updateLiveActivity(for snap: SessionSnapshot) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let liveStatus: CopyActivityAttributes.ContentState.Status
        switch snap.status {
        case .running:  liveStatus = .running
        case .paused:   liveStatus = .paused
        case .finished: liveStatus = .finished
        case .failed:   liveStatus = .failed
        case .idle:
            // Idle means the Mac has been launched but no copy has ever
            // run — there's nothing meaningful to show on the lock screen.
            // End any leftover activity (e.g. user re-opened the app the
            // day after) so the lock screen doesn't keep a stale tile.
            endLiveActivity()
            return
        }

        // Don't spin up a tile for a job that's already over by the time
        // the iPhone connects. The completion notification still fires;
        // the lock screen just stays clean instead of flashing a 100%
        // tile that was never being watched live.
        let isTerminal = (liveStatus == .finished || liveStatus == .failed)
        if currentActivity == nil, isTerminal { return }

        let state = CopyActivityAttributes.ContentState(
            status: liveStatus,
            progress: snap.progress,
            copiedCount: snap.copiedCount,
            failedCount: snap.failedCount,
            currentFile: snap.currentFile,
            bytesPerSecond: snap.bytesPerSecond,
            etaSeconds: snap.etaSeconds
        )
        // Mark the tile stale after 5 minutes of silence. Slow copies on
        // spinning archives can take several minutes per file; the previous
        // 2-minute window made the tile go grey mid-copy even though the
        // Mac was still actively working.
        let staleDate = Date().addingTimeInterval(300)
        let content = ActivityContent(state: state, staleDate: staleDate)

        // Restart the activity if the session changed underneath us — the
        // user can run two different jobs on the same Mac in a row. The
        // failed-session set is also cleared so a previously-rejected
        // request can be retried for the new session.
        if let existing = currentActivity,
           currentActivitySessionID == snap.sessionID {
            Task { await existing.update(content) }
        } else {
            // Tear down any previous activity for a different session
            // before starting a fresh one — Apple caps in-flight
            // activities per app, and we never need more than one for
            // the currently-active Mac.
            endLiveActivity()
            // Do NOT remove snap.sessionID from liveActivityFailedSessionIDs
            // here. If Activity.request() already failed for this session,
            // removing the guard and retrying every 500 ms wastes resources
            // with zero chance of success. When a genuinely new session
            // starts its ID won't be in the set (timestamps differ), so the
            // first attempt always gets through.
            startLiveActivity(content: content, snapshot: snap)
        }

        // Auto-end on terminal status, with a slight delay so the user
        // sees the final "100 % · Terminé" before the tile is dismissed.
        // Guard against the race where the Mac immediately starts another
        // session within the 8 s window — without the sessionID guard the
        // deferred task would wipe the brand-new tile.
        if isTerminal {
            let endingSession = snap.sessionID
            Task { [weak self] in
                try? await Task.sleep(nanoseconds: 8_000_000_000)
                await MainActor.run {
                    guard self?.currentActivitySessionID == endingSession else { return }
                    self?.endLiveActivity()
                }
            }
        }
    }

    private func startLiveActivity(content: ActivityContent<CopyActivityAttributes.ContentState>,
                                   snapshot: SessionSnapshot) {
        // Skip if a previous request for this exact session already
        // failed — typically because Live Activities are disabled in
        // Réglages → MisiCopy Remote. Retrying every 500 ms would hammer
        // the OS with no chance of success.
        guard !liveActivityFailedSessionIDs.contains(snapshot.sessionID) else { return }
        let attributes = CopyActivityAttributes(
            machineName: snapshot.machineName,
            sessionID: snapshot.sessionID
        )
        do {
            // `.token` makes ActivityKit mint an APNs push token for this
            // activity. We forward it to the Mac, which then drives the
            // lock-screen tile via the push relay while the app is
            // suspended — local `Activity.update` calls only run while the
            // app has CPU time, so push is the only path to a locked phone.
            let activity = try Activity<CopyActivityAttributes>.request(
                attributes: attributes,
                content: content,
                pushType: .token
            )
            currentActivity = activity
            currentActivitySessionID = snapshot.sessionID
            observePushToken(for: activity, sessionID: snapshot.sessionID)
        } catch {
            // Remember the failure so we don't spam Activity.request on
            // every subsequent snapshot. The local notification + the
            // foreground dashboard still cover this user.
            liveActivityFailedSessionIDs.insert(snapshot.sessionID)
        }
    }

    /// Streams the activity's APNs push token to the Mac. ActivityKit can
    /// rotate the token, so we keep listening for the life of the
    /// activity and re-send on every change. The hex encoding matches what
    /// APNs expects as the `/3/device/<token>` path component.
    private func observePushToken(for activity: Activity<CopyActivityAttributes>,
                                  sessionID: String) {
        Task { [weak self] in
            for await tokenData in activity.pushTokenUpdates {
                let hex = tokenData.map { String(format: "%02x", $0) }.joined()
                await MainActor.run {
                    self?.cachedLiveActivityToken = (hex, sessionID)
                    self?.client.send(liveActivityToken: hex, sessionID: sessionID)
                }
            }
        }
    }

    /// Re-pushes the cached Live Activity token to the Mac. Called shortly
    /// after a (re)connect so a token that was minted during a network
    /// blip still reaches the Mac and the lock-screen tile resumes
    /// ticking. Safe to call repeatedly — the Mac dedupes by token.
    func resendCachedLiveActivityToken() {
        guard let cached = cachedLiveActivityToken else { return }
        client.send(liveActivityToken: cached.token, sessionID: cached.sessionID)
    }

    private func endLiveActivity() {
        guard let activity = currentActivity else { return }
        Task { await activity.end(nil, dismissalPolicy: .immediate) }
        currentActivity = nil
        currentActivitySessionID = nil
    }

    private func fireLocalNotification(for snap: SessionSnapshot) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in
            let content = UNMutableNotificationContent()
            // .timeSensitive lets the alert pierce Focus modes (Do Not
            // Disturb included), which is the whole point of having an
            // end-of-copy notification on a DIT plateau — the user wants
            // to know the second a card is done. macOS 15 / iOS 17+.
            content.interruptionLevel = .timeSensitive
            switch snap.status {
            case .finished:
                content.title = "Copie terminée"
                content.subtitle = snap.machineName
                content.body = "\(snap.copiedCount) fichier(s) copiés · \(snap.verifiedCount) vérifiés"
                content.sound = .default
            case .failed:
                content.title = "Copie en erreur"
                content.subtitle = snap.machineName
                content.body = "\(snap.failedCount) fichier(s) en erreur · ouvrez l'app pour recopier"
                content.sound = .defaultCritical
            default:
                return
            }
            let request = UNNotificationRequest(
                identifier: "session_\(snap.sessionID)",
                content: content,
                trigger: nil
            )
            center.add(request, withCompletionHandler: nil)
        }
    }
}
