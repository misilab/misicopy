//
//  OptionCard.swift
//  MisiCopy
//

import SwiftUI

struct OptionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let accent: Color
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [accent.opacity(isSelected ? 0.28 : 0.15),
                                         accent.opacity(isSelected ? 0.18 : 0.10)],
                                startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 36, height: 36)
                        .shadow(color: accent.opacity(isSelected ? 0.35 : 0),
                                radius: isSelected ? 6 : 0, y: 2)
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(accent)
                        .symbolEffect(.bounce, value: isSelected)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(Theme.Typography.cardTitle())
                    Text(subtitle)
                        .font(Theme.Typography.cardSubtitle())
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer(minLength: 0)
                ZStack {
                    Circle()
                        .stroke(isSelected ? accent : Color.secondary.opacity(0.5),
                                lineWidth: isSelected ? 2 : 1.5)
                        .frame(width: 18, height: 18)
                    Circle()
                        .fill(accent)
                        .frame(width: 10, height: 10)
                        .scaleEffect(isSelected ? 1 : 0)
                        .opacity(isSelected ? 1 : 0)
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.6), value: isSelected)
            }
            .padding(.horizontal, Theme.Metrics.cardPaddingH)
            .padding(.vertical, Theme.Metrics.cardPaddingV)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .cardStyle(selected: isSelected)
        .scaleEffect(isPressed ? 0.98 : (isHovered && !isSelected ? 1.005 : 1.0))
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressed)
        .animation(.spring(response: 0.30, dampingFraction: 0.7), value: isHovered)
        .hoverLift(isHovered && !isSelected, intensity: 1)
        .onHover { hovering in isHovered = hovering }
        .pressEvents(isPressed: $isPressed)
    }
}
