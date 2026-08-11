//
//  DriveSpeedTester.swift
//  MisiCopy
//
//  Runs a brief sequential read/write benchmark against a target URL by
//  writing a small temporary file (~100 MB by default) and reading it
//  back. Cleaned up automatically. Used for preflight checks before a
//  long offload.
//

import Foundation

struct DriveSpeedResult: Hashable {
    let writeMBs: Double
    let readMBs: Double
}

enum DriveSpeedTester {

    nonisolated static func benchmark(
        at folder: URL,
        sampleSize: Int = 100 * 1_000_000   // 100 MB
    ) async throws -> DriveSpeedResult {
        let probeURL = folder.appending(path: ".misicopy_speedtest_\(UUID().uuidString).bin")
        defer { try? FileManager.default.removeItem(at: probeURL) }

        // Generate pseudo-random buffer once, reuse for writes.
        let chunkSize = 4 * 1_024 * 1_024  // 4 MiB
        var chunk = [UInt8](repeating: 0, count: chunkSize)
        for i in 0..<chunkSize { chunk[i] = UInt8(i & 0xFF) }

        // Write
        let writeStart = Date()
        FileManager.default.createFile(atPath: probeURL.path, contents: nil)
        let writer = try FileHandle(forWritingTo: probeURL)
        let writeMBs: Double
        do {
            defer { try? writer.close() }
            var written = 0
            while written < sampleSize {
                let n = min(chunkSize, sampleSize - written)
                try writer.write(contentsOf: chunk.prefix(n))
                written += n
            }
            try writer.synchronize()
            let writeElapsed = Date().timeIntervalSince(writeStart)
            writeMBs = Double(sampleSize) / writeElapsed / 1_000_000
        }

        // Read
        let readStart = Date()
        let reader = try FileHandle(forReadingFrom: probeURL)
        let readMBs: Double
        do {
            defer { try? reader.close() }
            var totalRead = 0
            while true {
                let data = try reader.read(upToCount: chunkSize) ?? Data()
                if data.isEmpty { break }
                totalRead += data.count
            }
            let readElapsed = Date().timeIntervalSince(readStart)
            readMBs = Double(totalRead) / readElapsed / 1_000_000
        }

        return DriveSpeedResult(writeMBs: writeMBs, readMBs: readMBs)
    }
}
