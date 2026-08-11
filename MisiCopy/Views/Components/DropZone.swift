//
//  DropZone.swift
//  MisiCopy
//
//  Reusable folder drop zone with title/subtitle and a "Choose" button.
//

import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct DropZone: View {
    let icon: String
    let title: String
    let subtitle: String
    let buttonTitle: String
    let onPick: () -> Void
    let onDrop: (URL) -> Void

    @State private var isTargeted = false
    @State private var isHovered = false
    @State private var dashPhase: CGFloat = 0

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(isTargeted ? 0.18 : 0))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(isTargeted ? Color.accentColor : .secondary)
                    .scaleEffect(isTargeted ? 1.15 : 1.0)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(Theme.Typography.cardTitle())
                Text(subtitle)
                    .font(Theme.Typography.cardSubtitle())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer(minLength: 0)
            Button(action: onPick) {
                HStack(spacing: 4) {
                    Image(systemName: "folder.badge.plus")
                    Text(buttonTitle)
                }
            }
            .controlSize(.small)
        }
        .padding(.horizontal, Theme.Metrics.cardPaddingH)
        .padding(.vertical, Theme.Metrics.cardPaddingV)
        .background(
            RoundedRectangle(cornerRadius: Theme.Metrics.cardRadius, style: .continuous)
                .fill(isTargeted ? Theme.Palette.cardSelectedBackground : Theme.Palette.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Metrics.cardRadius, style: .continuous)
                .strokeBorder(
                    isTargeted ? Theme.Palette.cardSelectedBorder : Theme.Palette.cardBorder,
                    style: StrokeStyle(lineWidth: isTargeted ? 1.5 : 1,
                                       dash: isTargeted ? [5, 4] : [],
                                       dashPhase: isTargeted ? dashPhase : 0)
                )
        )
        .scaleEffect(isTargeted ? 1.012 : 1.0)
        .animation(.spring(response: 0.28, dampingFraction: 0.7), value: isTargeted)
        .hoverLift(isHovered && !isTargeted)
        .onHover { hovering in isHovered = hovering }
        .onChange(of: isTargeted) { _, newValue in
            if newValue {
                withAnimation(.linear(duration: 0.6).repeatForever(autoreverses: false)) {
                    dashPhase = 18
                }
            } else {
                // Kill the repeatForever — a plain assignment leaves the
                // CADisplayLink ticking on the (now hidden) dashed border.
                var noAnim = Transaction()
                noAnim.disablesAnimations = true
                withTransaction(noAnim) { dashPhase = 0 }
            }
        }
        .onDrop(of: [UTType.fileURL], isTargeted: $isTargeted) { providers in
            guard let provider = providers.first else { return false }
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                guard let url else { return }
                DispatchQueue.main.async { onDrop(url) }
            }
            return true
        }
    }
}
