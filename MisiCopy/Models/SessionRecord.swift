//
//  SessionRecord.swift
//  MisiCopy
//
//  Immutable record of a completed copy session, persisted for the
//  history view.
//

import Foundation

struct SessionRecord: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var startDate: Date
    var endDate: Date
    var sourcePaths: [String]
    var destinationPaths: [String]
    var mode: CopyMode
    var algorithm: ChecksumAlgorithm
    var found: Int
    var copied: Int
    var verified: Int
    var failed: Int
    var totalBytes: Int64
    var simulation: Bool

    var duration: TimeInterval { endDate.timeIntervalSince(startDate) }
    var didSucceed: Bool { failed == 0 }
    var sourceSummary: String {
        sourcePaths.map { ($0 as NSString).lastPathComponent }
            .prefix(3).joined(separator: ", ")
    }
    var destinationSummary: String {
        destinationPaths.map { ($0 as NSString).lastPathComponent }
            .prefix(3).joined(separator: ", ")
    }
}
