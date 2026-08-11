//
//  PairedMacStore.swift
//  MisiCopyRemote
//
//  Persists the list of Macs the user has paired with. Public properties
//  are observable so the UI redraws when a new Mac is added or one is
//  removed. The shared-secret bytes live in the Keychain, keyed by
//  PairedMac.id, so they never end up in plain text in UserDefaults.
//

import Foundation

@MainActor
@Observable
final class PairedMacStore {
    private static let defaultsKey = "paired_macs"
    private(set) var macs: [PairedMac] = []
    private(set) var activeMacID: UUID?

    private static let activeKey = "active_mac_id"

    init() {
        load()
    }

    var activeMac: PairedMac? {
        guard let id = activeMacID else { return macs.first }
        return macs.first(where: { $0.id == id })
    }

    func add(_ payload: PairingPayload) {
        let mac = PairedMac(machineName: payload.machineName,
                            machineID: payload.machineID,
                            bonjourType: payload.bonjourType,
                            sharedSecret: payload.sharedSecret)
        macs.append(mac)
        activeMacID = mac.id
        saveSecret(mac.sharedSecret ?? "", for: mac.id)
        persist()
    }

    func remove(_ mac: PairedMac) {
        macs.removeAll { $0.id == mac.id }
        deleteSecret(for: mac.id)
        if activeMacID == mac.id { activeMacID = macs.first?.id }
        persist()
    }

    func select(_ mac: PairedMac) {
        activeMacID = mac.id
        UserDefaults.standard.set(mac.id.uuidString, forKey: Self.activeKey)
    }

    func sharedSecret(for mac: PairedMac) -> String? {
        if let cached = mac.sharedSecret, !cached.isEmpty { return cached }
        return loadSecret(for: mac.id)
    }

    // MARK: - Persistence

    private func load() {
        let defaults = UserDefaults.standard
        guard let data = defaults.data(forKey: Self.defaultsKey),
              let stored = try? JSONDecoder().decode([PairedMac].self, from: data)
        else { return }
        // Re-hydrate secrets from the Keychain so they're available without
        // a separate lookup at every call site.
        macs = stored.map {
            var copy = $0
            copy.sharedSecret = loadSecret(for: $0.id) ?? $0.sharedSecret
            return copy
        }
        if let s = defaults.string(forKey: Self.activeKey),
           let uuid = UUID(uuidString: s) {
            activeMacID = uuid
        } else {
            activeMacID = macs.first?.id
        }
    }

    private func persist() {
        let stripped = macs.map { mac -> PairedMac in
            var copy = mac
            copy.sharedSecret = nil // do NOT store the secret in UserDefaults
            return copy
        }
        if let data = try? JSONEncoder().encode(stripped) {
            UserDefaults.standard.set(data, forKey: Self.defaultsKey)
        }
        if let id = activeMacID {
            UserDefaults.standard.set(id.uuidString, forKey: Self.activeKey)
        }
    }

    // MARK: - Keychain (per-Mac secret)

    /// Namespaces our entries so they never collide with other generic
    /// passwords on the device.
    private static let keychainService = "fr.misilab.MisiCopyRemote.secret"

    private func keychainAccount(for id: UUID) -> String {
        "secret_\(id.uuidString)"
    }

    private func saveSecret(_ value: String, for id: UUID) {
        guard let data = value.data(using: .utf8) else { return }
        let account = keychainAccount(for: id)
        let baseQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainService,
            kSecAttrAccount as String: account
        ]
        // Atomic update path: try update first, fall back to add if absent.
        let updateAttrs: [String: Any] = [kSecValueData as String: data]
        let updateStatus = SecItemUpdate(baseQuery as CFDictionary,
                                         updateAttrs as CFDictionary)
        if updateStatus == errSecItemNotFound {
            var add = baseQuery
            add[kSecValueData as String] = data
            SecItemAdd(add as CFDictionary, nil)
        }
    }

    private func loadSecret(for id: UUID) -> String? {
        let account = keychainAccount(for: id)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainService,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let s = String(data: data, encoding: .utf8),
              !s.isEmpty else { return nil }
        return s
    }

    private func deleteSecret(for id: UUID) {
        let account = keychainAccount(for: id)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainService,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
