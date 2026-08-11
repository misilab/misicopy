//
//  StatCard.swift
//  MisiCopy
//

import SwiftUI

struct StatCard: View {
    let icon: String
    let label: String
    let value: String
    let accent: Color

    @State private var pulse: Double = 0

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                Text(label.uppercased())
                    .font(Theme.Typography.statLabel())
                    .tracking(0.4)
            }
            .foregroundStyle(accent)
            Text(value)
                .font(Theme.Typography.bigStat())
                .foregroundStyle(.primary)
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(value) ?? 0))
                .animation(.snappy(duration: 0.35), value: value)
                .scaleEffect(1 + 0.06 * pulse)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: Theme.Metrics.cardRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [accent.opacity(0.16), accent.opacity(0.10)],
                            startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                RoundedRectangle(cornerRadius: Theme.Metrics.cardRadius, style: .continuous)
                    .fill(accent.opacity(0.25 * pulse))
                    .blur(radius: 12)
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Metrics.cardRadius, style: .continuous)
                .stroke(accent.opacity(0.30 + 0.40 * pulse), lineWidth: 1)
        )
        .shadow(color: accent.opacity(0.30 * pulse), radius: 8 * pulse, y: 2)
        .onChange(of: value) { _, _ in
            // Skip if a pulse is already in flight — multiple rapid
            // increments would stomp on each other and produce jitter.
            // The ongoing pulse already telegraphs "value changed".
            guard pulse == 0 else { return }
            withAnimation(.easeOut(duration: 0.18)) { pulse = 1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                withAnimation(.easeIn(duration: 0.55)) { pulse = 0 }
            }
        }
    }
}
