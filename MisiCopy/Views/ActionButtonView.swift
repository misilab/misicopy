//
//  ActionButtonView.swift
//  MisiCopy
//

import SwiftUI

struct ActionButtonView: View {
    @Bindable var engine: CopyEngine
    @State private var isPressed: Bool = false

    var body: some View {
        VStack(spacing: 8) {
            if let flash = engine.completionFlash {
                CompletionFlashBanner(outcome: flash,
                                      l10n: engine.l10n,
                                      formatBytes: engine.formatBytes)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.92).combined(with: .opacity),
                        removal: .opacity.combined(with: .move(edge: .top))
                    ))
            }
            HStack(spacing: 8) {
                Button(action: tapAction) {
                    HStack(spacing: 8) {
                        Image(systemName: engine.isRunning ? "stop.circle.fill" : "play.circle.fill")
                            .font(.system(size: 17))
                        Text(buttonTitle)
                            .font(.system(size: 15, weight: .semibold))
                            .contentTransition(.interpolate)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Metrics.buttonRadius, style: .continuous)
                            .fill(buttonGradient)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.Metrics.buttonRadius, style: .continuous)
                                    .stroke(Color.white.opacity(0.18), lineWidth: 0.5)
                            )
                            .shadow(color: buttonShadow, radius: 8, y: 3)
                    )
                    .foregroundStyle(.white)
                    .scaleEffect(isPressed ? 0.97 : 1.0)
                    .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressed)
                }
                .buttonStyle(.plain)
                .disabled((!engine.isRunning && !canStart) || engine.cancelRequested)
                .opacity(engine.cancelRequested ? 0.75 : 1.0)
                .pressEvents(onPress: { isPressed = true },
                             onRelease: { isPressed = false })

                if engine.isRunning {
                    Button {
                        engine.togglePause()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: engine.isPaused ? "play.fill" : "pause.fill")
                            Text(engine.isPaused ? engine.l10n.actionResume : engine.l10n.actionPause)
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.Metrics.buttonRadius, style: .continuous)
                                .fill(engine.isPaused ? Color.green.opacity(0.85) : Color.indigo.opacity(0.85))
                        )
                        .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button {
                        engine.enqueueCurrent()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle")
                            Text(engine.l10n.buttonAddToQueue)
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.Metrics.buttonRadius, style: .continuous)
                                .fill(Color.secondary.opacity(0.15))
                        )
                        .foregroundStyle(.primary)
                    }
                    .buttonStyle(.plain)
                    .disabled(!canStart)
                }
            }

            if !engine.isRunning && engine.failedFileCount > 0 {
                Button {
                    engine.retryFailedFiles()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .font(.system(size: 15))
                        Text(engine.l10n.actionRetryFailed(count: engine.failedFileCount))
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Metrics.buttonRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.red.opacity(0.90), Color(red: 0.75, green: 0.16, blue: 0.28)],
                                    startPoint: .top, endPoint: .bottom)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.Metrics.buttonRadius, style: .continuous)
                                    .stroke(Color.white.opacity(0.18), lineWidth: 0.5)
                            )
                            .shadow(color: Color.red.opacity(0.30), radius: 6, y: 2)
                    )
                    .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .disabled(!canStart)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity
                ))
            }

            if engine.isRunning {
                VStack(spacing: 4) {
                    ShimmerProgressBar(value: engine.stats.progress,
                                       isPaused: engine.isPaused)
                    HStack {
                        Text(engine.currentFileName ?? "…")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer()
                        Text("\(engine.formatBytes(engine.stats.bytesProcessed)) / \(engine.formatBytes(engine.stats.totalBytes))")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.primary)
                            .monospacedDigit()
                    }

                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        timingRow(now: context.date)
                    }

                    HStack(spacing: 5) {
                        Image(systemName: "arrow.uturn.backward.circle")
                            .font(.system(size: 10))
                        Text(engine.l10n.interruptHint)
                            .font(.system(size: 10))
                    }
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 2)
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity
                ))
            }
        }
        .animation(.snappy(duration: 0.3), value: engine.isRunning)
        .animation(.spring(response: 0.45, dampingFraction: 0.7), value: engine.completionFlash)
        .animation(.snappy(duration: 0.3), value: engine.failedFileCount)
    }

    @ViewBuilder
    private func timingRow(now: Date) -> some View {
        let start = engine.startDate ?? now
        let elapsed = max(0, now.timeIntervalSince(start))
        let progress = engine.stats.progress
        let remaining: TimeInterval? = (progress > 0.005 && progress < 1.0)
            ? max(0, elapsed / progress - elapsed)
            : nil

        HStack(spacing: 14) {
            Label {
                Text("\(engine.l10n.labelElapsed) — \(format(elapsed))")
            } icon: {
                Image(systemName: "clock")
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.primary)

            if let remaining {
                Label {
                    Text("\(engine.l10n.labelRemaining) — \(format(remaining))")
                } icon: {
                    Image(systemName: "hourglass")
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.primary)
            }

            Spacer()

            Label {
                Text(engine.formatRate(engine.stats.bytesPerSecond))
            } icon: {
                Image(systemName: "speedometer")
            }
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Theme.Palette.brand)
        }
        .monospacedDigit()
    }

    private func format(_ interval: TimeInterval) -> String {
        let total = Int(interval.rounded())
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%d:%02d", m, s)
    }

    private var canStart: Bool {
        !engine.sources.isEmpty && !engine.destinations.isEmpty
    }

    private var buttonTitle: String {
        if engine.isRunning {
            // Once cancellation is requested, swap the title to reassure
            // the user it's been registered — otherwise they click again
            // and again because the copy doesn't stop instantly.
            if engine.cancelRequested {
                return engine.l10n.actionInterruptRegistered
            }
            let pct = Int((max(0, min(1, engine.stats.progress)) * 100).rounded())
            return "\(engine.l10n.actionInterrupt) — \(pct) %"
        }
        if engine.simulation { return engine.l10n.actionStartSim }
        if engine.mode == .verifyOnly { return engine.l10n.actionStartVerify }
        return engine.l10n.actionStart
    }

    private var buttonGradient: LinearGradient {
        if engine.isRunning {
            // Cool cyan→blue while running — "interrupt" is a safe action
            // now that progress is preserved, no need for alarm colors.
            return LinearGradient(
                colors: [Color(red: 0.15, green: 0.72, blue: 0.88),
                         Color(red: 0.15, green: 0.45, blue: 0.95)],
                startPoint: .top, endPoint: .bottom)
        }
        if !canStart {
            return LinearGradient(
                colors: [Color.secondary.opacity(0.40), Color.secondary.opacity(0.32)],
                startPoint: .top, endPoint: .bottom)
        }
        return LinearGradient(
            colors: [Color.accentColor.opacity(0.95), Color.accentColor.opacity(0.78)],
            startPoint: .top, endPoint: .bottom)
    }

    private var buttonShadow: Color {
        if engine.isRunning { return Color.cyan.opacity(0.35) }
        if !canStart { return .clear }
        return Color.accentColor.opacity(0.30)
    }

    private func tapAction() {
        if engine.isRunning {
            engine.cancel()
        } else {
            engine.start()
        }
    }
}

