#!/usr/bin/env swift
//
//  generate_key.swift
//  Utility: produces a license key for a given purchase email.
//  Use this server-side (Payhip webhook → email) or for support manually.
//
//  Usage:  swift scripts/generate_key.swift misicopy@misiraca.com
//
//  ⚠ The SECRET must match LicenseConfig.activationSecret in the app
//    bundle. If you change the secret you invalidate all previous keys.
//

import Foundation
import CryptoKit

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
            let index = Int((buffer >> bitsInBuffer) & 0x1F)
            output.append(alphabet[index])
        }
    }
    if bitsInBuffer > 0 {
        let index = Int((buffer << (5 - bitsInBuffer)) & 0x1F)
        output.append(alphabet[index])
    }
    return output
}

func generateKey(for email: String) -> String {
    let payload = "MISICOPY|\(email.lowercased())|v1"
    let secret = SymmetricKey(data: Data(SECRET.utf8))
    let mac = HMAC<SHA256>.authenticationCode(
        for: Data(payload.utf8), using: secret)
    let raw = String(base32Encode(Data(mac)).prefix(20))
    var out = ""
    for (i, ch) in raw.enumerated() {
        if i > 0 && i % 4 == 0 { out.append("-") }
        out.append(ch)
    }
    return out
}

guard CommandLine.arguments.count > 1 else {
    print("Usage: swift scripts/generate_key.swift <email>")
    exit(1)
}

let email = CommandLine.arguments[1]
let key = generateKey(for: email)
print("Email: \(email)")
print("Key:   \(key)")
