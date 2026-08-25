//
//  MisiCopyApp.swift
//  MisiCopy
//
//  Created by Matthieu Misiraca on 03/06/2026.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers
import Sparkle

@main
struct MisiCopyApp: App {
    @State private var appModel = AppModel()
    @NSApplicationDelegateAdaptor(MisiCopyAppDelegate.self) private var appDelegate
    private let updaterController: SPUStandardUpdaterController

    init() {
        let controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        // Force auto-checks on every launch, regardless of what the user
        // may have stored in UserDefaults from previous versions. Avoids
        // the "no update ever proposed" case when Sparkle thinks the user
        // opted out at some point.
        controller.updater.automaticallyChecksForUpdates = true
        controller.updater.updateCheckInterval = 3600 // 1 hour
        controller.updater.automaticallyDownloadsUpdates = false
        updaterController = controller
        // Kick off an immediate background check on launch so users on
        // older versions don't wait up to an hour for the first check.
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            controller.updater.checkForUpdatesInBackground()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appModel)
                .onAppear {
                    appDelegate.license = appModel.license
                    appDelegate.engine = appModel.engine
                    appDelegate.l10n = { appModel.engine.l10n }
                }
        }
        .windowResizability(.contentSize)
        .windowStyle(.titleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(after: .appInfo) {
                Button(appModel.engine.l10n.menuCheckForUpdates) {
                    updaterController.checkForUpdates(nil)
                }
                Button(appModel.engine.l10n.menuDonate) {
                    if let url = URL(string: LicenseConfig.purchaseURL) {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
            fileMenu
            jobMenu
            optionsMenu
            presetsMenu
            languageMenu
        }

        Settings {
            SettingsView()
                .environment(appModel)
        }
    }

    // MARK: - File

    @CommandsBuilder
    private var fileMenu: some Commands {
        let l = appModel.engine.l10n
        CommandMenu(l.menuFile) {
            Button(l.menuVerifyMHL) { verifyMHL() }
                .keyboardShortcut("v", modifiers: [.command, .shift])
            Button(l.menuExportMHLv1) { exportReport(.mhlV1) }
                .keyboardShortcut("e", modifiers: .command)
                .disabled(appModel.engine.files.isEmpty)
            Button(l.menuExportASCMHL) { exportReport(.ascmhl) }
                .keyboardShortcut("e", modifiers: [.command, .shift])
                .disabled(appModel.engine.files.isEmpty)
            Button(l.menuExportCSV) { exportReport(.csv) }
                .disabled(appModel.engine.files.isEmpty)
            Button(l.menuExportHTML) { exportReport(.html) }
                .disabled(appModel.engine.files.isEmpty)
            Button(l.menuExportJournal) { exportJournal() }
                .keyboardShortcut("l", modifiers: [.command, .shift])
                .disabled(appModel.engine.logs.isEmpty)
            Divider()
            Button(l.menuHistoryOpen2) { appModel.historySheet = true }
                .keyboardShortcut("y", modifiers: .command)
            Divider()
            Button(l.menuClearLog) { appModel.engine.clearLogs() }
                .disabled(appModel.engine.logs.isEmpty)
        }
    }

    @MainActor
    private func exportJournal() {
        let engine = appModel.engine
        guard !engine.logs.isEmpty else { return }
        let panel = NSSavePanel()
        let fmt = DateFormatter(); fmt.dateFormat = "yyyyMMdd-HHmmss"
        panel.nameFieldStringValue = "MisiCopy-journal-\(fmt.string(from: Date())).txt"
        panel.allowedContentTypes = [.plainText]
        panel.title = engine.l10n.panelExportJournal
        guard panel.runModal() == .OK, let url = panel.url else { return }
        if let data = engine.exportJournal().data(using: .utf8) {
            do {
                try data.write(to: url, options: .atomic)
                engine.log(.success, engine.l10n.exportSucceeded(url.lastPathComponent))
            } catch {
                engine.log(.error, engine.l10n.exportFailed(error.localizedDescription))
            }
        }
    }

    private enum ReportFormat {
        case mhlV1, ascmhl, csv, html
        var ext: String {
            switch self {
            case .mhlV1: return "mhl"
            case .ascmhl: return "ascmhl"
            case .csv: return "csv"
            case .html: return "html"
            }
        }
        /// Content type matching `ext` — declared explicitly because
        /// macOS doesn't know .mhl/.ascmhl, and a save panel silently
        /// renames the file to the nearest allowed type otherwise
        /// (an exported MHL used to land on disk as .xml).
        var contentType: UTType {
            switch self {
            case .mhlV1: return UTType(filenameExtension: "mhl") ?? .xml
            case .ascmhl: return UTType(filenameExtension: "ascmhl") ?? .xml
            case .csv: return .commaSeparatedText
            case .html: return .html
            }
        }
    }

    @MainActor
    private func exportReport(_ format: ReportFormat) {
        let engine = appModel.engine
        guard !engine.isRunning, !engine.files.isEmpty else { return }
        let panel = NSSavePanel()
        let fmt = DateFormatter(); fmt.dateFormat = "yyyyMMdd-HHmmss"
        panel.nameFieldStringValue = "MisiCopy-\(fmt.string(from: Date())).\(format.ext)"
        panel.allowedContentTypes = [format.contentType]
        panel.title = engine.l10n.panelExportTitle
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let content: String
        switch format {
        case .mhlV1:  content = engine.exportMHL()
        case .ascmhl: content = engine.exportASCMHL()
        case .csv:
            content = CSVExporter.makeCSV(
                files: engine.files, algorithm: engine.algorithm,
                startDate: engine.startDate ?? Date(),
                endDate: engine.endDate ?? Date())
        case .html:
            content = HTMLExporter.makeHTML(
                source: engine.sources.first?.url,
                destinations: engine.destinations,
                files: engine.files, stats: engine.stats,
                mode: engine.mode, algorithm: engine.algorithm,
                startDate: engine.startDate ?? Date(),
                endDate: engine.endDate ?? Date(),
                l10n: engine.l10n)
        }
        if let data = content.data(using: .utf8) {
            do {
                try data.write(to: url, options: .atomic)
                engine.log(.success, engine.l10n.exportSucceeded(url.lastPathComponent))
            } catch {
                engine.log(.error, engine.l10n.exportFailed(error.localizedDescription))
            }
        }
    }

    // MARK: - Job

    @CommandsBuilder
    private var jobMenu: some Commands {
        let l = appModel.engine.l10n
        CommandMenu(l.menuJob) {
            Button(appModel.engine.isRunning ? l.menuCancel : l.menuStart) {
                if appModel.engine.isRunning {
                    appModel.engine.cancel()
                } else {
                    appModel.engine.start()
                }
            }
            .keyboardShortcut("r", modifiers: .command)
            .disabled(!appModel.engine.isRunning &&
                      (appModel.engine.sources.isEmpty || appModel.engine.destinations.isEmpty))

            Button(appModel.engine.isPaused ? l.actionResume : l.actionPause) {
                appModel.engine.togglePause()
            }
            .keyboardShortcut("p", modifiers: .command)
            .disabled(!appModel.engine.isRunning)

            Divider()

            Button(l.menuAddToQueue) { appModel.engine.enqueueCurrent() }
                .keyboardShortcut("a", modifiers: [.command, .shift])
                .disabled(appModel.engine.sources.isEmpty || appModel.engine.destinations.isEmpty)

            Button(l.menuClearQueue) { appModel.engine.clearQueue() }
                .disabled(appModel.engine.queue.isEmpty)

            Divider()

            Menu(l.menuSpeedTest) {
                ForEach(appModel.engine.destinations) { dest in
                    Button(dest.displayName) {
                        appModel.engine.runDriveSpeedTest(at: dest.url)
                    }
                }
                if appModel.engine.destinations.isEmpty {
                    Text(l.menuNoDest).foregroundStyle(.secondary)
                }
            }
            .disabled(appModel.engine.destinations.isEmpty || appModel.engine.isRunning)
        }
    }

    // MARK: - Options

    @CommandsBuilder
    private var optionsMenu: some Commands {
        @Bindable var engine = appModel.engine
        let l = appModel.engine.l10n

        CommandMenu(l.menuOptions) {
            Toggle(l.menuToggleSim, isOn: $engine.simulation)
            Toggle(l.menuTogglePreserve, isOn: $engine.preserveStructure)
            Toggle(l.menuToggleEjectAfter, isOn: $engine.ejectAfterCopy)
            Toggle(l.menuToggleNotif, isOn: $engine.notifyOnFinish)
            Toggle(l.menuToggleSkipSystem, isOn: $engine.skipSystemFiles)
            Toggle(l.menuToggleOrganize, isOn: $engine.organizeByDate)
            Toggle(l.menuToggleThumbs, isOn: $engine.includePDFThumbnails)
            Toggle(l.menuToggleDuplicates, isOn: $engine.skipDuplicates)

            Divider()

            Section(l.menuWatchSection) {
                Toggle(l.menuWatchAutoAdd, isOn: $engine.watchAutoAddSource)
                Toggle(l.menuWatchAutoStart, isOn: $engine.watchAutoStart)
                    .disabled(!engine.watchAutoAddSource)
            }

            Divider()

            Menu(l.menuAlgo) {
                ForEach(ChecksumAlgorithm.allCases) { algo in
                    Button {
                        engine.algorithm = algo
                    } label: {
                        HStack {
                            Text(algo.displayName)
                            if engine.algorithm == algo { Image(systemName: "checkmark") }
                        }
                    }
                }
            }

            Menu(l.menuBandwidthLimit) {
                ForEach(bandwidthChoices, id: \.self) { value in
                    Button {
                        engine.bandwidthLimitMBs = value
                    } label: {
                        HStack {
                            Text(value == 0 ? l.menuUnlimited : "\(Int(value)) MB/s")
                            if engine.bandwidthLimitMBs == value { Image(systemName: "checkmark") }
                        }
                    }
                }
            }
        }
    }

    private let bandwidthChoices: [Double] = [0, 10, 25, 50, 100, 250]

    // MARK: - Presets

    @CommandsBuilder
    private var presetsMenu: some Commands {
        let l = appModel.engine.l10n
        CommandMenu(l.menuPresetsTitle) {
            if appModel.presetStore.presets.isEmpty {
                Text(l.menuNoPreset)
            } else {
                ForEach(appModel.presetStore.presets) { preset in
                    Button(preset.name) { appModel.engine.applyPreset(preset) }
                }
                Divider()
            }
            Button(l.menuSaveCurrent) { appModel.savePresetSheet = true }
            Button(l.menuManagePresets) { appModel.managePresetsSheet = true }
                .disabled(appModel.presetStore.presets.isEmpty)
        }
    }

    // MARK: - Language

    @CommandsBuilder
    private var languageMenu: some Commands {
        let l = appModel.engine.l10n
        CommandMenu(l.menuLanguageTitle) {
            ForEach(AppLanguage.allCases) { lang in
                Button {
                    appModel.engine.language = lang
                } label: {
                    HStack {
                        Text(lang.displayName)
                        if appModel.engine.language == lang { Image(systemName: "checkmark") }
                    }
                }
            }
        }
    }

    // MARK: - Actions backing the File menu

    @MainActor
    private func verifyMHL() {
        guard !appModel.engine.isRunning else { return }
        let mhlPanel = NSOpenPanel()
        mhlPanel.canChooseFiles = true
        mhlPanel.canChooseDirectories = false
        mhlPanel.allowsMultipleSelection = false
        // macOS doesn't know the .mhl / .ascmhl extensions conform to
        // XML, so a bare [.xml] filter greys every MHL file out. Declare
        // the extensions explicitly (dynamic UTTypes) and keep .xml as a
        // fallback for MHLs saved with an .xml extension.
        var mhlTypes: [UTType] = [.xml]
        if let mhl = UTType(filenameExtension: "mhl") { mhlTypes.append(mhl) }
        if let ascmhl = UTType(filenameExtension: "ascmhl") { mhlTypes.append(ascmhl) }
        mhlPanel.allowedContentTypes = mhlTypes
        mhlPanel.title = appModel.engine.l10n.panelVerifyTitle
        mhlPanel.prompt = appModel.engine.l10n.panelSelect
        guard mhlPanel.runModal() == .OK, let mhlURL = mhlPanel.url else { return }

        let rootPanel = NSOpenPanel()
        rootPanel.canChooseFiles = false
        rootPanel.canChooseDirectories = true
        rootPanel.title = appModel.engine.l10n.panelChooseSourceTitle
        rootPanel.prompt = appModel.engine.l10n.panelSelect
        let sourceRoot: URL? = (rootPanel.runModal() == .OK) ? rootPanel.url : nil
        appModel.engine.verifyMHL(at: mhlURL, sourceRoot: sourceRoot)
    }
}

/// Shows a purchase reminder when the user quits the app and the trial has
/// expired. Wired up to the SwiftUI app via `@NSApplicationDelegateAdaptor`.
@MainActor
final class MisiCopyAppDelegate: NSObject, NSApplicationDelegate {
    var license: LicenseManager?
    var l10n: (() -> Localization)?
    var engine: CopyEngine?

    nonisolated override init() { super.init() }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if engine?.isRunning == true { return .terminateNow }
        guard let license else { return .terminateNow }
        guard case .expired = license.status else { return .terminateNow }
        let strings = l10n?() ?? Localization(language: .fr)

        let alert = NSAlert()
        alert.messageText = strings.donateQuitTitle
        alert.informativeText = strings.donateQuitBody
        alert.alertStyle = .warning
        alert.addButton(withTitle: strings.donateButton)
        alert.addButton(withTitle: strings.donateQuitContinue)

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            if let url = URL(string: LicenseConfig.purchaseURL) {
                NSWorkspace.shared.open(url)
            }
            return .terminateCancel
        }
        return .terminateNow
    }
}
