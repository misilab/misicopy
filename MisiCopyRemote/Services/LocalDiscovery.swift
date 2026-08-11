//
//  LocalDiscovery.swift
//  MisiCopyRemote
//
//  Browses the local Wi-Fi for MisiCopy Macs (Bonjour `_misicopy._tcp`).
//  Publishes the list as `discoveredEndpoints`. The dashboard cross-checks
//  these against paired Macs (by machine name) to know which paired Mac
//  is actually reachable right now.
//

import Foundation
import Network

@MainActor
@Observable
final class LocalDiscovery {
    struct Result: Identifiable, Hashable {
        let id: String  // stable hash of endpoint
        let name: String
        /// Stable machineID parsed from the Bonjour TXT record's "mid" key.
        /// Used as the primary matching key against paired Macs.
        let machineID: String?
        let endpoint: NWEndpoint
    }

    /// Surfaces NWBrowser's last-known state so the UI can tell the user
    /// when the Réseau local permission is denied (iOS otherwise silently
    /// returns an empty result set). `.failed` typically appears as soon
    /// as the prompt is dismissed without granting.
    enum BrowserState: Equatable, Sendable {
        case stopped
        case starting
        case ready
        case failed(String)
    }

    private(set) var discoveredEndpoints: [Result] = []
    private(set) var browserState: BrowserState = .stopped
    private var browser: NWBrowser?

    func start() {
        guard browser == nil else { return }
        browserState = .starting
        let descriptor = NWBrowser.Descriptor.bonjourWithTXTRecord(
            type: "_misicopy._tcp",
            domain: nil
        )
        // `includePeerToPeer = true` mirrors the Mac side, which lets the
        // browse query travel over AWDL in addition to infrastructure
        // Wi-Fi — handy when the AP isolates clients (common on guest
        // networks and many home APs).
        let params = NWParameters.tcp
        params.includePeerToPeer = true
        let browser = NWBrowser(for: descriptor, using: params)
        browser.stateUpdateHandler = { [weak self] state in
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch state {
                case .ready: self.browserState = .ready
                case .failed(let err): self.browserState = .failed(err.localizedDescription)
                case .cancelled: self.browserState = .stopped
                default: break
                }
            }
        }
        browser.browseResultsChangedHandler = { [weak self] results, _ in
            Task { @MainActor [weak self] in
                self?.update(from: results)
            }
        }
        browser.start(queue: .main)
        self.browser = browser
    }

    func stop() {
        browser?.cancel()
        browser = nil
        discoveredEndpoints = []
        browserState = .stopped
    }

    /// Force-restart the browser. iOS occasionally freezes `NWBrowser`
    /// after long background time or after a permission grant happens
    /// post-launch; bouncing the browser is the canonical workaround.
    func restart() {
        stop()
        start()
    }

    private func update(from results: Set<NWBrowser.Result>) {
        discoveredEndpoints = results.compactMap { result in
            guard case .service(let name, _, _, _) = result.endpoint else { return nil }
            let mid: String? = {
                if case .bonjour(let record) = result.metadata { return record["mid"] }
                return nil
            }()
            let id = "\(name)|\(result.endpoint)"
            return Result(id: id, name: name, machineID: mid, endpoint: result.endpoint)
        }
    }

    /// Returns the live Bonjour endpoint matching a paired Mac. Matching
    /// strategy:
    ///   1. machineID from TXT record (exact, primary)
    ///   2. name fallback (legacy, when TXT record missing)
    func endpoint(matching mac: PairedMac) -> NWEndpoint? {
        if let mid = mac.machineID,
           let hit = discoveredEndpoints.first(where: { $0.machineID == mid }) {
            return hit.endpoint
        }
        // Fallback: older Macs (no TXT mid) or pre-migration pairings.
        return discoveredEndpoints.first(where: {
            $0.name.lowercased().hasPrefix(mac.machineName.lowercased())
        })?.endpoint
    }
}
