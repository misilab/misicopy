//
//  KeychainStore.swift
//  MisiCopy
//
//  Thin wrapper around Security.framework's generic-password class for
//  storing the license + trial bookkeeping. Survives app deletion +
//  reinstall (until the user clears their login keychain).
//

import Foundation
import Security

struct KeychainStore {
    let service: String

    init(service: String = "fr.misilab.MisiCopy.license") {
        self.service = service
    }

    func set(_ value: String, for account: String) {
        let data = Data(value.utf8)
        // Delete any existing entry to avoid duplicate errors.
        SecItemDelete(baseQuery(account: account) as CFDictionary)
        var attrs = baseQuery(account: account)
        attrs[kSecValueData as String] = data
        SecItemAdd(attrs as CFDictionary, nil)
    }

    func get(_ account: String) -> String? {
        var query = baseQuery(account: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let str = String(data: data, encoding: .utf8) else { return nil }
        return str
    }

    func remove(_ account: String) {
        SecItemDelete(baseQuery(account: account) as CFDictionary)
    }

    private func baseQuery(account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}
