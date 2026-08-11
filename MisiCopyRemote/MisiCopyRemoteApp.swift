//
//  MisiCopyRemoteApp.swift
//  MisiCopyRemote
//
//  iPhone companion to MisiCopy on Mac. Lets you monitor copy sessions in
//  real time over local Wi-Fi (Bonjour + WebSocket) and pause / resume /
//  cancel without touching the Mac.
//

import SwiftUI
import UserNotifications

@main
struct MisiCopyRemoteApp: App {
    @State private var appState = AppState()
    @State private var notificationDelegate = NotificationDelegate()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
        }
    }
}

/// Makes completion banners appear even when the app is in the foreground.
/// Without this delegate, iOS silently drops local notifications while the
/// app has focus — the user puts the iPhone down, copy finishes, picks it
/// back up and the banner never showed.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
}

@MainActor
@Observable
final class AppState {
    let pairedStore = PairedMacStore()
    let discovery = LocalDiscovery()
    let session = RemoteSession()

    init() {
        discovery.start()
        // Ask for notification permission once at launch so the first
        // completed session can actually fire its alert without a silent
        // no-op while iOS shows the system prompt.
        Task {
            _ = try? await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge, .timeSensitive])
        }
    }
}
