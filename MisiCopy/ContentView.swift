//
//  ContentView.swift
//  MisiCopy
//
//  Created by Matthieu Misiraca on 03/06/2026.
//

import SwiftUI
import AppKit

struct ContentView: View {
    @Environment(AppModel.self) private var appModel
    @AppStorage("showStatusItem") private var showStatusItem: Bool = false

    var body: some View {
        @Bindable var bindable = appModel
        let engine = appModel.engine

        VStack(spacing: 14) {
            HeaderView(engine: engine, license: appModel.license)
                .padding(.horizontal, 20)
                .padding(.top, 18)

            HStack(alignment: .top, spacing: 18) {
                configurationColumn
                monitoringColumn
            }
            .padding(.horizontal, 20)

            FooterView(engine: engine)
                .padding(.bottom, 10)
        }
        .frame(width: Theme.Metrics.windowWidth, height: Theme.Metrics.windowHeight)
        .background(
            LinearGradient(
                colors: [
                    Theme.Palette.appBackgroundTop,
                    Theme.Palette.appBackground,
                    Theme.Palette.appBackgroundBottom
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .onChange(of: engine.stats.bytesProcessed) { _, _ in updateDockAndStatus() }
        .onChange(of: engine.isRunning) { _, _ in updateDockAndStatus() }
        .onAppear {
            StatusItemController.shared.setEnabled(showStatusItem)
            renameSettingsMenuItem(to: engine.l10n.menuSettings)
        }
        .onChange(of: showStatusItem) { _, newValue in
            StatusItemController.shared.setEnabled(newValue)
        }
        .onChange(of: engine.language) { _, _ in
            renameSettingsMenuItem(to: engine.l10n.menuSettings)
        }
        .sheet(isPresented: $bindable.historySheet) {
            HistoryView(engine: engine) { appModel.historySheet = false }
        }
        .sheet(isPresented: $bindable.savePresetSheet) {
            SavePresetSheet(engine: engine, store: appModel.presetStore) {
                appModel.savePresetSheet = false
            }
        }
        .sheet(isPresented: $bindable.managePresetsSheet) {
            ManagePresetsSheet(engine: engine, store: appModel.presetStore) {
                appModel.managePresetsSheet = false
            }
        }
        .alert(
            engine.l10n.preflightAlertTitle,
            isPresented: Binding(
                get: { engine.preflightIssue != nil },
                set: { if !$0 { engine.preflightIssue = nil } })
        ) {
            Button("OK", role: .cancel) { }
        } message: {
            if let issue = engine.preflightIssue {
                Text(engine.l10n.preflightAlertMessage(
                    name: issue.destinationName,
                    needed: engine.formatBytes(issue.neededBytes),
                    free: engine.formatBytes(issue.freeBytes),
                    missing: engine.formatBytes(issue.missingBytes)))
            }
        }
        .alert(
            engine.completionSummary?.success == true
                ? engine.l10n.flashSuccessTitle
                : engine.l10n.flashFailureTitle,
            isPresented: Binding(
                get: { engine.completionSummary != nil },
                set: { if !$0 { engine.completionSummary = nil } })
        ) {
            Button("OK", role: .cancel) { }
        } message: {
            if let summary = engine.completionSummary {
                Text(engine.l10n.completionDialogMessage(
                    verifyOnly: summary.verifyOnly,
                    verified: summary.verified,
                    failed: summary.failed,
                    bytes: engine.formatBytes(summary.totalBytes),
                    duration: engine.formatDuration(summary.duration)))
            }
        }
    }

    private var configurationColumn: some View {
        let engine = appModel.engine
        return ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: Theme.Metrics.sectionSpacing) {
                ModeSelectionView(engine: engine)
                SourceSelectionView(engine: engine)
                DestinationsView(engine: engine)
            }
            .padding(.vertical, 2)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var monitoringColumn: some View {
        let engine = appModel.engine
        return VStack(alignment: .leading, spacing: Theme.Metrics.sectionSpacing) {
            DITStructureView(engine: engine)
            StatsView(engine: engine)
            ActionButtonView(engine: engine)
            QueueView(engine: engine)
            ActivityLogView(engine: engine)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    /// SwiftUI's `Settings { ... }` scene auto-injects a menu item using
    /// the system locale. We override its title to follow the in-app
    /// language by walking the application menu (NSApp.mainMenu).
    private func renameSettingsMenuItem(to title: String) {
        guard let appMenu = NSApp.mainMenu?.items.first?.submenu else { return }
        // Standard SwiftUI menu uses showSettingsWindow:, the legacy
        // selector is showPreferencesWindow: — match either.
        let selectors: Set<Selector> = [
            Selector(("showSettingsWindow:")),
            Selector(("showPreferencesWindow:"))
        ]
        for item in appMenu.items where selectors.contains(item.action ?? Selector(("__none"))) {
            item.title = title
        }
    }

    private func updateDockAndStatus() {
        let engine = appModel.engine
        let tile = NSApp.dockTile
        let progressPercent: Int?
        if engine.isRunning, engine.stats.totalBytes > 0 {
            let pct = max(0, min(100, Int(engine.stats.progress * 100)))
            progressPercent = pct
            tile.badgeLabel = "\(pct) %"
            // First frame after a new run starts: ensure no stale value
            // from the previous session bleeds through visually.
            if tile.contentView !== DockProgressView.shared {
                DockProgressView.shared.reset()
            }
            tile.contentView = DockProgressView.shared.refreshed(progress: engine.stats.progress)
        } else {
            progressPercent = nil
            tile.badgeLabel = nil
            tile.contentView = nil // restore the plain app icon
        }
        tile.display()
        StatusItemController.shared.update(
            progressPercent: progressPercent,
            isRunning: engine.isRunning,
            speed: engine.isRunning ? engine.formatRate(engine.stats.bytesPerSecond) : nil
        )
    }
}

/// Custom dock-tile content view that draws the regular app icon plus a
/// thin progress bar overlaid at the bottom. The bar is the only macOS-
/// native way to put a real progress UI on the dock icon (the badge label
/// is just text).
private final class DockProgressView: NSView {
    static let shared = DockProgressView()
    private var progress: Double = 0

    func refreshed(progress: Double) -> NSView {
        self.progress = max(0, min(1, progress))
        needsDisplay = true
        return self
    }

    func reset() {
        progress = 0
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        // 1. Draw the app icon underneath so we don't lose it.
        NSApp.applicationIconImage?.draw(in: bounds,
                                         from: .zero,
                                         operation: .sourceOver,
                                         fraction: 1.0)

        // 2. Overlay a rounded progress bar across the bottom 12% of the icon.
        let barHeight = bounds.height * 0.08
        let inset = bounds.width * 0.10
        let trackRect = NSRect(x: bounds.minX + inset,
                               y: bounds.minY + bounds.height * 0.06,
                               width: bounds.width - inset * 2,
                               height: barHeight)
        let radius = barHeight / 2

        // Track (semi-transparent dark pill)
        NSColor(white: 0, alpha: 0.55).setFill()
        let track = NSBezierPath(roundedRect: trackRect,
                                 xRadius: radius, yRadius: radius)
        track.fill()

        // Fill (brand blue)
        let fillWidth = trackRect.width * CGFloat(progress)
        if fillWidth > 1 {
            let fillRect = NSRect(x: trackRect.minX,
                                  y: trackRect.minY,
                                  width: fillWidth,
                                  height: trackRect.height)
            NSColor(red: 0.18, green: 0.55, blue: 1.00, alpha: 1).setFill()
            let fill = NSBezierPath(roundedRect: fillRect,
                                    xRadius: radius, yRadius: radius)
            fill.fill()
        }
    }
}

#Preview {
    ContentView()
        .environment(AppModel())
}
