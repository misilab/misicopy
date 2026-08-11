//
//  ModeSelectionView.swift
//  MisiCopy
//

import SwiftUI

struct ModeSelectionView: View {
    @Bindable var engine: CopyEngine

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(icon: "line.3.horizontal", title: engine.l10n.sectionMode)

            ForEach(CopyMode.allCases) { mode in
                OptionCard(
                    icon: mode.iconName,
                    title: engine.l10n.modeTitle(mode),
                    subtitle: engine.l10n.modeSubtitle(mode),
                    accent: mode.accentColor,
                    isSelected: engine.mode == mode
                ) {
                    engine.mode = mode
                }
                // The engine freezes its own snapshot at run start, but
                // blocking the cards too keeps the UI honest — a click
                // mid-copy would otherwise look accepted and do nothing.
                .disabled(engine.isRunning)
                .opacity(engine.isRunning && engine.mode != mode ? 0.5 : 1)
            }

            HStack(spacing: 8) {
                quickToggle(
                    icon: "eye",
                    label: engine.l10n.quickToggleWatch,
                    isOn: $engine.watchAutoAddSource,
                    accent: .cyan
                )
                quickToggle(
                    icon: "play.circle",
                    label: engine.l10n.quickToggleAutoStart,
                    isOn: $engine.watchAutoStart,
                    accent: .indigo,
                    disabled: !engine.watchAutoAddSource
                )
                quickToggle(
                    icon: "eject",
                    label: engine.l10n.quickToggleAutoEject,
                    isOn: $engine.ejectAfterCopy,
                    accent: .blue
                )
                quickToggle(
                    icon: "doc.on.doc",
                    label: engine.l10n.quickToggleSkipDuplicates,
                    isOn: $engine.skipDuplicates,
                    accent: .teal
                )
            }
            .padding(.top, 6)
        }
    }

    @ViewBuilder
    private func quickToggle(icon: String,
                             label: String,
                             isOn: Binding<Bool>,
                             accent: Color,
                             disabled: Bool = false) -> some View {
        QuickToggleButton(icon: icon, label: label, isOn: isOn,
                          accent: accent, disabled: disabled)
    }
}

private struct QuickToggleButton: View {
    let icon: String
    let label: String
    @Binding var isOn: Bool
    let accent: Color
    let disabled: Bool

    @State private var isHovered = false
    @State private var isPressed = false

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            HStack(spacing: 5) {
                Image(systemName: isOn ? "\(icon).fill" : icon)
                    .font(.system(size: 12, weight: .semibold))
                    .symbolEffect(.bounce, value: isOn)
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(isOn ? accent.opacity(0.18) : Color.secondary.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(isOn ? accent.opacity(0.55) : Color.primary.opacity(0.08),
                            lineWidth: isOn ? 1.2 : 1)
            )
            .foregroundStyle(isOn ? accent : Color.secondary)
            .shadow(color: isOn ? accent.opacity(0.25) : .clear,
                    radius: isOn ? 5 : 0, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.45 : 1.0)
        .scaleEffect(isPressed ? 0.96 : (isHovered ? 1.02 : 1.0))
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressed)
        .animation(.spring(response: 0.30, dampingFraction: 0.7), value: isHovered)
        .animation(.snappy, value: isOn)
        .onHover { hovering in isHovered = hovering && !disabled }
        .pressEvents(isPressed: $isPressed)
    }
}
