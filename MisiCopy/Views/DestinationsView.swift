//
//  DestinationsView.swift
//  MisiCopy
//

import SwiftUI
import AppKit

struct DestinationsView: View {
    @Bindable var engine: CopyEngine

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                SectionHeader(icon: "externaldrive.badge.plus", title: engine.l10n.sectionDestinations)
                Spacer()
                Button(action: pickDestination) {
                    Label(engine.l10n.buttonAdd, systemImage: "plus")
                        .font(.system(size: 11, weight: .semibold))
                }
                .controlSize(.small)
                .buttonStyle(.borderless)
                .foregroundStyle(Color.accentColor)
                .padding(.bottom, 4)
            }

            if engine.destinations.isEmpty {
                DropZone(
                    icon: "externaldrive",
                    title: engine.l10n.destEmptyTitle,
                    subtitle: engine.l10n.destEmptySubtitle,
                    buttonTitle: engine.l10n.buttonChoose,
                    onPick: pickDestination,
                    onDrop: { url in engine.addDestination(url) }
                )
            } else {
                ForEach(engine.destinations) { destination in
                    DestinationRow(
                        destination: destination,
                        speedMBs: engine.destinationSpeeds[destination.url],
                        speedRank: speedRank(for: destination),
                        speedUnit: engine.l10n.unitMBs,
                        speedTooltip: engine.l10n.tooltipSpeedBadge,
                        fastestTooltip: engine.l10n.tooltipFastestDrive,
                        slowTooltip: engine.l10n.tooltipSlowDrive,
                        canEject: !engine.isRunning,
                        ejectTooltip: engine.l10n.tooltipEjectVolume,
                        cascadeTooltip: engine.l10n.tooltipCascade,
                        canToggleCascade: !engine.isRunning,
                        onMeasureSpeed: { engine.measureDestinationSpeed(destination, force: true) },
                        onToggleCascade: { engine.toggleCascade(destination) },
                        onEject: { engine.ejectDestination(destination) },
                        onRemove: { engine.removeDestination(destination) }
                    )
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.94).combined(with: .opacity).combined(with: .move(edge: .leading)),
                        removal: .scale(scale: 0.92).combined(with: .opacity).combined(with: .move(edge: .leading))
                    ))
                }
                DropZone(
                    icon: "plus.rectangle.on.folder",
                    title: engine.l10n.destAddTitle,
                    subtitle: engine.l10n.destAddSubtitle,
                    buttonTitle: engine.l10n.buttonChoose,
                    onPick: pickDestination,
                    onDrop: { url in engine.addDestination(url) }
                )
                .opacity(0.85)
            }
        }
        .animation(.spring(response: 0.42, dampingFraction: 0.78), value: engine.destinations.map(\.id))
        .alert(engine.l10n.cascadeAlertTitle,
               isPresented: Binding(
                    get: { engine.showCascadeNeedsDirectAlert },
                    set: { engine.showCascadeNeedsDirectAlert = $0 })) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(engine.l10n.cascadeAlertMessage)
        }
    }

    /// Ranks a destination among those with a known measured speed.
    /// `.fastest` needs at least two measurements and a real lead;
    /// `.slow` flags a drive at less than 60 % of the fastest — the
    /// natural cascade candidate.
    private func speedRank(for destination: Destination) -> DestinationSpeedRank? {
        guard let speed = engine.destinationSpeeds[destination.url] else { return nil }
        let known = engine.destinations.compactMap { engine.destinationSpeeds[$0.url] }
        guard known.count >= 2, let fastest = known.max(), fastest > 0 else { return .middle }
        if speed == fastest, known.contains(where: { $0 < fastest }) { return .fastest }
        if speed < fastest * 0.6 { return .slow }
        return .middle
    }

    private func pickDestination() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.prompt = engine.l10n.buttonAdd
        if panel.runModal() == .OK {
            for url in panel.urls { engine.addDestination(url) }
        }
    }
}

enum DestinationSpeedRank {
    case fastest, middle, slow
}

/// Sober, professional status pill: hairline stroke, quiet tint, small
/// semibold type. Shared by the CASCADE flag and the speed indicator.
struct StatusBadge: View {
    let icon: String?
    let text: String
    let tint: Color

    var body: some View {
        HStack(spacing: 3.5) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 8, weight: .semibold))
            }
            Text(text)
                .font(.system(size: 9, weight: .semibold))
                .kerning(0.3)
                .monospacedDigit()
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2.5)
        .background(Capsule().fill(tint.opacity(0.10)))
        .overlay(Capsule().stroke(tint.opacity(0.35), lineWidth: 0.5))
        .foregroundStyle(tint)
    }
}

private struct DestinationRow: View {
    let destination: Destination
    let speedMBs: Double?
    let speedRank: DestinationSpeedRank?
    let speedUnit: String
    let speedTooltip: String
    let fastestTooltip: String
    let slowTooltip: String
    let canEject: Bool
    let ejectTooltip: String
    let cascadeTooltip: String
    let canToggleCascade: Bool
    let onMeasureSpeed: () -> Void
    let onToggleCascade: () -> Void
    let onEject: () -> Void
    let onRemove: () -> Void

