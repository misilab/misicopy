//
//  CopyLiveActivity.swift
//  MisiCopyWidgets
//
//  Lock-screen + Dynamic Island Live Activity rendering for the iPhone
//  Remote app. The activity is started, updated and ended by
//  `RemoteSession` on the iPhone whenever the Mac's session snapshot
//  transitions to / from a running state.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct CopyLiveActivity: Widget {
    nonisolated init() {}

    nonisolated var body: some WidgetConfiguration {
        ActivityConfiguration(for: CopyActivityAttributes.self) { context in
            LockScreenView(attributes: context.attributes,
                           state: context.state)
                .activityBackgroundTint(.black.opacity(0.55))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded (long-press)
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image(systemName: statusIconName(context.state.status))
                            .foregroundStyle(statusTint(context.state.status))
                            .font(.system(size: 14, weight: .semibold))
                        VStack(alignment: .leading, spacing: 0) {
                            Text("MisiCopy")
                                .font(.system(size: 13, weight: .bold))
                            Text(context.attributes.machineName)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(Int((context.state.progress * 100).rounded())) %")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(statusTint(context.state.status))
                        if context.state.bytesPerSecond > 0, context.state.status == .running {
                            Text(formatSpeed(context.state.bytesPerSecond))
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        ProgressView(value: context.state.progress)
                            .tint(statusTint(context.state.status))
                        HStack {
                            if let file = context.state.currentFile {
                                Text(file)
                                    .font(.caption.monospaced())
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text(statusLabel(context.state.status))
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if let eta = context.state.etaSeconds, context.state.status == .running {
                                HStack(spacing: 3) {
                                    Image(systemName: "hourglass")
                                        .font(.caption)
                                    Text(formatETA(eta))
                                        .font(.caption.monospacedDigit())
                                }
                                .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            } compactLeading: {
                HStack(spacing: 4) {
                    Image(systemName: statusIconName(context.state.status))
                        .foregroundStyle(statusTint(context.state.status))
                        .font(.system(size: 11, weight: .semibold))
                }
            } compactTrailing: {
                Text("\(Int((context.state.progress * 100).rounded())) %")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(statusTint(context.state.status))
            } minimal: {
                Image(systemName: statusIconName(context.state.status))
                    .foregroundStyle(statusTint(context.state.status))
                    .font(.system(size: 12, weight: .semibold))
            }
            .keylineTint(statusTint(context.state.status))
        }
    }

    private func statusIconName(_ s: CopyActivityAttributes.ContentState.Status) -> String {
        switch s {
        case .running:  return "arrow.triangle.2.circlepath"
        case .paused:   return "pause.circle.fill"
        case .finished: return "checkmark.circle.fill"
        case .failed:   return "exclamationmark.triangle.fill"
        }
    }

    private func statusTint(_ s: CopyActivityAttributes.ContentState.Status) -> Color {
        switch s {
        case .running:  return .cyan
        case .paused:   return .yellow
        case .finished: return .green
        case .failed:   return .red
        }
    }

    private func statusLabel(_ s: CopyActivityAttributes.ContentState.Status) -> String {
        switch s {
        case .running:  return "Copie en cours"
        case .paused:   return "En pause"
        case .finished: return "Terminé"
        case .failed:   return "Erreur"
        }
    }

    private func formatETA(_ s: Int) -> String {
        let f = DateComponentsFormatter()
        f.allowedUnits = [.hour, .minute, .second]
        f.unitsStyle = .abbreviated
        return f.string(from: TimeInterval(s)) ?? "—"
    }

    private func formatSpeed(_ bps: Int64) -> String {
        let mb = Double(bps) / 1_000_000
        if mb >= 1000 { return String(format: "%.1f GB/s", mb / 1000) }
        if mb >= 1    { return String(format: "%.0f MB/s", mb) }
        return String(format: "%.0f KB/s", Double(bps) / 1_000)
    }
}

/// Lock-screen presentation. Single-glance layout: prominent percentage,
/// wide progress bar, speed + ETA on the bottom row.
private struct LockScreenView: View {
    let attributes: CopyActivityAttributes
    let state: CopyActivityAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header row: icon + app name + Mac name + big percentage
            HStack(alignment: .center, spacing: 0) {
                HStack(spacing: 7) {
                    Image(systemName: statusIconName)
                        .foregroundStyle(statusTint)
                        .font(.system(size: 15, weight: .semibold))
                    VStack(alignment: .leading, spacing: 1) {
                        Text("MisiCopy")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                        Text(attributes.machineName)
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.6))
                            .lineLimit(1)
                    }
                }
                Spacer()
                // Large percentage — the one number that matters at a glance
                Text("\(Int((state.progress * 100).rounded())) %")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(statusTint)
                    .contentTransition(.numericText(countsDown: false))
            }

            // Progress bar — slightly thicker than default for readability at arm's length
            ProgressView(value: state.progress)
                .tint(statusTint)
                .scaleEffect(y: 1.4, anchor: .center)
                .animation(.easeInOut(duration: 0.4), value: state.progress)

            // Bottom row: current file or status / speed / ETA
            HStack(spacing: 12) {
                if let file = state.currentFile, state.status == .running {
                    Text(file)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.55))
                        .lineLimit(1)
                        .truncationMode(.middle)
                } else {
                    Text(statusLabel)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(statusTint.opacity(0.9))
                }
                Spacer()
                if state.failedCount > 0 {
                    Label("\(state.failedCount)", systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.red)
                }
                if state.bytesPerSecond > 0, state.status == .running {
                    Text(formatSpeed(state.bytesPerSecond))
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.7))
                }
                if let eta = state.etaSeconds, state.status == .running {
                    HStack(spacing: 3) {
                        Image(systemName: "hourglass")
                        Text(formatETA(eta))
                    }
                    .font(.system(size: 11, weight: .semibold).monospacedDigit())
                    .foregroundStyle(.white.opacity(0.85))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var statusIconName: String {
        switch state.status {
        case .running:  return "arrow.triangle.2.circlepath"
        case .paused:   return "pause.circle.fill"
        case .finished: return "checkmark.circle.fill"
        case .failed:   return "exclamationmark.triangle.fill"
        }
    }

    private var statusTint: Color {
        switch state.status {
        case .running:  return .cyan
        case .paused:   return .yellow
        case .finished: return .green
        case .failed:   return .red
        }
    }

    private var statusLabel: String {
        switch state.status {
        case .running:  return "Copie en cours…"
        case .paused:   return "En pause"
        case .finished: return "Copie terminée ✓"
        case .failed:   return "Erreur de copie"
        }
    }

    private func formatETA(_ s: Int) -> String {
        let f = DateComponentsFormatter()
        f.allowedUnits = [.hour, .minute, .second]
        f.unitsStyle = .abbreviated
        return f.string(from: TimeInterval(s)) ?? "—"
    }

    private func formatSpeed(_ bps: Int64) -> String {
        let mb = Double(bps) / 1_000_000
        if mb >= 1000 { return String(format: "%.1f GB/s", mb / 1000) }
        if mb >= 1    { return String(format: "%.0f MB/s", mb) }
        return String(format: "%.0f KB/s", Double(bps) / 1_000)
    }
}
