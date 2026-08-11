//
//  ChecksumAlgorithm.swift
//  MisiCopy
//

import Foundation

enum ChecksumAlgorithm: String, CaseIterable, Identifiable, Hashable, Codable {
    case xxhash64
    case xxhash3_64
    case xxhash3_128
    case md5
    case sha1
    case sha256

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .xxhash64:    return "xxHash64"
        case .xxhash3_64:  return "xxHash3 (64-bit)"
        case .xxhash3_128: return "xxHash3 (128-bit)"
        case .md5:         return "MD5"
        case .sha1:        return "SHA-1"
        case .sha256:      return "SHA-256"
        }
    }

    /// Used in MHL XML output (lowercase tag name)
    var mhlTag: String {
        switch self {
        case .xxhash64:    return "xxhash64"
        case .xxhash3_64:  return "xxh3"
        case .xxhash3_128: return "xxh3_128"
        case .md5:         return "md5"
        case .sha1:        return "sha1"
        case .sha256:      return "sha256"
        }
    }
}
