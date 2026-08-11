//
//  MacListView.swift
//  MisiCopyRemote
//
//  Lets the user switch between paired Macs and remove old pairings.
//  Online status (visible on Wi-Fi) is shown alongside each entry.
//

import SwiftUI
import UIKit

struct MacListView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        List {
            ForEach(state.pairedStore.macs) { mac in
                row(mac)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    state.pairedStore.remove(state.pairedStore.macs[index])
                }
            }
        }
        .navigationTitle("Mac appairés")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ mac: PairedMac) -> some View {
        let isOnline = state.discovery.endpoint(matching: mac) != nil
        let isActive = state.pairedStore.activeMacID == mac.id
        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            state.pairedStore.select(mac)
            // Re-wire the session against the newly-selected Mac —
            // without this, the dashboard keeps showing the previous
            // Mac's snapshot under the new name.
            state.session.wire(mac: mac,
                               discovery: state.discovery,
                               store: state.pairedStore)
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isOnline ? Color.green.opacity(0.15) : Color.secondary.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: "macbook")
                        .font(.system(size: 18))
                        .foregroundStyle(isOnline ? .green : .secondary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(mac.machineName).font(.body.weight(.semibold))
                    HStack(spacing: 4) {
                        Circle()
                            .fill(isOnline ? Color.green : Color.secondary)
                            .frame(width: 6, height: 6)
                        Text(isOnline ? "Sur le réseau" : "Hors de portée")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.blue)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}
