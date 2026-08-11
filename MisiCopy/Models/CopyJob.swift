//
//  CopyJob.swift
//  MisiCopy
//
//  Immutable snapshot of a copy configuration — used both to queue
//  pending jobs and to remember the last session.
//

import Foundation

struct CopyJob: Identifiable, Hashable {
    let id: UUID
    let addedAt: Date
    let sources: [Source]
    let destinations: [Destination]
    let mode: CopyMode
    let algorithm: ChecksumAlgorithm
    let preserveStructure: Bool
    let ejectAfterCopy: Bool
    let notifyOnFinish: Bool
    let skipSystemFiles: Bool
    let organizeByDate: Bool
    let simulation: Bool

    init(id: UUID = UUID(),
         addedAt: Date = Date(),
         sources: [Source],
         destinations: [Destination],
         mode: CopyMode,
         algorithm: ChecksumAlgorithm,
         preserveStructure: Bool,
         ejectAfterCopy: Bool,
         notifyOnFinish: Bool,
         skipSystemFiles: Bool,
         organizeByDate: Bool,
         simulation: Bool) {
        self.id = id
        self.addedAt = addedAt
        self.sources = sources
        self.destinations = destinations
        self.mode = mode
        self.algorithm = algorithm
        self.preserveStructure = preserveStructure
        self.ejectAfterCopy = ejectAfterCopy
        self.notifyOnFinish = notifyOnFinish
        self.skipSystemFiles = skipSystemFiles
        self.organizeByDate = organizeByDate
        self.simulation = simulation
    }

    var summary: String {
        let names = sources.prefix(2).map(\.displayName).joined(separator: ", ")
        let suffix = sources.count > 2 ? " +\(sources.count - 2)" : ""
        return "\(names)\(suffix) → \(destinations.count)"
    }
}
