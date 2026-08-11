//
//  AppIconView.swift
//  MisiCopy
//
//  Shared brand icon used in HeaderView and to render the macOS app icon.
//  Scales fluidly to any size — pass `.frame(width:, height:)`.
//

import SwiftUI

struct AppIconView: View {
    /// 0 → flat. macOS icons are tile-sized; on the app icon we slightly inset.
    var cornerStyle: CornerStyle = .ui

    enum CornerStyle {
        case ui          // Used inside the app header
        case macIcon     // Squircle for the .icns / 1024x1024 export
    }

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack {
                background(size: s)
                shine(size: s)
                glyph(size: s)
                checkBadge(size: s)
            }
            .frame(width: s, height: s)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    @ViewBuilder
    private func background(size s: CGFloat) -> some View {
        let radius = (cornerStyle == .macIcon ? 0.225 : 0.215) * s
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.20, green: 0.92, blue: 1.00),
                        Color(red: 0.18, green: 0.55, blue: 1.00),
                        Color(red: 0.28, green: 0.32, blue: 0.96)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.55), Color.white.opacity(0.0)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        lineWidth: s * 0.012
                    )
            )
    }

    @ViewBuilder
    private func shine(size s: CGFloat) -> some View {
        let radius = (cornerStyle == .macIcon ? 0.225 : 0.215) * s
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color.white.opacity(0.28), Color.clear],
                    startPoint: .top, endPoint: .center
                )
            )
            .padding(s * 0.04)
            .blendMode(.plusLighter)
            .opacity(0.6)
    }

    @ViewBuilder
    private func glyph(size s: CGFloat) -> some View {
        Image(systemName: "shippingbox.fill")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(.white)
            .frame(width: s * 0.52, height: s * 0.52)
            .offset(y: -s * 0.02)
            .shadow(color: Color(red: 0.05, green: 0.20, blue: 0.55).opacity(0.45),
                    radius: s * 0.025, x: 0, y: s * 0.015)
    }

    @ViewBuilder
    private func checkBadge(size s: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.55, green: 1.00, blue: 0.45),
                            Color(red: 0.10, green: 0.78, blue: 0.30)
                        ],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .overlay(Circle().stroke(Color.white, lineWidth: s * 0.018))
            Image(systemName: "checkmark")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .font(.system(size: s * 0.12, weight: .heavy))
                .foregroundStyle(.white)
                .padding(s * 0.05)
        }
        .frame(width: s * 0.32, height: s * 0.32)
        .shadow(color: Color.black.opacity(0.18), radius: s * 0.02, x: 0, y: s * 0.012)
        .offset(x: s * 0.22, y: s * 0.22)
    }
}

#Preview("App Icon — 1024") {
    AppIconView(cornerStyle: .macIcon)
        .frame(width: 1024, height: 1024)
        .padding()
        .background(Color.gray.opacity(0.15))
}

#Preview("Header — 46") {
    AppIconView(cornerStyle: .ui)
        .frame(width: 46, height: 46)
        .padding()
}
