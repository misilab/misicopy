//
//  LocalChannelServer.swift
//  MisiCopy
//
//  Lightweight WebSocket server advertised over Bonjour (`_misicopy._tcp`).
//  Lets a paired iPhone on the same Wi-Fi receive live session updates and
//  send back pause / resume / cancel commands.
//
//  Auth uses a challenge-response with HMAC-SHA256 over a per-pair shared
//  secret stored in the macOS Keychain. The secret is never transmitted.
//

import Foundation
import Network
import CryptoKit

protocol LocalChannelServerDelegate: AnyObject {
    /// Called on the main actor when a client successfully authenticates.
    @MainActor func localChannelDidAcceptClient()
    /// Called on the main actor when a previously-authenticated client
    /// disconnects (TCP closed, auth failed, app backgrounded long enough
    /// to drop the socket, …).
    @MainActor func localChannelDidDropClient()
    /// Called on the main actor for every authenticated command.
    @MainActor func localChannel(didReceive command: RemoteCommand)
    /// Called on the main actor when an authenticated client registers an
    /// ActivityKit push token for its Live Activity. The Mac uses it to
    /// drive lock-screen updates via the APNs relay.
    @MainActor func localChannel(didReceiveLiveActivityToken token: String, sessionID: String)
}

@MainActor
@Observable
final class LocalChannelServer {

    @ObservationIgnored weak var delegate: LocalChannelServerDelegate?

    private(set) var isRunning: Bool = false
    private(set) var listeningPort: UInt16?

    private let queue = DispatchQueue(label: "fr.misilab.misicopy.local-channel")
    private var listener: NWListener?
    private var clients: [ObjectIdentifier: ClientSession] = [:]
    private let sharedSecret: () -> String
    private let machineID: () -> String

    init(sharedSecret: @escaping () -> String,
         machineID: @escaping () -> String) {
        self.sharedSecret = sharedSecret
        self.machineID = machineID
    }

    // MARK: - Lifecycle

    func start(preferredPort: UInt16 = 0) {
        guard !isRunning else { return }
        let wsOptions = NWProtocolWebSocket.Options()
        wsOptions.autoReplyPing = true
        // Plain WebSocket over TCP for v1. App-level HMAC challenge-
        // response handles authentication. PSK-TLS rollout deferred —
        // see `PSKTLSHelper.swift` for the work-in-progress wrapper.
        let params = NWParameters(tls: nil)
        params.defaultProtocolStack.applicationProtocols.insert(wsOptions, at: 0)
        params.includePeerToPeer = true

        let listener: NWListener
        do {
            if preferredPort == 0 {
                listener = try NWListener(using: params)
            } else {
                listener = try NWListener(using: params,
                                          on: NWEndpoint.Port(rawValue: preferredPort) ?? .any)
            }
        } catch {
            NSLog("LocalChannel: failed to create listener: \(error)")
            return
        }

        listener.service = NWListener.Service(
            name: Host.current().localizedName ?? "MisiCopy",
            type: "_misicopy._tcp",
            // Embed machineID in the TXT record so the iPhone matches by
            // ID rather than by display name (avoids ambiguity when two
            // Macs on the LAN share a name).
            txtRecord: NWTXTRecord(["version": "1", "mid": machineID()])
        )

        listener.stateUpdateHandler = { [weak self] state in
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch state {
                case .ready:
                    self.listeningPort = listener.port?.rawValue
                    self.isRunning = true
                case .failed, .cancelled:
                    self.isRunning = false
                    self.listeningPort = nil
                default:
                    break
                }
            }
        }

        listener.newConnectionHandler = { [weak self] connection in
            Task { @MainActor [weak self] in
                self?.handle(newConnection: connection)
            }
        }

        listener.start(queue: queue)
        self.listener = listener
    }

    func stop() {
        guard isRunning || listener != nil else { return }
        listener?.cancel()
        listener = nil
        for session in clients.values { session.close() }
        clients.removeAll()
        isRunning = false
        listeningPort = nil
    }

    // MARK: - Broadcast

    func broadcast(_ message: RemoteMessage) {
        guard isRunning, !clients.isEmpty else { return }
        do {
            let data = try JSONEncoder().encode(message)
            for session in clients.values where session.isAuthenticated {
                session.send(data)
            }
        } catch {
            NSLog("LocalChannel: failed to encode broadcast: \(error)")
        }
    }

    // MARK: - Connection handling

    private func handle(newConnection: NWConnection) {
        let session = ClientSession(
            connection: newConnection,
            sharedSecret: sharedSecret(),
            onCommand: { [weak self] cmd in
                Task { @MainActor in
                    self?.delegate?.localChannel(didReceive: cmd)
                }
            },
            onLiveActivityToken: { [weak self] token, sessionID in
                Task { @MainActor in
                    self?.delegate?.localChannel(didReceiveLiveActivityToken: token,
                                                 sessionID: sessionID)
                }
            },
            onAuthenticated: { [weak self] in
                Task { @MainActor in
                    self?.delegate?.localChannelDidAcceptClient()
                }
            },
            onClose: { [weak self] id, wasAuthed in
                Task { @MainActor in
                    self?.clients.removeValue(forKey: id)
                    if wasAuthed {
                        self?.delegate?.localChannelDidDropClient()
                    }
                }
            }
        )
        clients[ObjectIdentifier(session)] = session
        session.start(on: queue)
    }
}

// MARK: - Client session

