//
//  PairedMac.swift
//  MisiCopyRemote
//
//  Persistent record of a Mac the user has scanned the pairing QR for.
//  Stored in UserDefaults (encoded JSON) — small enough that Keychain
//  isn't required for the bulk record. The sensitive `sharedSecret` field
//  is also mirrored into the Keychain, looked up by `id`, so a backup
//  restore on a different device doesn't carry it over.
//

import Foundation

struct PairedMac: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var machineName: String
    /// Mirror of the Mac's stable `machineID`. Used as CloudKit recordName
    /// to fetch the active session from the cloud channel.
    var machineID: String?
    var bonjourType: String
    var pairedAt: Date
    /// Stored in Keychain under `kSharedSecret_<id>`. Never persisted to
    /// UserDefaults directly.
    var sharedSecret: String?

    init(machineName: String,
         machineID: String?,
         bonjourType: String = "_misicopy._tcp",
         sharedSecret: String) {
        self.id = UUID()
        self.machineName = machineName
        self.machineID = machineID
        self.bonjourType = bonjourType
        self.pairedAt = Date()
        self.sharedSecret = sharedSecret
    }
}
