//
//  ChecksumCalculator.swift
//  MisiCopy
//
//  Streams files in chunks and computes checksums using CryptoKit
//  (MD5/SHA-1/SHA-256) or a pure-Swift xxHash64 implementation.
//

import Foundation
import CryptoKit

enum ChecksumError: Error {
    case cannotOpenFile(URL)
    case readFailure(URL)
}

/// Class-based incremental hasher used by the copy pipeline. We use a
/// reference type on purpose: the previous value-type / enum-backed
/// implementation forced Swift to copy the underlying `XXH3State` (≈ 370
/// bytes) on every chunk, which sabotaged throughput. With a class the
/// hasher state stays put in memory and `update(data:)` is essentially
/// free at the language level.
nonisolated final class CopyHasher: @unchecked Sendable {
    private let algorithm: ChecksumAlgorithm
    private var md5: Insecure.MD5?
    private var sha1: Insecure.SHA1?
    private var sha256: SHA256?
    private var xxh64: XXH64State?
    private var xxh3: XXH3State?

    init(_ algorithm: ChecksumAlgorithm) {
        self.algorithm = algorithm
        switch algorithm {
        case .md5:         md5 = Insecure.MD5()
        case .sha1:        sha1 = Insecure.SHA1()
        case .sha256:      sha256 = SHA256()
        case .xxhash64:    xxh64 = XXH64State(seed: 0)
        case .xxhash3_64,
             .xxhash3_128: xxh3 = XXH3State()
        }
    }

    func update(data: Data) {
        switch algorithm {
        case .md5:    md5!.update(data: data)
        case .sha1:   sha1!.update(data: data)
        case .sha256: sha256!.update(data: data)
        case .xxhash64:
            data.withUnsafeBytes { raw in
                if let base = raw.baseAddress {
                    xxh64!.update(bytes: base.assumingMemoryBound(to: UInt8.self), count: data.count)
                }
            }
        case .xxhash3_64, .xxhash3_128:
            data.withUnsafeBytes { raw in
                if let base = raw.baseAddress {
                    xxh3!.update(bytes: base.assumingMemoryBound(to: UInt8.self), count: data.count)
                }
            }
        }
    }

    func finalize() -> String {
        switch algorithm {
        case .md5:    return md5!.finalize().map { String(format: "%02x", $0) }.joined()
        case .sha1:   return sha1!.finalize().map { String(format: "%02x", $0) }.joined()
        case .sha256: return sha256!.finalize().map { String(format: "%02x", $0) }.joined()
        case .xxhash64: return String(format: "%016llx", xxh64!.finalize())
        case .xxhash3_64: return String(format: "%016llx", xxh3!.digest64())
        case .xxhash3_128:
            let r = xxh3!.digest128()
            return String(format: "%016llx%016llx", r.high, r.low)
        }
    }
}

struct ChecksumCalculator {

    nonisolated static let bufferSize = 1 << 20 // 1 MiB

    /// Computes the checksum for `url` using the requested algorithm.
    /// Reports per-chunk progress in bytes via `onChunk`.
    nonisolated static func checksum(
        for url: URL,
        algorithm: ChecksumAlgorithm,
        onChunk: (@Sendable (Int) -> Void)? = nil
    ) async throws -> String {
        try await Task.detached(priority: .userInitiated) {
            try computeSync(url: url, algorithm: algorithm, onChunk: onChunk)
        }.value
    }

    // MARK: - Sync core

    nonisolated private static func computeSync(
        url: URL,
        algorithm: ChecksumAlgorithm,
        onChunk: (@Sendable (Int) -> Void)?
    ) throws -> String {
        switch algorithm {
        case .md5:
            return try streamHash(url: url, hasher: Insecure.MD5(), onChunk: onChunk)
        case .sha1:
            return try streamHash(url: url, hasher: Insecure.SHA1(), onChunk: onChunk)
        case .sha256:
            return try streamHash(url: url, hasher: SHA256(), onChunk: onChunk)
        case .xxhash64:
            return try streamXXH64(url: url, onChunk: onChunk)
        case .xxhash3_64:
            return try streamXXH3_64(url: url, onChunk: onChunk)
        case .xxhash3_128:
            return try streamXXH3_128(url: url, onChunk: onChunk)
        }
    }

