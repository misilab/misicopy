//
//  Theme.swift
//  MisiCopy
//

import SwiftUI
import AppKit

enum Theme {
    enum Palette {
        static let brand = Color(red: 0.30, green: 0.65, blue: 0.95)
        static let primary = Color.accentColor

        /// Surface that adapts to the system appearance — light grey in
        /// Light mode, near-black in Dark mode. Pairs with `cardBackground`
        /// so the cards remain one shade lighter than the canvas.
        static let appBackground = Color(nsColor: NSColor(name: nil) { appearance in
            appearance.isDark
            ? NSColor(red: 0.10, green: 0.10, blue: 0.12, alpha: 1)
            : NSColor(red: 0.95, green: 0.95, blue: 0.96, alpha: 1)
        })

        static let appBackgroundTop = Color(nsColor: NSColor(name: nil) { appearance in
            appearance.isDark
            ? NSColor(red: 0.13, green: 0.13, blue: 0.15, alpha: 1)
            : NSColor(red: 0.97, green: 0.97, blue: 0.98, alpha: 1)
        })

        static let appBackgroundBottom = Color(nsColor: NSColor(name: nil) { appearance in
            appearance.isDark
            ? NSColor(red: 0.07, green: 0.07, blue: 0.09, alpha: 1)
            : NSColor(red: 0.93, green: 0.93, blue: 0.95, alpha: 1)
        })

        static let cardBackground = Color(nsColor: NSColor(name: nil) { appearance in
            appearance.isDark
            ? NSColor(red: 0.16, green: 0.16, blue: 0.18, alpha: 1)
            : NSColor.white
        })

        /// Subtle hairline border. Stronger in Dark mode so cards keep
        /// definition against the dark canvas.
        static let cardBorder = Color(nsColor: NSColor(name: nil) { appearance in
            appearance.isDark
            ? NSColor.white.withAlphaComponent(0.10)
            : NSColor.black.withAlphaComponent(0.08)
        })

        static let cardSelectedBorder = Color.accentColor.opacity(0.55)
        static let cardSelectedBackground = Color.accentColor.opacity(0.10)

        static let statFound = Color.blue
        static let statCopied = Color.indigo
        static let statVerified = Color.green
        static let statFailed = Color.red

        static let logBackground = Color(nsColor: NSColor(name: nil) { appearance in
            appearance.isDark
            ? NSColor(red: 0.13, green: 0.13, blue: 0.15, alpha: 1)
            : NSColor(red: 0.92, green: 0.92, blue: 0.93, alpha: 1)
        })

        /// Shadow tinted black in Light mode, near-pure-black in Dark
        /// mode (a pure-black shadow on a dark canvas is invisible — we
        /// drop the opacity slightly and rely on tone separation alone).
        static let cardShadow = Color(nsColor: NSColor(name: nil) { appearance in
            appearance.isDark
            ? NSColor.black.withAlphaComponent(0.45)
            : NSColor.black.withAlphaComponent(0.06)
        })

        static let hoverShadow = Color(nsColor: NSColor(name: nil) { appearance in
            appearance.isDark
            ? NSColor.black.withAlphaComponent(0.55)
            : NSColor.black.withAlphaComponent(0.10)
        })
    }

    enum Metrics {
        static let windowWidth: CGFloat = 1280
        static let windowHeight: CGFloat = 970
        static let cardRadius: CGFloat = 12
        static let buttonRadius: CGFloat = 14
        static let sectionSpacing: CGFloat = 18
        static let cardPaddingV: CGFloat = 14
        static let cardPaddingH: CGFloat = 16
    }

    enum Typography {
        static func sectionHeader() -> Font {
            .system(size: 11, weight: .semibold, design: .default)
        }
        static func cardTitle() -> Font {
            .system(size: 14, weight: .semibold)
        }
        static func cardSubtitle() -> Font {
            .system(size: 12, weight: .regular)
        }
        static func bigStat() -> Font {
            .system(size: 28, weight: .bold, design: .rounded)
        }
        static func statLabel() -> Font {
            .system(size: 10, weight: .semibold)
        }
    }
}

extension NSAppearance {
    /// Convenience predicate that resolves the current appearance to a
    /// Dark / Light bucket so adaptive `NSColor(name:)` blocks stay
    /// readable.
    var isDark: Bool {
        bestMatch(from: [.darkAqua, .vibrantDark, .accessibilityHighContrastDarkAqua,
                         .accessibilityHighContrastVibrantDark]) != nil
    }
}

extension View {
    func cardStyle(selected: Bool = false) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: Theme.Metrics.cardRadius, style: .continuous)
                    .fill(selected ? Theme.Palette.cardSelectedBackground : Theme.Palette.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Metrics.cardRadius, style: .continuous)
                    .stroke(selected ? Theme.Palette.cardSelectedBorder : Theme.Palette.cardBorder,
                            lineWidth: selected ? 1.5 : 1)
            )
            .shadow(color: Theme.Palette.cardShadow.opacity(selected ? 1.0 : 0.45),
                    radius: selected ? 6 : 3,
                    x: 0, y: selected ? 3 : 1)
    }

    /// Bridges press / release to SwiftUI without a custom ButtonStyle.
    /// The `minimumDistance: 0` + `simultaneousGesture` combination is
    /// load-bearing: it tracks the press without eating Button taps.
    /// Shared by the action button, the mode cards and the quick toggles.
    func pressEvents(onPress: @escaping () -> Void,
                     onRelease: @escaping () -> Void) -> some View {
        self.simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in onPress() }
                .onEnded { _ in onRelease() }
        )
    }

    /// Convenience overload for the common "drive an isPressed @State"
    /// usage.
    func pressEvents(isPressed: Binding<Bool>) -> some View {
        pressEvents(onPress: { isPressed.wrappedValue = true },
                    onRelease: { isPressed.wrappedValue = false })
    }

    /// Pro-level hover lift: 1pt vertical translate + deeper shadow when
    /// the cursor enters the surface. Use on tappable cards (modes,
    /// drop zones, action buttons).
    func hoverLift(_ isHovered: Bool, intensity: CGFloat = 1) -> some View {
        self
            .offset(y: isHovered ? -intensity : 0)
            .shadow(color: Theme.Palette.hoverShadow.opacity(isHovered ? 1 : 0),
                    radius: isHovered ? 10 : 0, x: 0, y: isHovered ? 6 : 0)
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: isHovered)
    }
}
