//
//  CameraFormatDetector.swift
//  MisiCopy
//
//  Lightweight detection of common professional camera formats based on
//  file extension and magic bytes. Used to annotate the journal and the
//  PDF report with the camera origin of each clip.
//

import Foundation

enum CameraFormat: String, Hashable, Codable {
    case red          // R3D (RED)
    case braw         // Blackmagic RAW
    case arri         // ARRI (MXF / ProRes from ALEXA)
    case sony         // Sony XAVC / X-OCN / RAW
    case canon        // Canon CRM / XF-AVC
    case dji          // DJI MOV
    case prores       // ProRes (generic)
    case mxf          // Generic MXF (no specific brand)
    case mov          // Generic QuickTime
    case unknown

    var displayName: String {
        switch self {
        case .red: return "RED R3D"
        case .braw: return "Blackmagic RAW"
        case .arri: return "ARRI"
        case .sony: return "Sony"
        case .canon: return "Canon"
        case .dji: return "DJI"
        case .prores: return "ProRes"
        case .mxf: return "MXF"
        case .mov: return "QuickTime"
        case .unknown: return "—"
        }
    }

    var shortBadge: String {
        switch self {
        case .red: return "RED"
        case .braw: return "BRAW"
        case .arri: return "ARRI"
        case .sony: return "SONY"
        case .canon: return "CANON"
        case .dji: return "DJI"
        case .prores: return "PRORES"
        case .mxf: return "MXF"
        case .mov: return "MOV"
        case .unknown: return ""
        }
    }
}

enum CameraFormatDetector {

    /// Extensions that are typically delivered as image sequences
    /// (one file per frame). Used for the "plan grouping" feature.
    nonisolated static let frameSequenceExtensions: Set<String> = [
        "dpx", "exr", "cin", "ari", "arx", "dng", "arq", "tif", "tiff"
    ]

    /// Audio codecs commonly delivered by pro field recorders (Sound Devices,
    /// Zoom F-series, Tascam, Zaxcom…) and general audio masters. Used to
    /// auto-tag a source as `.son` so it lands in the SON folder of the DIT
    /// tree instead of A_CAM / B_CAM.
    nonisolated static let audioExtensions: Set<String> = [
        "wav", "bwf", "aif", "aiff", "flac", "mp3", "m4a", "aac",
        "ogg", "opus", "caf", "wma", "ac3", "dts", "ape"
    ]

    nonisolated static func isAudio(_ url: URL) -> Bool {
        audioExtensions.contains(url.pathExtension.lowercased())
    }

    nonisolated static func detect(at url: URL) -> CameraFormat {
        let ext = url.pathExtension.lowercased()

        // Cheap path: extension tells us a lot.
        switch ext {
        case "r3d":  return .red
        case "braw": return .braw
        case "ari":  return .arri
        case "crm":  return .canon
        case "mxf":
            return detectMXFBrand(at: url)
        case "mov":
            return detectMOVBrand(at: url)
        default:
            return .unknown
        }
    }

    /// Returns a stable family key when `url` looks like one frame of a
    /// sequence (e.g. `shot01_0042.dpx` → `<parent>/shot01_####.dpx`).
    /// Returns `nil` for non-sequence files.
    nonisolated static func clipFamily(at url: URL) -> String? {
        let ext = url.pathExtension.lowercased()
        guard frameSequenceExtensions.contains(ext) else { return nil }
        let stem = (url.lastPathComponent as NSString).deletingPathExtension
        // Strip trailing run of digits (frame number).
        var endDigits = stem.endIndex
        while endDigits > stem.startIndex {
            let prev = stem.index(before: endDigits)
            if stem[prev].isASCII && stem[prev].isNumber {
                endDigits = prev
            } else {
                break
            }
        }
        let digitsCount = stem.distance(from: endDigits, to: stem.endIndex)
        // Need at least 3 trailing digits to look like a frame number.
        guard digitsCount >= 3 else { return nil }
        let prefix = String(stem[..<endDigits])
        let parent = url.deletingLastPathComponent().path(percentEncoded: false)
        return "\(parent)/\(prefix)####.\(ext)"
    }

    // MARK: - MXF inspection (best-effort, no full SMPTE parser)

    nonisolated private static func detectMXFBrand(at url: URL) -> CameraFormat {
        // Read first 4 KiB and search for known operational pattern UMIDs
        // or vendor strings. Doesn't parse the partition pack.
        guard let handle = try? FileHandle(forReadingFrom: url) else { return .mxf }
        defer { try? handle.close() }
        let data = (try? handle.read(upToCount: 4096)) ?? Data()
        let ascii = String(data: data, encoding: .ascii)?.lowercased() ?? ""
        if ascii.contains("sony") || ascii.contains("xavc") { return .sony }
        if ascii.contains("arri") || ascii.contains("alexa") { return .arri }
        if ascii.contains("canon") { return .canon }
        return .mxf
    }

    // MARK: - QuickTime inspection

    nonisolated private static func detectMOVBrand(at url: URL) -> CameraFormat {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return .mov }
        defer { try? handle.close() }
        // Read enough to capture ftyp + first major brand reads.
        let data = (try? handle.read(upToCount: 256)) ?? Data()
        let bytes = [UInt8](data)
        // Look for 'ftyp' atom (offset 4..8).
        if bytes.count >= 12,
           bytes[4] == 0x66, bytes[5] == 0x74, bytes[6] == 0x79, bytes[7] == 0x70 {
            let brand = String(bytes: bytes[8..<12], encoding: .ascii)?.lowercased() ?? ""
            switch brand {
            case "qt  ", "mp42", "mp41", "isom":
                // Search a bit further for vendor strings.
                let ascii = String(data: data, encoding: .ascii)?.lowercased() ?? ""
                if ascii.contains("apple") { return .prores }
                if ascii.contains("dji") { return .dji }
                return .mov
            default:
                return .mov
            }
        }
        return .mov
    }
}
