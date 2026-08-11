//
//  RootView.swift
//  MisiCopyRemote
//
//  Top-level navigation: shows the pairing flow on first launch, then the
//  dashboard for the active Mac. Lets the user switch between paired Macs
//  via a list when more than one is known.
//

import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var state
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("MisiCopy Remote")
                .navigationBarTitleDisplayMode(.inline)
        }
        .onChange(of: scenePhase) { _, phase in
            handle(scenePhase: phase)
        }
    }

    private func handle(scenePhase phase: ScenePhase) {
        guard let mac = state.pairedStore.activeMac else { return }
        switch phase {
        case .active:
            // iOS occasionally wedges NWBrowser after long background
            // time — the browse query stops returning results. Bouncing
            // the browser is the canonical workaround, and is also how
            // we pick up a Réseau local permission grant that happened
            // after first launch.
            state.discovery.restart()
            // Re-establish channels: iOS suspended the WebSocket while in
            // background, so the cached `connected` status is a lie.
            state.session.wire(mac: mac,
                               discovery: state.discovery,
                               store: state.pairedStore)
        case .background:
            state.session.client.disconnect()
        default:
            break
        }
    }

    @ViewBuilder
    private var content: some View {
        if state.session.isDemoMode {
            DashboardView()
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            state.session.disableDemoMode()
                        } label: {
                            Text("Quitter")
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                }
        } else if state.pairedStore.macs.isEmpty {
            WelcomeView()
        } else {
            DashboardView()
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        NavigationLink {
                            MacListView()
                        } label: {
                            Image(systemName: "desktopcomputer")
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink {
                            PairingView()
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
        }
    }
}

private struct WelcomeView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "iphone.gen2.radiowaves.left.and.right")
                .font(.system(size: 64))
                .foregroundStyle(.blue.gradient)
            VStack(spacing: 8) {
                Text("MisiCopy Remote")
                    .font(.title2.weight(.bold))
                Text("Suivez vos copies MisiCopy en direct\ndepuis votre iPhone.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
            NavigationLink {
                PairingView()
            } label: {
                Label("Appairer un Mac", systemImage: "qrcode.viewfinder")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 32)
            Text("Vous aurez besoin de scanner le QR code\naffiché dans MisiCopy → Réglages → iPhone.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                state.session.enableDemoMode()
            } label: {
                Label("Essayer en mode démo", systemImage: "play.rectangle")
                    .font(.system(size: 13, weight: .medium))
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .tint(.purple)
            Spacer().frame(height: 12)
        }
    }
}