/// Drives a sweeping highlight across a `ProgressView`-shaped track so the
/// progress bar feels alive (matches the polish bar in OffShoot/Hedge).
/// The shimmer pauses when the copy is paused.
private struct ShimmerProgressBar: View {
    let value: Double
    let isPaused: Bool
    @State private var phase: CGFloat = -0.3

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.accentColor.opacity(0.15))
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.15, green: 0.72, blue: 0.88),
                                     Color(red: 0.15, green: 0.45, blue: 0.95)],
                            startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(width: geo.size.width * CGFloat(max(0, min(1, value))))
                    .overlay(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    stops: [
                                        .init(color: .clear, location: max(0, phase - 0.15)),
                                        .init(color: Color.white.opacity(0.5), location: phase),
                                        .init(color: .clear, location: min(1, phase + 0.15))
                                    ],
                                    startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(Capsule())
                    )
            }
        }
        .frame(height: 12)
        .onAppear {
            withAnimation(.linear(duration: 1.6).repeatForever(autoreverses: false)) {
                phase = 1.3
            }
        }
        .opacity(isPaused ? 0.55 : 1.0)
        .animation(.snappy, value: value)
    }
}

/// End-of-copy flash card: green check on success, red alert on
/// partial failure, grey on cancel. Auto-fades after 6 s thanks to the
/// engine clearing its `completionFlash` state.
private struct CompletionFlashBanner: View {
    let outcome: CopyEngine.CompletionFlash
    let l10n: Localization
    let formatBytes: (Int64) -> String
    @State private var iconScale: CGFloat = 0.5
    @State private var iconOpacity: Double = 0
    @State private var ringScale: CGFloat = 0.8
    @State private var ringOpacity: Double = 0

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(palette.tint.opacity(0.55), lineWidth: 2)
                    .frame(width: 44, height: 44)
                    .scaleEffect(ringScale)
                    .opacity(ringOpacity)
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [palette.tint, palette.tint.opacity(0.75)],
                            startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 34, height: 34)
                    .shadow(color: palette.tint.opacity(0.45), radius: 8, y: 3)
                Image(systemName: palette.icon)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .scaleEffect(iconScale)
                    .opacity(iconOpacity)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(palette.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.primary)
                Text(palette.subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: Theme.Metrics.cardRadius, style: .continuous)
                .fill(palette.tint.opacity(0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Metrics.cardRadius, style: .continuous)
                .stroke(palette.tint.opacity(0.40), lineWidth: 1)
        )
        .shadow(color: palette.tint.opacity(0.18), radius: 10, y: 4)
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.55)) {
                iconScale = 1
                iconOpacity = 1
            }
            withAnimation(.easeOut(duration: 1.0)) {
                ringScale = 1.7
                ringOpacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                ringScale = 0.8
                ringOpacity = 0.7
                withAnimation(.easeOut(duration: 1.0)) {
                    ringScale = 1.7
                    ringOpacity = 0
                }
            }
        }
    }

    private struct Palette {
        let tint: Color
        let icon: String
        let title: String
        let subtitle: String
    }

    private var palette: Palette {
        switch outcome {
        case .success(let verified, let totalBytes):
            return Palette(
                tint: .green,
                icon: "checkmark",
                title: l10n.flashSuccessTitle,
                subtitle: l10n.flashSuccessSubtitle(verified: verified,
                                                    bytes: formatBytes(totalBytes)))
        case .failure(let failed):
            return Palette(
                tint: .red,
                icon: "exclamationmark",
                title: l10n.flashFailureTitle,
                subtitle: l10n.flashFailureSubtitle(failed: failed))
        case .cancelled:
            return Palette(
                tint: .gray,
                icon: "xmark",
                title: l10n.flashCancelledTitle,
                subtitle: l10n.flashCancelledSubtitle)
        }
    }
}
