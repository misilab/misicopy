//
//  Preset.swift
//  MisiCopy
//
//  Reusable copy configuration the user can save and apply.
//

import Foundation

struct Preset: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var name: String
    var mode: CopyMode
    var algorithm: ChecksumAlgorithm
    var preserveStructure: Bool
    var ejectAfterCopy: Bool
    var notifyOnFinish: Bool
    var skipSystemFiles: Bool
    var organizeByDate: Bool
}
