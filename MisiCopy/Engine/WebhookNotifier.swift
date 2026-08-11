//
//  WebhookNotifier.swift
//  MisiCopy
//
//  Posts a JSON payload to an external webhook (Slack, Make.com, Zapier,
//  custom email relay) on copy completion. Network entitlement
//  com.apple.security.network.client must be enabled in the App Sandbox
//  build settings.
//

import Foundation

enum WebhookNotifier {

    nonisolated static func postSlack(url: String, message: String) async {
        guard !url.isEmpty, let endpoint = URL(string: url) else { return }
        let body: [String: Any] = ["text": message]
        await post(endpoint: endpoint, json: body)
    }

    nonisolated static func postGeneric(
        url: String,
        message: String,
        stats: CopyStats,
        success: Bool
    ) async {
        guard !url.isEmpty, let endpoint = URL(string: url) else { return }
        let body: [String: Any] = [
            "tool": "MisiCopy",
            "message": message,
            "success": success,
            "stats": [
                "found": stats.found,
                "copied": stats.copied,
                "verified": stats.verified,
                "failed": stats.failed,
                "totalBytes": stats.totalBytes
            ],
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        await post(endpoint: endpoint, json: body)
    }

    private nonisolated static func post(endpoint: URL, json: [String: Any]) async {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10
        request.httpBody = try? JSONSerialization.data(withJSONObject: json)
        _ = try? await URLSession.shared.data(for: request)
    }
}
