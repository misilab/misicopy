//
//  PSKTLSHelper.swift
//  MisiCopy
//
//  Configures NWProtocolTLS for pre-shared-key (PSK) operation. Both Mac
//  (server) and iPhone (client) call `makeOptions(secret:)` with the same
//  pairing secret; TLS 1.3 then negotiates a fresh session key without
//  any X.509 certificate involvement.
//
//  Threat model: an attacker on the same Wi-Fi can no longer read
//  `SessionSnapshot` JSON, file paths, or the HMAC challenge/response.
//

import Foundation
import Network
import Security

enum PSKTLSHelper {
    /// PSK identity sent in the ClientHello — purely informational, the
    /// PSK material itself is the shared secret.
    static let identity = "MisiCopyPSK"

    /// Returns `NWProtocolTLS.Options` ready to be plugged into a
    /// `NWParameters(tls:)` initialiser. Falls back to nil when the
    /// secret can't be base64-decoded, leaving the caller to disable
    /// the channel rather than transmit in clear.
    static func makeOptions(secret: String) -> NWProtocolTLS.Options? {
        guard let secretData = Data(base64Encoded: secret), !secretData.isEmpty else {
            return nil
        }
        let options = NWProtocolTLS.Options()
        let secOptions = options.securityProtocolOptions

        // Build dispatch_data_t copies of the PSK + identity. The
        // `DispatchData(bytes:)` initialiser copies the buffer, so the
        // returned values own their bytes independently of the source
        // `Data` and are safe to hand off to `sec_protocol_options_*`.
        let pskDispatch: DispatchData = secretData.withUnsafeBytes { raw in
            DispatchData(bytes: raw)
        }
        let identityData = Data(Self.identity.utf8)
        let identityDispatch: DispatchData = identityData.withUnsafeBytes { raw in
            DispatchData(bytes: raw)
        }
        // Keep `secretData` / `identityData` alive until after the C call:
        // belt-and-braces against any future SDK that loses the copy.
        defer { withExtendedLifetime(secretData) {} ; withExtendedLifetime(identityData) {} }

        sec_protocol_options_add_pre_shared_key(
            secOptions,
            pskDispatch as __DispatchData,
            identityDispatch as __DispatchData
        )
        // TLS 1.3 — PSK is first-class, no legacy cipher selection needed.
        sec_protocol_options_set_min_tls_protocol_version(secOptions, .TLSv13)
        // Restrict to a single AEAD ciphersuite so both ends agree quickly.
        sec_protocol_options_append_tls_ciphersuite(
            secOptions,
            tls_ciphersuite_t.AES_256_GCM_SHA384
        )
        // External-PSK mode does not exchange certificates. Network
        // framework would otherwise still try to verify a cert chain and
        // close the connection. Explicitly accept whatever the peer sends
        // — the PSK handshake itself already provides mutual auth, and
        // the HMAC challenge-response above provides defence-in-depth.
        sec_protocol_options_set_verify_block(
            secOptions,
            { _, _, complete in complete(true) },
            DispatchQueue.global(qos: .userInitiated)
        )
        return options
    }
}