    nonisolated private static func streamXXH3_64(url: URL, onChunk: (@Sendable (Int) -> Void)?) throws -> String {
        guard let handle = try? FileHandle(forReadingFrom: url) else {
            throw ChecksumError.cannotOpenFile(url)
        }
        defer { try? handle.close() }
        var state = XXH3State()
        while true {
            // Drain each read's autoreleased Data per iteration — without
            // this a large-file hash grows RAM to the full file size and
            // macOS force-quits the app (see parallelCopy for the same fix).
            let done = try autoreleasepool { () -> Bool in
                let data = try handle.read(upToCount: bufferSize) ?? Data()
                if data.isEmpty { return true }
                data.withUnsafeBytes { raw in
                    if let base = raw.baseAddress {
                        state.update(bytes: base.assumingMemoryBound(to: UInt8.self), count: data.count)
                    }
                }
                onChunk?(data.count)
                return false
            }
            if done { break }
        }
        return String(format: "%016llx", state.digest64())
    }

    nonisolated private static func streamXXH3_128(url: URL, onChunk: (@Sendable (Int) -> Void)?) throws -> String {
        guard let handle = try? FileHandle(forReadingFrom: url) else {
            throw ChecksumError.cannotOpenFile(url)
        }
        defer { try? handle.close() }
        var state = XXH3State()
        while true {
            let done = try autoreleasepool { () -> Bool in
                let data = try handle.read(upToCount: bufferSize) ?? Data()
                if data.isEmpty { return true }
                data.withUnsafeBytes { raw in
                    if let base = raw.baseAddress {
                        state.update(bytes: base.assumingMemoryBound(to: UInt8.self), count: data.count)
                    }
                }
                onChunk?(data.count)
                return false
            }
            if done { break }
        }
        let result = state.digest128()
        return String(format: "%016llx%016llx", result.high, result.low)
    }

