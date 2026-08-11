//
//  PairingPayload.swift
//  MisiCopy
//
//  JSON payload encoded in the pairing QR code. Scanned by the iPhone app
//  to establish the trust relationship with a Mac. The same payload format
//  is reused later for CloudKit pairing (extra optional fields).
//

import Foundation

struct PairingPayload: Codable, Sendable {
    /// Bumped if the wire format changes. iPhone refuses unknown majors.
    static let formatVersion: Int = 1

    var formatVersion: Int = PairingPayload.formatVersion
    var machineName: String
    /// Stable per-Mac identifier used both as the CloudKit recordName for
    /// the `ActiveSession` record and as the disambiguator when an iPhone
    /// has paired multiple Macs with the same display name.
    var machineID: String?
    /// 256-bit shared secret (base64). Used to HMAC the auth challenge on
    /// both local Wi-Fi and CloudKit channels.
    var sharedSecret: String
    /// Bonjour service type the iPhone should browse for.
    var bonjourType: String = "_misicopy._tcp"
    /// Optional iCloud user record name to route CloudKit traffic. Filled
    /// once CloudKit support lands; nil today.
    var cloudUserID: String?
}

extension PairingPayload {
    /// Encodes to a compact JSON string suitable for a QR code.
    func encoded() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(self)
        return String(decoding: data, as: UTF8.self)
    }

    static func decode(from json: String) throws -> PairingPayload {
        guard let data = json.data(using: .utf8) else {
            throw NSError(domain: "PairingPayload", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Payload non-UTF8"])
        }
        let payload = try JSONDecoder().decode(PairingPayload.self, from: data)
        guard payload.formatVersion == PairingPayload.formatVersion else {
            throw NSError(domain: "PairingPayload", code: 2,
                          userInfo: [NSLocalizedDescriptionKey:
                            "Version de payload incompatible (\(payload.formatVersion))"])
        }
        return payload
    }
}
