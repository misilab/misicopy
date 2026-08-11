//
//  DashboardView.swift
//  MisiCopyRemote
//
//  Live monitoring of the active Mac's copy job: progress ring, transfer
//  speed, ETA, file counters and recent errors. Pause / resume / cancel
//  controls send commands back through the WebSocket.
//

import SwiftUI

struct DashboardView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                connectionBanner
                progressBlock
                statsGrid
                retryFailedBar
                destinationsBlock
                if let snap = state.session.snapshot, !snap.recentLogs.isEmpty {
                    journalBlock(snap.recentLogs)
                }
                controls
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(activeMac?.machineName ?? "MisiCopy")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                channelMenu
            }
        }
        .onAppear {
            reconnectIfNeeded()
            // Catch-up: if the copy finished while the iPhone was suspended
            // or the app was not yet open, fire the completion notification
            // now that the view is active and a snapshot is available.
            state.session.checkForCompletionNotification()
        }
        .onChange(of: state.discovery.discoveredEndpoints) { _, _ in reconnectIfNeeded() }
        .onChange(of: state.session.snapshot) { _, _ in
            state.session.checkForCompletionNotification()
        }
    }

    private var activeMac: PairedMac? { state.pairedStore.activeMac }

    private func reconnectIfNeeded() {
        if state.session.isDemoMode { return }
        guard let mac = activeMac else { return }
        if case .connected = state.session.client.status { return }
        if case .connecting = state.session.client.status { return }
        if case .authenticating = state.session.client.status { return }
        state.session.wire(mac: mac, discovery: state.discovery, store: state.pairedStore)
    }

    // MARK: - Sub-views

    /// Channel selector, moved off the main scroll area into the nav bar
    /// so the dashboard reads as a focused monitoring surface rather than
    /// a settings screen. The icon reflects the live channel (Wi-Fi /
    /// iCloud / auto) and the menu lets the user pin a transport.
    private var channelMenu: some View {
        @Bindable var session = state.session
        return Menu {
            Picker("Canal", selection: $session.preference) {
                ForEach(RemoteSession.Preference.allCases) { pref in
                    Label(pref.displayName, systemImage: pref.icon).tag(pref)
                }
            }
        } label: {
            Image(systemName: state.session.preference.icon)
                .font(.system(size: 15, weight: .semibold))
        }
    }

    /// Orange "Re-copy failed files (N)" button surfaced after a run
    /// ends with at least one failure. Sends `.retryFailed` to the Mac
    /// which calls `engine.retryFailedFiles()` server-side. Hidden when
    /// a run is in flight (the engine refuses retry then anyway).
    @ViewBuilder
    private var retryFailedBar: some View {
        if let snap = state.session.snapshot,
           snap.failedCount > 0,
           snap.status == .failed || snap.status == .finished || snap.status == .idle {
            Button {
                hapticImpact(.medium)
                state.session.send(.retryFailed)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .font(.system(size: 17))
                    Text("Recopier les fichiers en erreur (\(snap.failedCount))")
                        .font(.system(size: 14, weight: .semibold))
                    Spacer()
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.orange.opacity(0.95),
                                         Color(red: 0.93, green: 0.46, blue: 0.16)],
                                startPoint: .top, endPoint: .bottom)
                        )
                )
                .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .disabled(state.session.activeChannel != .local && !state.session.isDemoMode)
            .opacity(state.session.activeChannel == .local || state.session.isDemoMode ? 1.0 : 0.55)
        }
    }

    /// Per-destination disk-space block. Shows "X GB libres de Y GB" with
    /// a thin progress bar so the user can tell at a glance whether the
    /// next dump will fit. Hidden when the Mac is still < 1.8.1 (sends
    /// no disk space data — empty arrays).
    @ViewBuilder
    private var destinationsBlock: some View {
        if let snap = state.session.snapshot,
           !snap.destinationNames.isEmpty,
           !snap.destinationFreeBytes.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Label("Destinations", systemImage: "externaldrive")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                ForEach(Array(snap.destinationNames.enumerated()), id: \.offset) { idx, name in
                    destinationRow(name: name,
                                   free: snap.destinationFreeBytes.indices.contains(idx) ? snap.destinationFreeBytes[idx] : 0,
                                   total: snap.destinationTotalBytes.indices.contains(idx) ? snap.destinationTotalBytes[idx] : 0)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
    }

    private func destinationRow(name: String, free: Int64, total: Int64) -> some View {
        let usedFraction: Double = {
            guard total > 0 else { return 0 }
            return max(0, min(1, Double(total - free) / Double(total)))
        }()
        let barTint: Color = {
            if usedFraction > 0.9 { return .red }
            if usedFraction > 0.75 { return .orange }
            return .green
        }()
        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "externaldrive.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Text(name)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                Text(diskUsageLabel(free: free, total: total))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.secondary.opacity(0.15))
                    Capsule().fill(barTint)
                        .frame(width: geo.size.width * CGFloat(usedFraction))
                }
            }
            .frame(height: 5)
        }
    }

    private func diskUsageLabel(free: Int64, total: Int64) -> String {
        guard total > 0 else { return "—" }
        let formatter = ByteCountFormatter()
        // Include MB so a near-full 1 TB SSD with 500 MB free doesn't
        // render as "0 GB libres" (which would mislead the user about
        // whether the next dump will actually fit).
        formatter.allowedUnits = [.useMB, .useGB, .useTB]
        formatter.countStyle = .file
        return "\(formatter.string(fromByteCount: free)) libres / \(formatter.string(fromByteCount: total))"
    }

    @ViewBuilder
    private var connectionBanner: some View {
        let (icon, text, color) = bannerInfo
        let hint = bannerHint
        let isPending: Bool = {
            switch state.session.status {
            case .connecting, .authenticating: return true
            default: return false
            }
        }()
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .symbolEffect(.pulse, options: .repeating, isActive: isPending)
                Text(text).font(.system(size: 13, weight: .semibold))
                Spacer()
            }
            if let hint {
                Text(hint)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(color.opacity(0.12))
        )
        .animation(.easeInOut(duration: 0.2), value: color)
    }

    /// Actionable hint shown under the banner. Targets the most likely
    /// root cause for each disconnected variant so the user knows where
    /// to look instead of staring at a generic "Pas connecté".
    private var bannerHint: String? {
        if state.session.cloud.lastSnapshot != nil { return nil }
        switch state.session.status {
        case .connected, .connecting, .authenticating:
            return nil
        case .failed:
            return "Re-scannez le QR code depuis l'app Mac si l'erreur persiste."
        case .disconnected:
            let nMacs = state.discovery.discoveredEndpoints.count
            if nMacs == 0 {
                return "Vérifiez : Réglages iOS → MisiCopy Remote → Réseau local activé. " +
                       "Mac et iPhone sur le même Wi-Fi."
            }
            let macID = state.pairedStore.activeMac?.machineID
            let macName = state.pairedStore.activeMac?.machineName ?? "Mac"
            let hasOurMac = state.discovery.discoveredEndpoints.contains {
                if let macID, let mid = $0.machineID { return mid == macID }
                return $0.name.lowercased().hasPrefix(macName.lowercased())
            }
            if !hasOurMac {
                let names = state.discovery.discoveredEndpoints.map(\.name).joined(separator: ", ")
                return "Détectés : \(names). Vérifiez que MisiCopy → Réglages → iPhone est activé sur le bon Mac."
            }
            return nil
        }
    }

    private var bannerInfo: (String, String, Color) {
        if state.session.isDemoMode {
            return ("play.rectangle.fill",
                    "Mode démo — aucune connexion réelle",
                    .purple)
        }
        // Local channel takes precedence when alive.
        switch state.session.status {
        case .connected:
            return ("wifi", "Connecté en local (Wi-Fi)", .green)
        case .connecting:
            return ("wifi.exclamationmark", "Connexion…", .blue)
        case .authenticating:
            return ("lock.shield", "Authentification…", .blue)
        case .failed(let err):
            // Local failed — fall through to cloud if it's working.
            if state.session.cloud.lastSnapshot != nil {
                return ("icloud", "Connecté via iCloud", .indigo)
            }
            return ("xmark.octagon.fill", err, .red)
        case .disconnected:
            if state.session.cloud.lastSnapshot != nil {
                return ("icloud", "Connecté via iCloud", .indigo)
            }
            // Surface the iCloud sign-in error before anything else —
            // without it, the user is staring at "Pas connecté" with no
            // clue why the cloud fallback isn't kicking in either.
            if case .needsiCloudSignIn = state.session.cloud.status {
                return ("exclamationmark.icloud.fill",
                        "Connectez-vous à iCloud pour le suivi à distance",
                        .red)
            }
            // Surface a real NWBrowser failure first — that means the
            // Réseau local permission is denied (silent on iOS) or the
            // network framework couldn't bind to the local interface.
            if case .failed = state.discovery.browserState {
                return ("wifi.exclamationmark", "Bonjour bloqué — vérifier Réseau local", .red)
            }
            let nMacs = state.discovery.discoveredEndpoints.count
            let macID = state.pairedStore.activeMac?.machineID
            let macName = state.pairedStore.activeMac?.machineName ?? "Mac"
            if nMacs == 0 {
                return ("wifi.slash", "Aucun Mac détecté sur le Wi-Fi", .orange)
            }
            let hasOurMac = state.discovery.discoveredEndpoints.contains {
                if let macID, let mid = $0.machineID { return mid == macID }
                return $0.name.lowercased().hasPrefix(macName.lowercased())
            }
            if !hasOurMac {
                return ("magnifyingglass", "\(macName) introuvable sur le Wi-Fi", .orange)
            }
            return ("wifi.slash", "Pas connecté", .orange)
        }
    }

    @ViewBuilder
    private var progressBlock: some View {
        let snap = state.session.snapshot
        let isIdle = snap == nil || snap?.status == .idle
        VStack(spacing: 16) {
            ProgressRing(progress: snap?.progress ?? 0,
                         isActive: snap?.status == .running,
                         ringColor: ringColor(for: snap?.status))
                .frame(width: 220, height: 220)
                .overlay(
                    Group {
                        if isIdle {
                            VStack(spacing: 6) {
                                Image(systemName: "moon.zzz")
                                    .font(.system(size: 36))
                                    .foregroundStyle(.secondary)
                                Text("Au repos")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            VStack(spacing: 4) {
                                Text("\(Int((snap?.progress ?? 0) * 100)) %")
                                    .font(.system(size: 44, weight: .bold, design: .rounded))
                                    .contentTransition(.numericText())
                                Text(snap?.status.localizedLabel ?? "En attente")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: isIdle)
                )
            if let snap {
                HStack(spacing: 24) {
                    metric("Vitesse", formatSpeed(snap.bytesPerSecond))
                    metric("ETA", formatETA(snap.etaSeconds))
                }
                // Cascade phase: the cards are already released — the
                // one thing the DIT wants to know from their pocket.
                if let phase = snap.phaseLabel {
                    Label(phase, systemImage: "arrow.turn.down.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.teal)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.teal.opacity(0.15)))
                }
                if let file = snap.currentFile {
                    Text(file)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private func metric(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 18, weight: .semibold, design: .rounded))
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var statsGrid: some View {
        let snap = state.session.snapshot
        let columns = [GridItem(.flexible()), GridItem(.flexible())]
        let failed = snap?.failedCount ?? 0
        LazyVGrid(columns: columns, spacing: 10) {
            statCard("Trouvés", snap?.foundCount ?? 0, icon: "doc.on.doc", color: .blue)
            statCard("Copiés", snap?.copiedCount ?? 0, icon: "arrow.down.doc", color: .indigo)
            statCard("Vérifiés", snap?.verifiedCount ?? 0, icon: "checkmark.seal", color: .green)
            statCard("Erreurs", failed, icon: "exclamationmark.triangle",
                     color: failed > 0 ? .red : .secondary)
        }
    }

    private func statCard(_ label: String, _ value: Int, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(color.opacity(0.15))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("\(value)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .monospacedDigit()
                    .contentTransition(.numericText(value: Double(value)))
                    .animation(.snappy, value: value)
                Text(label.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.5)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private func journalBlock(_ logs: [SnapshotLogLine]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Journal", systemImage: "list.bullet.rectangle")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            ForEach(Array(logs.enumerated().reversed()), id: \.offset) { _, line in
                journalRow(line)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private func journalRow(_ line: SnapshotLogLine) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: line.level.iconName)
                .font(.system(size: 11))
                .foregroundStyle(line.level.color)
            Text(line.date, format: .dateTime.hour().minute().second())
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.secondary)
            Text(line.message)
                .font(.system(size: 11))
                .lineLimit(2)
                .truncationMode(.middle)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var controls: some View {
        if let snap = state.session.snapshot, snap.status == .running || snap.status == .paused {
            HStack(spacing: 10) {
                if snap.status == .paused {
                    Button {
                        hapticImpact(.medium)
                        state.session.send(.resume)
                    } label: {
                        Label("Reprendre", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                } else {
                    Button {
                        hapticImpact(.medium)
                        state.session.send(.pause)
                    } label: {
                        Label("Pause", systemImage: "pause.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
                Button(role: .destructive) {
                    hapticImpact(.heavy)
                    state.session.send(.cancel)
                } label: {
                    Label("Annuler", systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
    }

    private func hapticImpact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    private func ringColor(for status: SessionSnapshot.Status?) -> Color {
        switch status {
        case .running, .paused: return .blue
        case .finished: return .green
        case .failed: return .red
        case .idle, .none: return .gray
        }
    }

    // MARK: - Formatting helpers

    private func formatSpeed(_ bps: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bps) + "/s"
    }

    private func formatETA(_ seconds: Int?) -> String {
        guard let s = seconds, s > 0 else { return "—" }
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: TimeInterval(s)) ?? "—"
    }
}

private extension SessionSnapshot.Status {
    var localizedLabel: String {
        switch self {
        case .idle: return "En attente"
        case .running: return "Copie en cours"
        case .paused: return "En pause"
        case .finished: return "Terminée"
        case .failed: return "Échec"
        }
    }
}

private extension SnapshotLogLine.Level {
    var color: Color {
        switch self {
        case .info: return .secondary
        case .success: return .green
        case .warning: return .orange
        case .error: return .red
        }
    }
    var iconName: String {
        switch self {
        case .info: return "info.circle"
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.octagon.fill"
        }
    }
}
