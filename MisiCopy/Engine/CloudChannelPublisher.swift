//
//  CloudChannelPublisher.swift
//  MisiCopy
//
//  Mirrors `SessionSnapshot` to a single CloudKit record in the user's
//  private database every `Self.uploadInterval`. The iPhone reads from the
//  same record when it can't reach the Mac over local Wi-Fi (e.g. user is
//  at home, Mac is at the studio).
//
//  Container: iCloud.fr.misilab.MisiCopy
//  Record type: ActiveSession
//  recordName: <machineID> — one record per Mac, overwritten in place
//

import Foundation
import CloudKit

@MainActor
@Observable
final class CloudChannelPublisher {

    enum Status: Equatable, Sendable {
        case idle               // not started yet
        case ready              // logged in, ready to publish
        case publishing         // upload in flight
        case unavailable(Reason) // iCloud account missing / network down / disabled

        /// Translatable cause behind a `.unavailable` status. The string
        /// payload of `.other` is for non-CKError messages we can't
        /// classify (network, etc.) — kept as the raw, already-localized
        /// `Error.localizedDescription` from the OS.
        enum Reason: Equatable, Sendable {
            case noAccount
            case restricted
            case undetermined
            case temporarilyUnavailable
            case unknown
            case other(String)
        }
    }

    private static let containerID = "iCloud.fr.misilab.MisiCopy"
    private static let recordType = "ActiveSession"
    private static let uploadInterval: TimeInterval = 5

    private(set) var status: Status = .idle
    private(set) var lastUploadAt: Date?

    private let container: CKContainer
    private var database: CKDatabase { container.privateCloudDatabase }
    private let machineID: String
    private var uploadTimer: Timer?
    private var pendingSnapshot: SessionSnapshot?
    private var inFlight = false
    private var accountObserver: NSObjectProtocol?

    init(machineID: String) {
        self.machineID = machineID
        self.container = CKContainer(identifier: Self.containerID)
    }

    // MARK: - Lifecycle

    func start() {
        guard uploadTimer == nil else { return }
        Task { @MainActor in
            await refreshAccountStatus()
        }
        // React to iCloud sign-in / sign-out without restart. The token is
        // retained so we can balance it in `stop()` / `deinit`.
        accountObserver = NotificationCenter.default.addObserver(
            forName: .CKAccountChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in await self?.refreshAccountStatus() }
        }
        let timer = Timer(timeInterval: Self.uploadInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        uploadTimer = timer
    }

    func stop() {
        uploadTimer?.invalidate()
        uploadTimer = nil
        pendingSnapshot = nil
        if let token = accountObserver {
            NotificationCenter.default.removeObserver(token)
            accountObserver = nil
        }
        // Best-effort cleanup of the cloud record so private file paths
        // don't linger in the user's iCloud after they stop monitoring.
        let id = CKRecord.ID(recordName: machineID)
        let db = database
        Task.detached { try? await db.deleteRecord(withID: id) }
    }

    /// Called from RemoteSyncService whenever a fresh snapshot is built.
    func update(_ snapshot: SessionSnapshot) {
        pendingSnapshot = snapshot
    }

    // MARK: - Upload

    private func tick() {
        guard !inFlight, let snap = pendingSnapshot else { return }
        // Don't burn the network when iCloud isn't available — but DO
        // re-check the account status periodically so we recover when
        // the user signs back in.
        if case .unavailable = status {
            Task { @MainActor in await refreshAccountStatus() }
            return
        }
        Task { await upload(snap) }
    }

    private func upload(_ snapshot: SessionSnapshot) async {
        inFlight = true
        status = .publishing
        defer { inFlight = false }
        do {
            let data = try JSONEncoder().encode(snapshot)
            let record = try await fetchOrMakeRecord()
            record["snapshotJSON"] = data as NSData
            record["updatedAt"] = snapshot.generatedAt as NSDate
            record["machineName"] = snapshot.machineName as NSString
            record["status"] = snapshot.status.rawValue as NSString
            _ = try await database.save(record)
            lastUploadAt = Date()
            status = .ready
        } catch {
            status = .unavailable(.other(error.localizedDescription))
        }
    }

    private func fetchOrMakeRecord() async throws -> CKRecord {
        let recordID = CKRecord.ID(recordName: machineID)
        do {
            return try await database.record(for: recordID)
        } catch let error as CKError where error.code == .unknownItem {
            return CKRecord(recordType: Self.recordType, recordID: recordID)
        }
    }

    private func refreshAccountStatus() async {
        do {
            let s = try await container.accountStatus()
            switch s {
            case .available: status = .ready
            case .noAccount: status = .unavailable(.noAccount)
            case .restricted: status = .unavailable(.restricted)
            case .couldNotDetermine: status = .unavailable(.undetermined)
            case .temporarilyUnavailable: status = .unavailable(.temporarilyUnavailable)
            @unknown default: status = .unavailable(.unknown)
            }
        } catch {
            status = .unavailable(.other(error.localizedDescription))
        }
    }
}
