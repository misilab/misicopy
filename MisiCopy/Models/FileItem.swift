//
//  FileItem.swift
//  MisiCopy
//

import Foundation

enum FileStatus: Hashable {
    case pending
    case copying(progress: Double)
    case verifying
    case copied
    case verified
    case failed(reason: String)
    case skipped
}

struct FileItem: Identifiable, Hashable {
    let id = UUID()
    let sourceRoot: URL
    let sourceURL: URL
    let relativePath: String
    let size: Int64
    var status: FileStatus = .pending
    var sourceChecksum: String?
    var destinationChecksums: [URL: String] = [:]
    var cameraFormat: CameraFormat = .unknown
    /// For image-sequence formats (DPX/EXR/ARRIRAW/CinemaDNG…), this is a
    /// stable key shared by all frames of the same "plan" / shot, so the
    /// report can group N frames as one clip. `nil` for standalone files.
    var clipFamily: String?

    var displayName: String { sourceURL.lastPathComponent }
    var sourceRootName: String { sourceRoot.lastPathComponent }
}