    nonisolated private static func streamHash<H: HashFunction>(
        url: URL,
        hasher: H,
        onChunk: (@Sendable (Int) -> Void)?
    ) throws -> String {
        guard let handle = try? FileHandle(forReadingFrom: url) else {
            throw ChecksumError.cannotOpenFile(url)
        }
        defer { try? handle.close() }
        var h = hasher
        while true {
            let done = try autoreleasepool { () -> Bool in
                let data = try handle.read(upToCount: bufferSize) ?? Data()
                if data.isEmpty { return true }
                h.update(data: data)
                onChunk?(data.count)
                return false
            }
            if done { break }
        }
        let digest = h.finalize()
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    nonisolated private static func streamXXH64(url: URL, onChunk: (@Sendable (Int) -> Void)?) throws -> String {
        guard let handle = try? FileHandle(forReadingFrom: url) else {
            throw ChecksumError.cannotOpenFile(url)
        }
        defer { try? handle.close() }
        var state = XXH64State(seed: 0)
        while true {
            let done = try autoreleasepool { () -> Bool in
                let data = try handle.read(upToCount: bufferSize) ?? Data()
                if data.isEmpty { return true }
                data.withUnsafeBytes { raw in
                    if let base = raw.baseAddress {
                        state.update(bytes: base.assumingMemoryBound(to: UInt8.self), count: data.count)
                    }
                }
                onChunk?(data.count)
                return false
            }
            if done { break }
        }
        let value = state.finalize()
        return String(format: "%016llx", value)
    }
}

// MARK: - xxHash64 (pure Swift, single-stream)

/// Reference: https://github.com/Cyan4973/xxHash — XXH64 algorithm.
/// 64-bit non-cryptographic hash, standard in media offload (MHL).
nonisolated private struct XXH64State {
    private static let p1: UInt64 = 0x9E3779B185EBCA87
    private static let p2: UInt64 = 0xC2B2AE3D27D4EB4F
    private static let p3: UInt64 = 0x165667B19E3779F9
    private static let p4: UInt64 = 0x85EBCA77C2B2AE63
    private static let p5: UInt64 = 0x27D4EB2F165667C5

    private var v1: UInt64
    private var v2: UInt64
    private var v3: UInt64
    private var v4: UInt64
    private let seed: UInt64
    private var totalLength: UInt64 = 0
    private var buffer = [UInt8](repeating: 0, count: 32)
    private var bufferLen: Int = 0

    init(seed: UInt64) {
        self.seed = seed
        self.v1 = seed &+ Self.p1 &+ Self.p2
        self.v2 = seed &+ Self.p2
        self.v3 = seed
        self.v4 = seed &- Self.p1
    }

    mutating func update(bytes: UnsafePointer<UInt8>, count: Int) {
        totalLength &+= UInt64(count)
        var input = bytes
        var remaining = count

        if bufferLen > 0 {
            let need = 32 - bufferLen
            let take = min(need, remaining)
            memcpy(&buffer[bufferLen], input, take)
            bufferLen += take
            input = input.advanced(by: take)
            remaining -= take
            if bufferLen == 32 {
                buffer.withUnsafeBytes { raw in
                    if let base = raw.baseAddress {
                        let p = base.assumingMemoryBound(to: UInt8.self)
                        v1 = Self.round(v1, read64(p))
                        v2 = Self.round(v2, read64(p.advanced(by: 8)))
                        v3 = Self.round(v3, read64(p.advanced(by: 16)))
                        v4 = Self.round(v4, read64(p.advanced(by: 24)))
                    }
                }
                bufferLen = 0
            }
        }

        while remaining >= 32 {
            v1 = Self.round(v1, read64(input))
            v2 = Self.round(v2, read64(input.advanced(by: 8)))
            v3 = Self.round(v3, read64(input.advanced(by: 16)))
            v4 = Self.round(v4, read64(input.advanced(by: 24)))
            input = input.advanced(by: 32)
            remaining -= 32
        }

        if remaining > 0 {
            memcpy(&buffer[bufferLen], input, remaining)
            bufferLen += remaining
        }
    }

    mutating func finalize() -> UInt64 {
        var h: UInt64
        if totalLength >= 32 {
            h = rotl(v1, 1) &+ rotl(v2, 7) &+ rotl(v3, 12) &+ rotl(v4, 18)
            h = Self.mergeRound(h, v1)
            h = Self.mergeRound(h, v2)
            h = Self.mergeRound(h, v3)
            h = Self.mergeRound(h, v4)
        } else {
            h = seed &+ Self.p5
        }

        h &+= totalLength

        var idx = 0
        while idx + 8 <= bufferLen {
            let k = buffer.withUnsafeBytes { raw -> UInt64 in
                let base = raw.baseAddress!.assumingMemoryBound(to: UInt8.self)
                return read64(base.advanced(by: idx))
            }
            let k1 = Self.round(0, k)
            h ^= k1
            h = rotl(h, 27) &* Self.p1 &+ Self.p4
            idx += 8
        }
        if idx + 4 <= bufferLen {
            let k = buffer.withUnsafeBytes { raw -> UInt32 in
                let base = raw.baseAddress!.assumingMemoryBound(to: UInt8.self)
                return read32(base.advanced(by: idx))
            }
            h ^= UInt64(k) &* Self.p1
            h = rotl(h, 23) &* Self.p2 &+ Self.p3
            idx += 4
        }
        while idx < bufferLen {
            h ^= UInt64(buffer[idx]) &* Self.p5
            h = rotl(h, 11) &* Self.p1
            idx += 1
        }

        h ^= h >> 33
        h &*= Self.p2
        h ^= h >> 29
        h &*= Self.p3
        h ^= h >> 32
        return h
    }

    // MARK: helpers

    private static func round(_ acc: UInt64, _ input: UInt64) -> UInt64 {
        var a = acc &+ (input &* p2)
        a = rotl(a, 31)
        return a &* p1
    }

    private static func mergeRound(_ acc: UInt64, _ val: UInt64) -> UInt64 {
        let v = round(0, val)
        var a = acc ^ v
        a = a &* p1 &+ p4
        return a
    }

    private func read64(_ p: UnsafePointer<UInt8>) -> UInt64 {
        var v: UInt64 = 0
        memcpy(&v, p, 8) // little-endian on Apple platforms
        return v
    }

    private func read32(_ p: UnsafePointer<UInt8>) -> UInt32 {
        var v: UInt32 = 0
        memcpy(&v, p, 4)
        return v
    }
}

private func read64(_ p: UnsafePointer<UInt8>) -> UInt64 {
    var v: UInt64 = 0
    memcpy(&v, p, 8)
    return v
}

private func read32(_ p: UnsafePointer<UInt8>) -> UInt32 {
    var v: UInt32 = 0
    memcpy(&v, p, 4)
    return v
}

private func rotl(_ x: UInt64, _ r: UInt64) -> UInt64 {
    (x << r) | (x >> (64 &- r))
}
