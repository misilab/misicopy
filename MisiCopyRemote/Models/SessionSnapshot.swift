//
//  SessionSnapshot.swift
//  MisiCopy
//
//  Wire-format used by `RemoteSyncService` to describe the live state of
//  the copy engine to a paired iPhone (over local Wi-Fi or CloudKit later).
//
//  This is the SINGLE source of truth for what the iPhone app reads. Any
//  field added here must remain backward compatible — clients running older
//  versions of the remote app will simply ignore unknown keys.
//

import Foundation

/// A single journal line. Compact wire format used by `recentLogs` on the
/// snapshot — about ~30 lines are kept rolling so the iPhone view stays
/// fresh without bloating the WebSocket payload.
struct SnapshotLogLine: Codable, Sendable, Hashable {
    enum Level: String, Codable, Sendable {
        case info, success, warning, error
    }
    var date: Date
    var level: Level
    var message: String
}

struct SessionSnapshot: Codable, Sendable, Hashable {
    /// Bumped whenever the wire format changes in a non-additive way. The
    /// iPhone app refuses incompatible majors.
    static let formatVersion: Int = 1

    enum Status: String, Codable, Sendable {
        case idle       // no job has run yet this launch
        case running    // copy in progress
        case paused     // user paused mid-job
        case finished   // last job completed successfully
        case failed     // last job had at least one failure
    }

    // Envelope
    var formatVersion: Int = SessionSnapshot.formatVersion
    var generatedAt: Date

    // Identity
    var machineName: String
    var sessionID: String

    // Lifecycle
    var status: Status
    var startedAt: Date?
    var endedAt: Date?

    // Progress
    var bytesProcessed: Int64
    var bytesTotal: Int64
    var filesProcessed: Int
    var filesTotal: Int
    var bytesPerSecond: Int64
    var etaSeconds: Int?
    /// Work-budget fields sent by Mac ≥ 1.11.1. When present, progress
    /// uses these instead of bytesProcessed/bytesTotal so the iPhone bar
    /// matches the Mac UI (which accounts for verification passes).
    var workBudget: Int64 = 0
    var workDone: Int64 = 0

    // Counts (mirror CopyStats)
    var foundCount: Int
    var copiedCount: Int
    var verifiedCount: Int
    var failedCount: Int

    // Current activity
    var currentFile: String?
    var mode: String
    var algorithm: String

    // Summary
    var sourceNames: [String]
    var destinationNames: [String]

    /// Free / total bytes available on each destination volume, indexed in
    /// the same order as `destinationNames`. Empty on Macs < 1.8.1 — the
    /// Codable default keeps the field invisible to old senders. The
    /// iPhone uses this to display "X GB free of Y GB" on the locked
    /// screen and in the dashboard.
    var destinationFreeBytes: [Int64] = []
    var destinationTotalBytes: [Int64] = []

    /// Human-readable phase hint, pre-localized on the Mac side like
    /// `mode` — e.g. "Cascade — cartes libérées" while phase 2 feeds the
    /// slow destinations (the cards themselves are already ejectable).
    /// nil outside the cascade phase. Older clients ignore the key.
    var phaseLabel: String? = nil

    // Last 5 error / warning log lines (truncated to ~200 chars each)
    var recentErrors: [String]

    // Full-fidelity rolling journal — last ~30 entries (info / success /
    // warning / error). Used to power the live activity log on iPhone.
    var recentLogs: [SnapshotLogLine] = []

    /// Friendly progress 0…1 (NaN-safe).
    /// Prefers workBudget/workDone (sent by Mac ≥ 1.11.1) so the bar
    /// accounts for verification passes, matching the Mac UI exactly.
    var progress: Double {
        if workBudget > 0 {
            return min(1, max(0, Double(workDone) / Double(workBudget)))
        }
        guard bytesTotal > 0 else { return 0 }
        return min(1, max(0, Double(bytesProcessed) / Double(bytesTotal)))
    }
}

