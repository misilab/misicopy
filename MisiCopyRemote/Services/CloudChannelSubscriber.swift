//
//  CloudChannelSubscriber.swift
//  MisiCopyRemote
//
//  Polls the CloudKit `ActiveSession` record for the active paired Mac.
//  Used as a fallback when the local Wi-Fi channel can't reach the Mac
//  (different network, off-site, etc.) — about 10 s of latency between
//  Mac event and iPhone update, vs ~50 ms via local WebSocket.
//

import Foundation
import CloudKit

@MainActor
@Observable
final class CloudChannelSubscriber {

    enum Status: Equatable, Sendable {
        case idle
        case polling
        case got(Date)              // last successful fetch
        case unavailable(String)
        case needsiCloudSignIn      // user not signed in to iCloud
    }

    private static let containerID = "iCloud.fr.misilab.MisiCopy"
    private static let recordType = "ActiveSession"
    private static let pollInterval: TimeInterval = 10

    private(set) var status: Status = .idle
    private(set) var lastSnapshot: SessionSnapshot?

    private let container: CKContainer
    private var database: CKDatabase { container.privateCloudDatabase }
    private var machineID: String?
    private var pollTimer: Timer?
    private var inFlight = false
    /// Number of consecutive "no session published" / network errors. Used
    /// to back off polling so we don't hammer the network when the Mac
    /// is offline or the user hasn't run a copy yet.
    private var consecutiveMisses: Int = 0

    init() {
        self.container = CKContainer(identifier: Self.containerID)
    }

    // MARK: - Lifecycle

    func connect(machineID: String) {
        // Always reset backoff on an explicit (re)connect so the user can
        // recover from "Mac was offline" by simply re-entering the
        // dashboard or switching transports.
        consecutiveMisses = 0
        if self.machineID == machineID && pollTimer != nil {
            // Same Mac, polling already running — just kick off a fresh
            // fetch so the UI updates immediately.
            Task { await fetchOnce() }
            return
        }
        self.machineID = machineID
        startPolling()
    }

    func disconnect() {
        pollTimer?.invalidate()
        pollTimer = nil
        machineID = nil
        lastSnapshot = nil
        status = .idle
    }

    private func startPolling() {
        pollTimer?.invalidate()
        consecutiveMisses = 0
        Task {
            // Check iCloud account once before the first fetch so the UI
            // can show a clear "sign in to iCloud" message rather than a
            // misleading "no session" silence.
            do {
                let s = try await container.accountStatus()
                if s != .available {
                    status = .needsiCloudSignIn
                    return
                }
            } catch {
                status = .needsiCloudSignIn
                return
            }
            await fetchOnce()
        }
        scheduleNextPoll()
    }

    private func scheduleNextPoll() {
        let multiplier = min(6, 1 + consecutiveMisses)   // 10s → 60s max
        let interval = Self.pollInterval * Double(multiplier)
        let timer = Timer(timeInterval: interval, repeats: false) { [weak self] _ in
            Task { @MainActor in
                await self?.fetchOnce()
                self?.scheduleNextPoll()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        pollTimer = timer
    }

    // MARK: - Fetch

    private func fetchOnce() async {
        guard !inFlight, let machineID else { return }
        inFlight = true
        status = .polling
        defer { inFlight = false }
        let recordID = CKRecord.ID(recordName: machineID)
        do {
            let record = try await database.record(for: recordID)
            guard let data = record["snapshotJSON"] as? Data else {
                consecutiveMisses += 1
                status = .unavailable("Aucun snapshot dans le record")
                return
            }
            let snapshot = try JSONDecoder().decode(SessionSnapshot.self, from: data)
            lastSnapshot = snapshot
            consecutiveMisses = 0
            status = .got(Date())
        } catch let error as CKError where error.code == .unknownItem {
            consecutiveMisses += 1
            status = .unavailable("Aucune session active publiée par ce Mac")
        } catch {
            consecutiveMisses += 1
            status = .unavailable(error.localizedDescription)
        }
    }
}
