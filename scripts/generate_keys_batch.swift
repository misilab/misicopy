#!/usr/bin/env swift
//
//  generate_keys_batch.swift
//
//  Generates a batch of self-validating MisiCopy license keys ready to
//  upload to Payhip → Product → License Keys → Upload Keys.
//
//  Format: 20 base32 chars in 5 groups of 4 (e.g. B4XQ-K7M2-N8P3-R5T6-J9V1).
//  Layout: first 12 chars = random ID, last 8 = HMAC-SHA256(id, SECRET).
//
//  ⚠ SECRET must match LicenseConfig.activationSecret in the app.
//
//  Usage:
//    swift scripts/generate_keys_batch.swift [count]
//
//  Output:
//    out/keys-<count>-<timestamp>.txt   (one key per line, Payhip-ready)
//

import Foundation
import CryptoKit
import Security

let SECRET = "SFdn24PFXu5axNMG7qhZojUNCCq5NEvPpWQTMkuoja8NEecJq3WetsLF+amMF1zE"

func base32Encode(_ data: Data) -> String {
    let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ234567")
    var buffer: UInt64 = 0
    var bitsInBuffer = 0
    var output = ""
    for byte in data {
        buffer = (buffer << 8) | UInt64(byte)
        bitsInBuffer += 8
        while bitsInBuffer >= 5 {
            bitsInBuffer -= 5
            output.append(alphabet[Int((buffer >> bitsInBuffer) & 0x1F)])
        }
    }
    if bitsInBuffer > 0 {
        output.append(alphabet[Int((buffer << (5 - bitsInBuffer)) & 0x1F)])
    }
    return output
}

func checksum(of id: String) -> String {
    let key = SymmetricKey(data: Data(SECRET.utf8))
    let mac = HMAC<SHA256>.authenticationCode(for: Data(id.utf8), using: key)
    return String(base32Encode(Data(mac)).prefix(8))
}

func generateKey() -> String {
    var bytes = [UInt8](repeating: 0, count: 8)
    _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
    let id = String(base32Encode(Data(bytes)).prefix(12))
    let raw = id + checksum(of: id)
    var out = ""
    for (i, ch) in raw.enumerated() {
        if i > 0 && i % 4 == 0 { out.append("-") }
        out.append(ch)
    }
    return out
}

// ─── CLI ────────────────────────────────────────────────────────────

let count = Int(CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "1000") ?? 1000

let scriptDir = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()
let projectDir = scriptDir.deletingLastPathComponent()
let outDir = projectDir.appending(path: "out")
try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

let fmt = DateFormatter()
fmt.dateFormat = "yyyyMMdd-HHmmss"
let stamp = fmt.string(from: Date())
let outURL = outDir.appending(path: "keys-\(count)-\(stamp).txt")

// Generate unique keys (in case of collision, retry).
var keys: Set<String> = []
while keys.count < count {
    keys.insert(generateKey())
}
let sorted = keys.sorted()
let text = sorted.joined(separator: "\n") + "\n"
try text.write(to: outURL, atomically: true, encoding: .utf8)

print("✅ \(count) clés générées : \(outURL.path)")
print("→ Upload dans Payhip : Product → License Keys → Upload Keys")
