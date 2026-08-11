//
//  ProgressRing.swift
//  MisiCopyRemote
//
//  Circular progress indicator used at the top of the dashboard. Animates
//  smoothly between snapshot updates.
//

import SwiftUI
import UIKit

struct ProgressRing: View {
    let progress: Double
    /// When true, the ring softly pulses to signal active work.
    var isActive: Bool = false
    var lineWidth: CGFloat = 14
    var trackColor: Color = Color.secondary.opacity(0.18)
    var ringColor: Color = .blue

    @State private var pulse: Bool = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(trackColor, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(
                    LinearGradient(colors: [ringColor.opacity(0.7), ringColor],
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: isActive ? ringColor.opacity(pulse ? 0.45 : 0.15) : .clear,
                        radius: pulse ? 10 : 4)
                .animation(.easeOut(duration: 0.25), value: progress)
                .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true),
                           value: pulse)
        }
        .onAppear { if isActive { pulse = true } }
        .onChange(of: isActive) { _, newValue in pulse = newValue }
    }
}
