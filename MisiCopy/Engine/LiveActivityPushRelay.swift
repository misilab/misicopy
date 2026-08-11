//
//  LiveActivityPushRelay.swift
//  MisiCopy
//
//  Relays iPhone Live Activity content-state updates to Apple Push
//  Notification service THROUGH a small Cloudflare Worker. The Worker
//  holds the APNs auth key (.p8); the Mac never sees it. This lets the
//  locked iPhone's lock-screen tile keep ticking in real time even when
//  the companion app is suspended (local `Activity.update` can't run
//  while the app has no CPU time — only an APNs push can wake the tile).
//
//  Data flow:
//      iPhone starts Live Activity → gets APNs push token →
//      sends token to Mac over the local channel →
//      Mac POSTs {token, content-state} to the Worker every ~1.5 s →
//      Worker signs an APNs JWT and forwards to api.push.apple.com →
//      iOS updates the lock-screen tile without waking the app.
//

import Foundation

/// Stateless HTTPS client for the push relay. Safe to share; every call
/// builds its own request.
final class LiveActivityPushRelay: @unchecked Sendable {

    /// Public Worker endpoint. NOT a secret — it carries no credentials;
    /// the APNs key lives only inside the Worker. Change this to match
    /// where you deployed `scripts/cloudflare-worker/`.
    static let workerURL = URL(string: "https://misicopy-push.apple-591.workers.dev/push")!

    /// Mirrors `CopyActivityAttributes.ContentState` on the iOS side. The
    /// JSON keys MUST match field-for-field — ActivityKit decodes the
    /// APNs `content-state` payload straight into that Swift type.
    struct ContentState: Codable, Sendable {
        var status: String          // running | paused | finished | failed
        var progress: Double
        var copiedCount: Int
        var failedCount: Int
        var currentFile: String?
        var bytesPerSecond: Int64
        var etaSeconds: Int?
    }

    /// Optional lock-screen banner shown by iOS when the copy ends.
    struct Alert: Codable, Sendable {
        var title: String
        var body: String
    }

    private struct RelayRequest: Codable {
        var token: String
        var event: String           // "update" | "end"
        var contentState: ContentState
        var staleDate: Int?         // unix seconds
        var dismissalDate: Int?     // unix seconds, only for "end"
        var priority: Int           // 5 = throttle-friendly, 10 = immediate
        var alert: Alert?           // only on the terminal "end" push
    }

    /// Fire-and-forget POST. A failed push just means the tile skips a
    /// tick; the next push catches up, so errors are swallowed.
    func send(token: String,
              event: String,
              state: ContentState,
              staleDate: Date?,
              dismissalDate: Date?,
              priority: Int,
              alert: Alert? = nil) async {
        var request = URLRequest(url: Self.workerURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 8
        let body = RelayRequest(
            token: token,
            event: event,
            contentState: state,
            staleDate: staleDate.map { Int($0.timeIntervalSince1970) },
            dismissalDate: dismissalDate.map { Int($0.timeIntervalSince1970) },
            priority: priority,
            alert: alert
        )
        do {
            request.httpBody = try JSONEncoder().encode(body)
            _ = try await URLSession.shared.data(for: request)
        } catch {
            // Best-effort: lock-screen tile just misses this update.
        }
    }
}
