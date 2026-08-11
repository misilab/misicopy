//
//  CopyStats.swift
//  MisiCopy
//

import Foundation

struct CopyStats: Hashable {
    var found: Int = 0
    var copied: Int = 0
    var verified: Int = 0
    var failed: Int = 0
    /// Real data volume of the run: bytes written for a copy
    /// (source × destinations), bytes verified for a verify-only run.
    /// This is what reports, history and the completion banner display.
    var totalBytes: Int64 = 0
    var bytesProcessed: Int64 = 0
    var bytesPerSecond: Double = 0
    /// Work budget for the progress bar: every byte the run has to READ
    /// or WRITE (copy + verification re-reads). Kept separate from
    /// `totalBytes` so the displayed volume stays honest while the bar
    /// still only reaches 100 % when the trailing verifications finish.
    var workBudget: Int64 = 0
    var workDone: Int64 = 0

    var progress: Double {
        if workBudget > 0 {
            return min(1.0, Double(workDone) / Double(workBudget))
        }
        // Legacy paths (MHL verification) budget only totalBytes.
        guard totalBytes > 0 else { return 0 }
        return min(1.0, Double(bytesProcessed) / Double(totalBytes))
    }

    static let empty = CopyStats()
}
