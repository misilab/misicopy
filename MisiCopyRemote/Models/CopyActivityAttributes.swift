//
//  CopyActivityAttributes.swift
//  MisiCopy
//
//  Wire-format shared by the iPhone Remote app, its Widget Extension and
//  the (future) APNs push pipeline. ActivityKit (iOS 16.1+) hosts the
//  lock-screen view that shows live copy progress without the user
//  unlocking the device.
//
//  `Attributes` are immutable for the life of an Activity — they describe
//  WHICH job is running (Mac name, session ID). `ContentState` carries the
//  fields that mutate every snapshot (progress, ETA, status). Both must
//  be Codable & Hashable so ActivityKit can diff and persist them.
//

import Foundation
import ActivityKit

/// Drives the iPhone Remote Live Activity (lock-screen + Dynamic Island).
/// Started from `RemoteSession` whenever a `running` snapshot arrives,
/// updated on every subsequent snapshot, ended on `finished` / `failed`.
struct CopyActivityAttributes: ActivityAttributes {
    /// Immutable for the life of the activity — captured at start.
    var machineName: String
    var sessionID: String

    /// Frequently-updated state shipped over `Activity.update(...)` or via
    /// APNs push. Keep this small — Apple caps the payload at 4 KB.
    public struct ContentState: Codable, Hashable {
        var status: Status
        /// 0…1, NaN-safe.
        var progress: Double
        var copiedCount: Int
        var failedCount: Int
        var currentFile: String?
        var bytesPerSecond: Int64
        var etaSeconds: Int?

        public enum Status: String, Codable, Hashable {
            case running, paused, finished, failed
        }
    }
}
