//
//  SessionStore.swift
//  MisiCopy
//
//  Persists the user's last copy configuration so it can be restored on
//  next launch ("resume previous session"). Stores only paths/settings —
//  the actual file enumeration is re-done at resume time.
//

import Foundation
import SwiftUI

struct SavedSession: Codable, Hashable {
    var savedAt: Date
    var sourcePaths: [String]
    var destinationPaths: [String]
    var mode: CopyMode
    var algorithm: ChecksumAlgorithm
    var preserveStructure: Bool
    var ejectAfterCopy: Bool
    var notifyOnFinish: Bool
    var skipSystemFiles: Bool
    var organizeByDate: Bool
    /// Files fully copied + verified before the run was interrupted.
    /// Key is `<sourceRootPath>\u{0}<relativePath>`, value is the source
    /// checksum ("" in fast mode). Optional so pre-1.7 session files
    /// still decode. Lets a resumed session skip work already secured.
    var completedFiles: [String: String]?
    /// The exact destination paths each completed file was written to,
    /// keyed like `completedFiles`. Resume validates THESE paths instead
    /// of re-deriving them from today's settings (which would break on a
    /// new REEL allocation, a date rollover or a {counter} template).
    var completedTargets: [String: [String]]?
    /// Layout stamps of the interrupted run, restored on resume so the
    /// remaining files land in the SAME folders the interrupted run used.
    var resumeDitDateStamp: String?
    var resumeOrganizeDateStamp: String?
    /// sourceRootPath → "REEL_NNN" allocated by the interrupted run.
    var resumeReelFolders: [String: String]?
    /// Paths of the destinations flagged as cascade, so the flag
    /// survives a session restore.
    var cascadeDestinationPaths: [String]?
}

@MainActor
@Observable
final class SessionStore {
    private(set) var saved: SavedSession?
    private let store = JSONFileStore(filename: "last_session.json")
    /// Serial queue that serializes all disk operations. Guarantees that a
    /// clear() dispatched after saveInBackground() always wins on disk even
    /// if the background write was still pending when clear() was called.
    private let diskQueue = DispatchQueue(label: "com.misicopy.session-store",
                                          qos: .utility)

    init() {
        saved = store.load(as: SavedSession.self)
    }

    func save(_ session: SavedSession) {
        saved = session
        let store = store
        diskQueue.async { store.save(session) }
    }

    /// Same as `save`, but the JSON encode + disk write happen off the
    /// main actor. Used by the mid-copy progress saves, whose payload
    /// (one entry per completed file) can reach tens of thousands of
    /// entries on frame-sequence cards.
    func saveInBackground(_ session: SavedSession) {
        saved = session
        let store = store
        diskQueue.async { store.save(session) }
    }

    func clear() {
        saved = nil
        // Dispatch through the same serial queue so any in-flight save
        // completes before the file is deleted — preventing a stale write
        // from racing past the clear and resurrecting the banner.
        let store = store
        diskQueue.async { store.clear() }
    }
}