private final class ClientSession: @unchecked Sendable {
    private let connection: NWConnection
    private let sharedSecret: String
    private let onCommand: @Sendable (RemoteCommand) -> Void
    private let onLiveActivityToken: @Sendable (String, String) -> Void
    private let onAuthenticated: @Sendable () -> Void
    private let onClose: @Sendable (ObjectIdentifier, Bool) -> Void

    /// Guards `_isAuthenticated`, `_expectedNonce` and `_wasClosed` — all
    /// mutated from the NWConnection queue but `isAuthenticated` is read
    /// from the MainActor inside `LocalChannelServer.broadcast`.
    private let stateLock = NSLock()
    private var _isAuthenticated: Bool = false
    private var _expectedNonce: String?
    /// Set once `closeAndReport()` runs so any in-flight `receive`
    /// callback delivered after cancellation is short-circuited (NWConn
    /// callbacks aren't always atomic with cancel).
    private var _wasClosed: Bool = false

    var isAuthenticated: Bool {
        stateLock.lock(); defer { stateLock.unlock() }
        return _isAuthenticated
    }

    private var wasClosed: Bool {
        stateLock.lock(); defer { stateLock.unlock() }
        return _wasClosed
    }

    init(connection: NWConnection,
         sharedSecret: String,
         onCommand: @escaping @Sendable (RemoteCommand) -> Void,
         onLiveActivityToken: @escaping @Sendable (String, String) -> Void,
         onAuthenticated: @escaping @Sendable () -> Void,
         onClose: @escaping @Sendable (ObjectIdentifier, Bool) -> Void) {
        self.connection = connection
        self.sharedSecret = sharedSecret
        self.onCommand = onCommand
        self.onLiveActivityToken = onLiveActivityToken
        self.onAuthenticated = onAuthenticated
        self.onClose = onClose
    }

    func start(on queue: DispatchQueue) {
        connection.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            switch state {
            case .ready: self.sendAuthChallenge()
            case .failed, .cancelled: self.closeAndReport()
            default: break
            }
        }
        connection.start(queue: queue)
        receive()
    }

    func close() {
        connection.cancel()
    }

    fileprivate func send(_ data: Data) {
        let metadata = NWProtocolWebSocket.Metadata(opcode: .text)
        let context = NWConnection.ContentContext(identifier: "tx", metadata: [metadata])
        connection.send(content: data,
                        contentContext: context,
                        isComplete: true,
                        completion: .contentProcessed { _ in })
    }

    // MARK: - Auth

    private func sendAuthChallenge() {
        let nonce = Self.randomNonce()
        stateLock.lock(); _expectedNonce = nonce; stateLock.unlock()
        do {
            let data = try JSONEncoder().encode(RemoteMessage.authChallenge(nonce: nonce))
            send(data)
        } catch {
            closeAndReport()
        }
    }

    private static func randomNonce() -> String {
        var bytes = [UInt8](repeating: 0, count: 16)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64EncodedString()
    }

    private func validate(hmac: String) -> Bool {
        stateLock.lock(); let nonce = _expectedNonce; stateLock.unlock()
        guard let nonce,
              let secretData = Data(base64Encoded: sharedSecret),
              let nonceData = nonce.data(using: .utf8),
              let presented = Data(base64Encoded: hmac) else { return false }
        let key = SymmetricKey(data: secretData)
        // Constant-time validation via CryptoKit's built-in verify.
        return HMAC<SHA256>.isValidAuthenticationCode(
            presented, authenticating: nonceData, using: key)
    }

    // MARK: - Receive loop

    private func receive() {
        connection.receiveMessage { [weak self] content, context, isComplete, error in
            guard let self else { return }
            // Suppress all late callbacks once the session has been torn
            // down — prevents post-close frame handling + double-reports.
            if self.wasClosed { return }
            if let error {
                NSLog("LocalChannel: receive error: \(error)")
                self.closeAndReport()
                return
            }
            if let content {
                self.processInbound(content)
            }
            if isComplete && context?.isFinal == true && self.connection.state == .ready {
                self.closeAndReport()
                return
            }
            // Continue reading the next frame.
            if self.connection.state != .cancelled && !self.wasClosed {
                self.receive()
            }
        }
    }

    private func processInbound(_ data: Data) {
        if wasClosed { return }
        do {
            let message = try JSONDecoder().decode(RemoteClientMessage.self, from: data)
            switch message {
            case .authResponse(let hmac):
                stateLock.lock(); let already = _isAuthenticated; stateLock.unlock()
                if !already, validate(hmac: hmac) {
                    stateLock.lock(); _isAuthenticated = true; stateLock.unlock()
                    if let ok = try? JSONEncoder().encode(RemoteMessage.authOK) {
                        send(ok)
                    }
                    onAuthenticated()
                } else {
                    if let ko = try? JSONEncoder().encode(RemoteMessage.authFailed) {
                        send(ko)
                    }
                    closeAndReport()
                }
            case .command(let cmd):
                guard isAuthenticated else { closeAndReport(); return }
                onCommand(cmd)
            case .liveActivityToken(let token, let sessionID):
                guard isAuthenticated else { closeAndReport(); return }
                onLiveActivityToken(token, sessionID)
            }
        } catch {
            NSLog("LocalChannel: failed to decode client message: \(error)")
        }
    }

    private func closeAndReport() {
        stateLock.lock()
        // Idempotent: only the first call actually closes + reports.
        if _wasClosed {
            stateLock.unlock()
            return
        }
        _wasClosed = true
        let wasAuthed = _isAuthenticated
        stateLock.unlock()
        connection.cancel()
        onClose(ObjectIdentifier(self), wasAuthed)
    }
}
