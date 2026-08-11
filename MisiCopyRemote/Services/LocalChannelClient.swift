//
//  LocalChannelClient.swift
//  MisiCopyRemote
//
//  WebSocket client that connects to a MisiCopy Mac, completes the HMAC
//  challenge-response handshake and streams `SessionSnapshot` updates.
//  Commands (pause / resume / cancel) are sent back over the same socket.
//

import Foundation
import Network
import CryptoKit
import os.log

private let logger = Logger(subsystem: "fr.misilab.MisiCopyRemote", category: "channel")

@MainActor
@Observable
final class LocalChannelClient {

    enum Status: Equatable, Sendable {
        case disconnected
        case connecting
        case authenticating
        case connected
        case failed(String)
    }

    private(set) var status: Status = .disconnected
    private(set) var lastSnapshot: SessionSnapshot?

    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "fr.misilab.misicopy.remote.client")
    private var sharedSecret: String = ""
    private let pathMonitor = NWPathMonitor(requiredInterfaceType: .wifi)
    private var pathMonitorStarted = false

    // MARK: - Lifecycle

    func connect(to endpoint: NWEndpoint, sharedSecret: String) {
        disconnect()
        self.sharedSecret = sharedSecret
        status = .connecting

        let wsOptions = NWProtocolWebSocket.Options()
        wsOptions.autoReplyPing = true
        // Plain WebSocket over TCP for v1 — matches Mac side. PSK-TLS
        // rollout deferred.
        let params = NWParameters(tls: nil)
        params.defaultProtocolStack.applicationProtocols.insert(wsOptions, at: 0)

        let connection = NWConnection(to: endpoint, using: params)
        connection.stateUpdateHandler = { [weak self] state in
            Task { @MainActor [weak self] in
                self?.handleState(state)
            }
        }
        connection.start(queue: queue)
        self.connection = connection
        receive()
        startPathMonitorIfNeeded()
    }

    private func startPathMonitorIfNeeded() {
        guard !pathMonitorStarted else { return }
        pathMonitorStarted = true
        pathMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self else { return }
                // Wi-Fi went down → drop the (now useless) WebSocket so
                // the UI immediately falls back to the CloudKit channel.
                if path.status != .satisfied {
                    if case .connected = self.status {
                        self.disconnect()
                    } else if case .connecting = self.status {
                        self.disconnect()
                    } else if case .authenticating = self.status {
                        self.disconnect()
                    }
                }
            }
        }
        pathMonitor.start(queue: queue)
    }

    func disconnect() {
        // Flip status BEFORE cancelling so the receive callback delivered
        // for the cancelled connection doesn't overwrite it with a noisy
        // POSIX "ENOTCONN" failure message.
        status = .disconnected
        connection?.cancel()
        connection = nil
        lastSnapshot = nil
    }

    func send(command: RemoteCommand) {
        guard status == .connected else { return }
        let message = RemoteClientMessage.command(command)
        sendClient(message)
    }

    /// Registers this iPhone's ActivityKit push token with the Mac so it
    /// can drive lock-screen Live Activity updates via APNs while the app
    /// is suspended. No-op until the channel is authenticated.
    func send(liveActivityToken token: String, sessionID: String) {
        guard status == .connected else { return }
        sendClient(.liveActivityToken(token: token, sessionID: sessionID))
    }

    // MARK: - State

    private func handleState(_ state: NWConnection.State) {
        switch state {
        case .ready:
            // Waiting for the server's authChallenge.
            status = .authenticating
        case .failed(let error):
            status = .failed(error.localizedDescription)
        case .cancelled:
            status = .disconnected
        default:
            break
        }
    }

    // MARK: - Receive loop

    private func receive() {
        guard let connection else { return }
        // `NWConnection.State` isn't Equatable for `.failed` (associated
        // NWError isn't), so we must use pattern matching rather than `==`.
        if case .cancelled = connection.state { return }
        if case .failed = connection.state { return }
        connection.receiveMessage { [weak self] content, _, isComplete, error in
            guard let self else { return }
            Task { @MainActor [weak self] in
                guard let self else { return }
                // User-initiated disconnect already flipped status; don't
                // overwrite with a misleading failure message.
                if self.status == .disconnected { return }
                if let error {
                    self.status = .failed(error.localizedDescription)
                    return
                }
                if let content {
                    self.processInbound(content)
                }
                // Re-arm only if the socket is still alive.
                guard let conn = self.connection,
                      conn.state == .ready else {
                    logger.warning("Receive loop stopped: hasConn=\(self.connection != nil, privacy: .public) status=\(String(describing: self.status), privacy: .public)")
                    return
                }
                self.receive()
            }
        }
    }

    private func processInbound(_ data: Data) {
        do {
            let message = try JSONDecoder().decode(RemoteMessage.self, from: data)
            switch message {
            case .authChallenge(let nonce):
                respondToChallenge(nonce: nonce)
            case .authOK:
                status = .connected
            case .authFailed:
                status = .failed("Clé d'appairage refusée")
                disconnect()
            case .snapshot(let snap):
                logger.info("Snapshot received: status=\(snap.status.rawValue, privacy: .public) session=\(snap.sessionID, privacy: .public)")
                lastSnapshot = snap
            case .pong:
                break
            }
        } catch {
            logger.error("Decode inbound message failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Auth

    private func respondToChallenge(nonce: String) {
        guard let secretData = Data(base64Encoded: sharedSecret),
              let nonceData = nonce.data(using: .utf8) else {
            status = .failed("Secret invalide")
            return
        }
        let key = SymmetricKey(data: secretData)
        let mac = HMAC<SHA256>.authenticationCode(for: nonceData, using: key)
        let response = Data(mac).base64EncodedString()
        sendClient(.authResponse(hmac: response))
    }

    private func sendClient(_ message: RemoteClientMessage) {
        guard let connection else { return }
        do {
            let data = try JSONEncoder().encode(message)
            let metadata = NWProtocolWebSocket.Metadata(opcode: .text)
            let context = NWConnection.ContentContext(identifier: "tx", metadata: [metadata])
            connection.send(content: data,
                            contentContext: context,
                            isComplete: true,
                            completion: .contentProcessed { _ in })
        } catch {
            logger.error("Encode client message failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
