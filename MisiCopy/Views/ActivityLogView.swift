//
//  ActivityLogView.swift
//  MisiCopy
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ActivityLogView: View {
    @Bindable var engine: CopyEngine
    @State private var showClearConfirm = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionHeader(icon: "list.bullet.rectangle", title: engine.l10n.sectionJournal)

            ZStack {
                RoundedRectangle(cornerRadius: Theme.Metrics.cardRadius, style: .continuous)
                    .fill(Theme.Palette.logBackground)
                if engine.logs.isEmpty {
                    VStack(spacing: 6) {
                        Image(systemName: "tray")
                            .font(.system(size: 18))
                            .foregroundStyle(.secondary)
                        Text(engine.l10n.journalEmpty)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 4) {
                                // Most recent first — newest entries
                                // stay visible without forcing the user
                                // to scroll to the bottom on long sessions.
                                ForEach(engine.logs.reversed()) { entry in
                                    LogRow(entry: entry).id(entry.id)
                                }
                            }
                            .padding(10)
                        }
                        .scrollIndicators(.visible)
                        .onChange(of: engine.logs.count) { _, _ in
                            if let last = engine.logs.last {
                                withAnimation { proxy.scrollTo(last.id, anchor: .top) }
                            }
                        }
                    }
                }
            }
            .frame(minHeight: 200, maxHeight: .infinity)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Metrics.cardRadius, style: .continuous)
                    .stroke(Theme.Palette.cardBorder, lineWidth: 1)
            )

            HStack(spacing: 14) {
                Button {
                    showClearConfirm = true
                } label: {
                    Label(engine.l10n.buttonClear, systemImage: "trash")
                        .font(.system(size: 11))
                }
                .buttonStyle(.borderless)
                .disabled(engine.logs.isEmpty)

                Button { exportMHL() } label: {
                    Label(engine.l10n.buttonExportMHL, systemImage: "square.and.arrow.up")
                        .font(.system(size: 11))
                }
                .buttonStyle(.borderless)
                .disabled(engine.files.isEmpty)

                Button { verifyMHL() } label: {
                    Label(engine.l10n.buttonVerifyMHL, systemImage: "checkmark.shield")
                        .font(.system(size: 11))
                }
                .buttonStyle(.borderless)
                .disabled(engine.isRunning)

                Button { exportJournal() } label: {
                    Label(engine.l10n.buttonJournal, systemImage: "doc.text")
                        .font(.system(size: 11))
                }
                .buttonStyle(.borderless)
                .disabled(engine.logs.isEmpty)

                Spacer()
            }
            .foregroundStyle(.secondary)
        }
        .confirmationDialog(engine.l10n.confirmClearJournalTitle,
                            isPresented: $showClearConfirm,
                            titleVisibility: .visible) {
            Button(engine.l10n.confirmClearJournalAction, role: .destructive) {
                engine.clearLogs()
            }
            Button(engine.l10n.buttonCancel, role: .cancel) {}
        } message: {
            Text(engine.l10n.confirmClearJournalMessage)
        }
    }

    @MainActor
    private func exportMHL() {
        guard !engine.isRunning, !engine.files.isEmpty else { return }
        let panel = NSSavePanel()
        let fmt = DateFormatter(); fmt.dateFormat = "yyyyMMdd-HHmmss"
        panel.nameFieldStringValue = "MisiCopy-\(fmt.string(from: Date())).mhl"
        panel.allowedContentTypes = [.xml]
        panel.title = engine.l10n.panelExportTitle
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let xml = engine.exportMHL()
        if let data = xml.data(using: .utf8) {
            do {
                try data.write(to: url, options: .atomic)
                engine.log(.success, engine.l10n.exportSucceeded(url.lastPathComponent))
            } catch {
                engine.log(.error, engine.l10n.exportFailed(error.localizedDescription))
            }
        }
    }

    @MainActor
    private func exportJournal() {
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

    @MainActor
    private func verifyMHL() {
        guard !engine.isRunning else { return }
        let mhlPanel = NSOpenPanel()
        mhlPanel.canChooseFiles = true
        mhlPanel.canChooseDirectories = false
        mhlPanel.allowsMultipleSelection = false
        mhlPanel.allowedContentTypes = [.xml]
        mhlPanel.title = engine.l10n.panelVerifyTitle
        mhlPanel.prompt = engine.l10n.panelSelect
        guard mhlPanel.runModal() == .OK, let mhlURL = mhlPanel.url else { return }

        let rootPanel = NSOpenPanel()
        rootPanel.canChooseFiles = false
        rootPanel.canChooseDirectories = true
        rootPanel.title = engine.l10n.panelChooseSourceTitle
        rootPanel.prompt = engine.l10n.panelSelect
        let sourceRoot: URL? = (rootPanel.runModal() == .OK) ? rootPanel.url : nil
        engine.verifyMHL(at: mhlURL, sourceRoot: sourceRoot)
    }
}

private struct LogRow: View {
    let entry: LogEntry

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: entry.level.iconName)
                .font(.system(size: 10))
                .foregroundStyle(entry.level.color)
                .frame(width: 14, alignment: .center)
            Text(entry.timeString)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.secondary)
            Text(entry.message)
                .font(.system(size: 11))
                .foregroundStyle(.primary)
            Spacer(minLength: 0)
        }
    }
}
