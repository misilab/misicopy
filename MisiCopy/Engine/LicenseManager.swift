//
//  LicenseManager.swift
//  MisiCopy
//
//  Tracks trial usage (days + transfers) and validates entered license
//  keys via HMAC-SHA256(email + secret). All state lives in the user's
//  login Keychain so a fresh reinstall of the app does NOT reset the
//  trial. Time tampering is detected by comparing the system clock to
//  the last-seen timestamp stored alongside the trial start.
//

import Foundation
import SwiftUI
import CryptoKit

@MainActor
@Observable
final class LicenseManager {

    private let keychain = KeychainStore()
    private let defaults = UserDefaults.standard

    // Keychain accounts (only sensitive data — the actual license key)
    private let kLicenseEmail = "license_email"
    private let kLicenseKey = "license_key"

    // UserDefaults keys (non-secret trial bookkeeping — avoids prompting
    // the user for keychain access on every copy completion). Migrated
    // from keychain in 1.3.4 to stop the "MisiCopy veut utiliser vos
    // informations confidentielles…" dialog from popping up.
    private let dInstallDate = "trial_install_date"
    private let dTransferCount = "trial_transfer_count"
    private let dLastSeen = "trial_last_seen"

    private(set) var status: LicenseStatus = .expired

    init() {
        bootstrap()
        refreshStatus()
    }

    private func bootstrap() {
        // One-time migration: if older versions wrote the trial bookkeeping
        // into the keychain, copy it into UserDefaults so the user's days
        // / transfer counter survive the upgrade — then forget the
        // keychain entries (next keychain read won't prompt anymore).
        migrateLegacyKeychainTrialIfNeeded()

        if defaults.object(forKey: dInstallDate) == nil {
            let now = Date().timeIntervalSince1970
            defaults.set(now, forKey: dInstallDate)
            defaults.set(now, forKey: dLastSeen)
            defaults.set(0, forKey: dTransferCount)
        }
    }

    private func migrateLegacyKeychainTrialIfNeeded() {
        let legacyInstall = "trial_install_date"
        let legacyTransfer = "trial_transfer_count"
        let legacyLastSeen = "trial_last_seen"
        // Only run when UserDefaults doesn't yet know about the trial AND
        // the keychain still holds the legacy values.
        guard defaults.object(forKey: dInstallDate) == nil,
              let install = keychain.get(legacyInstall),
              let installValue = Double(install) else { return }
        defaults.set(installValue, forKey: dInstallDate)
        if let s = keychain.get(legacyLastSeen), let v = Double(s) {
            defaults.set(v, forKey: dLastSeen)
        } else {
            defaults.set(installValue, forKey: dLastSeen)
        }
        if let s = keychain.get(legacyTransfer), let v = Int(s) {
            defaults.set(v, forKey: dTransferCount)
        }
        keychain.remove(legacyInstall)
        keychain.remove(legacyTransfer)
        keychain.remove(legacyLastSeen)
    }

    // MARK: - Trial helpers

    private var installDate: Date {
        Date(timeIntervalSince1970: defaults.double(forKey: dInstallDate))
    }

    private var lastSeen: Date {
        Date(timeIntervalSince1970: defaults.double(forKey: dLastSeen))
    }

    private var transferCount: Int {
        defaults.integer(forKey: dTransferCount)
    }

    private func setTransferCount(_ n: Int) {
        defaults.set(n, forKey: dTransferCount)
    }

    private func touchLastSeen() {
        defaults.set(Date().timeIntervalSince1970, forKey: dLastSeen)
    }

    /// Returns the effective elapsed days, anchored to the largest of
    /// (today, lastSeen) so the user can't shrink it by rewinding the clock.
    private var elapsedDays: Int {
        let anchor = max(Date().timeIntervalSince1970, lastSeen.timeIntervalSince1970)
        let elapsed = anchor - installDate.timeIntervalSince1970
        return max(0, Int(elapsed / 86400))
    }

    // MARK: - Public API

    func recordTransferCompletion() {
        setTransferCount(transferCount + 1)
        touchLastSeen()
        refreshStatus()
    }

    func refreshStatus() {
        touchLastSeen()
        // MisiCopy is free since 1.4.0 — non-licensed users are always
        // unlocked (no day / transfer expiry). The licence key only
        // silences the donation reminder shown on quit.
        if let key = keychain.get(kLicenseKey), Self.validate(key: key) {
            let label = keychain.get(kLicenseEmail) ?? key
            status = .licensed(email: label)
        } else {
            status = .trial(daysLeft: Int.max, transfersLeft: Int.max)
        }
    }

    /// Returns true if the key was accepted and stored. `email` is
    /// optional — used only as a display label.
    @discardableResult
    func activate(email: String, key: String) -> Bool {
        let cleanKey = Self.normalizeKey(key)
        guard !cleanKey.isEmpty, Self.validate(key: cleanKey) else { return false }
        keychain.set(cleanKey, for: kLicenseKey)
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanEmail.isEmpty {
            keychain.set(cleanEmail, for: kLicenseEmail)
        } else {
            keychain.remove(kLicenseEmail)
        }
        refreshStatus()
        return true
    }

    func deactivate() {
        keychain.remove(kLicenseEmail)
        keychain.remove(kLicenseKey)
        refreshStatus()
    }

    // MARK: - Self-validating key generation

    /// Mints a random license key for the pool. Format:
    /// `XXXX-XXXX-XXXX-XXXX-XXXX` (20 base32 chars + 4 hyphens).
    /// First 12 chars = random ID, last 8 = truncated HMAC checksum.
    static func generateKey() -> String {
        var bytes = [UInt8](repeating: 0, count: 8)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        let id = String(base32Encode(Data(bytes)).prefix(12))
        let check = checksum(of: id)
        let raw = id + check
        var out = ""
        for (i, ch) in raw.enumerated() {
            if i > 0 && i % 4 == 0 { out.append("-") }
            out.append(ch)
        }
        return out
    }

    static func validate(key: String) -> Bool {
        let clean = normalizeKey(key)
        guard clean.count == 20 else { return false }
        let id = String(clean.prefix(12))
        let provided = String(clean.suffix(8))
        return constantTimeEqual(checksum(of: id), provided)
    }

    private static func checksum(of id: String) -> String {
        let secret = SymmetricKey(data: Data(LicenseConfig.activationSecret.utf8))
        let mac = HMAC<SHA256>.authenticationCode(
            for: Data(id.utf8), using: secret)
        return String(base32Encode(Data(mac)).prefix(8))
    }

    static func normalizeKey(_ raw: String) -> String {
        raw.uppercased()
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Internals

    private static func constantTimeEqual(_ a: String, _ b: String) -> Bool {
        let ad = Array(a.utf8), bd = Array(b.utf8)
        guard ad.count == bd.count else { return false }
        var diff = 0
        for i in 0..<ad.count { diff |= Int(ad[i] ^ bd[i]) }
        return diff == 0
    }

    /// Base32 (RFC 4648) without padding, uppercase. Hand-rolled so we
    /// don't depend on third-party packages.
    private static func base32Encode(_ data: Data) -> String {
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
}