    /// Polls volume free space every 5 s while the row is visible. Cheap
    /// (a single `resourceValues` call) and lets the user see the disk
    /// fill up live during a copy.
    @State private var capacity: VolumeCapacity? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                Image(systemName: destination.isCascade
                      ? "arrow.turn.down.right" : "externaldrive.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(destination.isCascade ? .teal : .indigo)
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 6) {
                        Text(destination.displayName)
                            .font(Theme.Typography.cardTitle())
                        if destination.isCascade {
                            StatusBadge(icon: "arrow.turn.down.right",
                                        text: "CASCADE", tint: .teal)
                        }
                        if let speedMBs {
                            speedBadge(speedMBs)
                        }
                    }
                    Text(destination.path)
                        .font(Theme.Typography.cardSubtitle())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                Spacer(minLength: 0)
                if let capacity {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(capacity.freeFormatted)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(capacityColor(capacity))
                            .monospacedDigit()
                        Text("/ \(capacity.totalFormatted)")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
                Button(action: onToggleCascade) {
                    Image(systemName: "arrow.turn.down.right")
                        .foregroundStyle(destination.isCascade
                                         ? .teal
                                         : (canToggleCascade ? Color.secondary : Color.secondary.opacity(0.4)))
                }
                .buttonStyle(.plain)
                .disabled(!canToggleCascade)
                .help(cascadeTooltip)
                Button(action: onEject) {
                    Image(systemName: "eject.fill")
                        .foregroundStyle(canEject ? .indigo : .secondary)
                }
                .buttonStyle(.plain)
                .disabled(!canEject)
                .help(ejectTooltip)
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            if let capacity {
                CapacityBar(used: capacity.usedRatio, tint: capacityColor(capacity))
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, Theme.Metrics.cardPaddingH)
        .padding(.vertical, 10)
        .cardStyle()
        .animation(.snappy, value: capacity?.freeBytes)
        .task(id: destination.id) {
            capacity = VolumeCapacity.read(at: destination.url)
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                if Task.isCancelled { break }
                capacity = VolumeCapacity.read(at: destination.url)
            }
        }
    }

    private func capacityColor(_ c: VolumeCapacity) -> Color {
        if c.freeBytes < 10_000_000_000 { return .red }
        if c.usedRatio > 0.85 { return .orange }
        return .indigo
    }

    /// Measured-speed pill: ⚡ cyan on the fastest drive, 🐢 grey on a
    /// clearly slower one (cascade candidate), speedometer otherwise.
    /// Clicking re-measures; the tooltip carries the explanation so the
    /// pill itself stays quiet.
    @ViewBuilder
    private func speedBadge(_ mbs: Double) -> some View {
        let value = "\(Int(mbs.rounded())) \(speedUnit)"
        let (icon, tint, tooltip): (String, Color, String) = {
            switch speedRank {
            case .fastest: return ("bolt.fill", .cyan, fastestTooltip)
            case .slow: return ("tortoise.fill", .gray, slowTooltip)
            default: return ("speedometer", .secondary, speedTooltip)
            }
        }()
        Button(action: onMeasureSpeed) {
            StatusBadge(icon: icon, text: value, tint: tint)
        }
        .buttonStyle(.plain)
        .help(tooltip)
    }
}

private struct CapacityBar: View {
    let used: Double
    let tint: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.secondary.opacity(0.12))
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [tint.opacity(0.95), tint.opacity(0.65)],
                            startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(width: max(0, min(1, used)) * geo.size.width)
            }
        }
        .frame(height: 4)
    }
}

private struct VolumeCapacity {
    let freeBytes: Int64
    let totalBytes: Int64
    var usedRatio: Double {
        guard totalBytes > 0 else { return 0 }
        return 1.0 - Double(freeBytes) / Double(totalBytes)
    }
    var freeFormatted: String { Self.formatter.string(fromByteCount: freeBytes) }
    var totalFormatted: String { Self.formatter.string(fromByteCount: totalBytes) }

    private static let formatter: ByteCountFormatter = {
        let f = ByteCountFormatter()
        f.countStyle = .file
        f.allowedUnits = [.useGB, .useTB]
        return f
    }()

    static func read(at url: URL) -> VolumeCapacity? {
        let keys: Set<URLResourceKey> = [
            .volumeAvailableCapacityForImportantUsageKey,
            .volumeAvailableCapacityKey,
            .volumeTotalCapacityKey
        ]
        guard let values = try? url.resourceValues(forKeys: keys) else { return nil }
        // `volumeAvailableCapacityForImportantUsage` is what Apple recommends
        // for "should this fit?" checks, but it returns 0 for many external
        // and network volumes (anything not APFS-managed). Fall back to the
        // raw `volumeAvailableCapacity` so a freshly-plugged SSD doesn't show
        // "0 Go libre — disque plein" while it has 4 TB free.
        let preferredFree = values.volumeAvailableCapacityForImportantUsage ?? 0
        let rawFree = Int64(values.volumeAvailableCapacity ?? 0)
        let free = preferredFree > 0 ? preferredFree : rawFree
        let total = Int64(values.volumeTotalCapacity ?? 0)
        guard total > 0 else { return nil }
        return VolumeCapacity(freeBytes: free, totalBytes: total)
    }
}
