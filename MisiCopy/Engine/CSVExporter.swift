//
//  CSVExporter.swift
//  MisiCopy
//

import Foundation

enum CSVExporter {

    nonisolated static func makeCSV(
        files: [FileItem],
        algorithm: ChecksumAlgorithm,
        startDate: Date,
        endDate: Date
    ) -> String {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]
        var csv = "filename,relativepath,size_bytes,size_human,camera_format,checksum_\(algorithm.rawValue),status,timestamp\n"
        let bytesFmt = ByteCountFormatter()
        bytesFmt.countStyle = .file
        let timestamp = iso.string(from: endDate)
        for file in files {
            let status: String
            switch file.status {
            case .verified: status = "verified"
            case .copied: status = "copied"
            case .failed(let r): status = "failed: \(r)"
            case .skipped: status = "skipped"
            default: status = "pending"
            }
            let row: [String] = [
                escape(file.displayName),
                escape(file.relativePath),
                "\(file.size)",
                escape(bytesFmt.string(fromByteCount: file.size)),
                file.cameraFormat.shortBadge,
                file.sourceChecksum ?? "",
                escape(status),
                timestamp
            ]
            csv += row.joined(separator: ",") + "\n"
        }
        return csv
    }

    private static func escape(_ s: String) -> String {
        if s.contains(",") || s.contains("\"") || s.contains("\n") {
            return "\"" + s.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return s
    }
}