/// Commands the iPhone can send back over the same channel.
enum RemoteCommand: String, Codable, Sendable {
    case pause
    case resume
    case cancel
    case ping
    /// 1.1.0+ — relaunch the copy pipeline on the previously-failed files
    /// only. Mac < 1.8.1 will reject the unknown rawValue with a Codable
    /// error; the iPhone catches that and tells the user to update the
    /// Mac app.
    case retryFailed
}

/// Top-level envelope sent by the Mac over the WebSocket / CloudKit channel.
/// Always JSON-encoded.
enum RemoteMessage: Codable, Sendable {
    case authChallenge(nonce: String)
    case authOK
    case authFailed
    case snapshot(SessionSnapshot)
    case pong

    private enum CodingKeys: String, CodingKey { case kind, payload }
    private enum Kind: String, Codable { case authChallenge, authOK, authFailed, snapshot, pong }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try c.decode(Kind.self, forKey: .kind)
        switch kind {
        case .authChallenge:
            let nonce = try c.decode(String.self, forKey: .payload)
            self = .authChallenge(nonce: nonce)
        case .authOK:     self = .authOK
        case .authFailed: self = .authFailed
        case .snapshot:
            let snap = try c.decode(SessionSnapshot.self, forKey: .payload)
            self = .snapshot(snap)
        case .pong:       self = .pong
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .authChallenge(let nonce):
            try c.encode(Kind.authChallenge, forKey: .kind)
            try c.encode(nonce, forKey: .payload)
        case .authOK:
            try c.encode(Kind.authOK, forKey: .kind)
        case .authFailed:
            try c.encode(Kind.authFailed, forKey: .kind)
        case .snapshot(let snap):
            try c.encode(Kind.snapshot, forKey: .kind)
            try c.encode(snap, forKey: .payload)
        case .pong:
            try c.encode(Kind.pong, forKey: .kind)
        }
    }
}

/// Top-level envelope sent by the iPhone to the Mac.
enum RemoteClientMessage: Codable, Sendable {
    case authResponse(hmac: String)
    case command(RemoteCommand)
    /// 1.8.2 (Mac) / 1.1.0 (iOS)+ — the iPhone hands the Mac the ActivityKit
    /// push token for the Live Activity it just started, so the Mac can
    /// drive lock-screen progress updates via APNs (through the relay)
    /// even when the iPhone app is suspended. Macs < 1.8.2 fail to decode
    /// the unknown `kind` and ignore it — the tile then only updates while
    /// the iPhone app is foregrounded.
    case liveActivityToken(token: String, sessionID: String)

    private enum CodingKeys: String, CodingKey { case kind, payload }
    private enum Kind: String, Codable { case authResponse, command, liveActivityToken }

    /// Two-field payload for `.liveActivityToken`, wrapped so the existing
    /// single-`payload`-key envelope shape stays unchanged.
    private struct TokenPayload: Codable { var token: String; var sessionID: String }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try c.decode(Kind.self, forKey: .kind)
        switch kind {
        case .authResponse:
            let h = try c.decode(String.self, forKey: .payload)
            self = .authResponse(hmac: h)
        case .command:
            let cmd = try c.decode(RemoteCommand.self, forKey: .payload)
            self = .command(cmd)
        case .liveActivityToken:
            let p = try c.decode(TokenPayload.self, forKey: .payload)
            self = .liveActivityToken(token: p.token, sessionID: p.sessionID)
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .authResponse(let h):
            try c.encode(Kind.authResponse, forKey: .kind)
            try c.encode(h, forKey: .payload)
        case .command(let cmd):
            try c.encode(Kind.command, forKey: .kind)
            try c.encode(cmd, forKey: .payload)
        case .liveActivityToken(let token, let sessionID):
            try c.encode(Kind.liveActivityToken, forKey: .kind)
            try c.encode(TokenPayload(token: token, sessionID: sessionID), forKey: .payload)
        }
    }
}
