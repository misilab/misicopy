//
//  DITStructureView.swift
//  MisiCopy
//
//  Toggle + project name field that activates the DIT-standard folder
//  structure on each destination (`<projet>/01_RUSHES/<JJMMAA>/<cam>/…`).
//

import SwiftUI

struct DITStructureView: View {
    @Bindable var engine: CopyEngine
    @State private var showReelResetConfirm = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(icon: "folder.badge.gearshape",
                          title: engine.l10n.sectionDIT)

            VStack(alignment: .leading, spacing: 10) {
                Toggle(isOn: $engine.ditMode) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(engine.l10n.ditToggleTitle)
                            .font(Theme.Typography.cardTitle())
                        Text(engine.l10n.ditToggleSubtitle)
                            .font(Theme.Typography.cardSubtitle())
                            .foregroundStyle(.secondary)
                    }
                }
                .toggleStyle(.switch)

                if engine.ditMode {
                    HStack(spacing: 8) {
                        Image(systemName: "film.stack")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .frame(width: 18)
                        TextField(engine.l10n.ditProjectPlaceholder,
                                  text: $engine.projectName)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                    }
                    Toggle(isOn: $engine.reelSubfolderEnabled) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(engine.l10n.ditReelToggleTitle)
                                .font(Theme.Typography.cardTitle())
                            Text(engine.l10n.ditReelToggleSubtitle)
                                .font(Theme.Typography.cardSubtitle())
                                .foregroundStyle(.secondary)
                        }
                    }
                    .toggleStyle(.switch)
                    if engine.reelSubfolderEnabled {
                        Button {
                            showReelResetConfirm = true
                        } label: {
                            Label(engine.l10n.ditReelResetButton,
                                  systemImage: "arrow.counterclockwise")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .buttonStyle(.borderless)
                        .controlSize(.small)
                        .foregroundStyle(.red)
                        .disabled(engine.isRunning)
                    }
                    Toggle(isOn: $engine.ditCopyProxyEnabled) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(engine.l10n.ditProxyToggleTitle)
                                .font(Theme.Typography.cardTitle())
                            Text(engine.l10n.ditProxyToggleSubtitle)
                                .font(Theme.Typography.cardSubtitle())
                                .foregroundStyle(.secondary)
                        }
                    }
                    .toggleStyle(.switch)
                    Text(previewLine)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .truncationMode(.middle)
                }
            }
            .padding(.horizontal, Theme.Metrics.cardPaddingH)
            .padding(.vertical, 10)
            .cardStyle()
        }
        .onChange(of: engine.ditMode) { _, _ in engine.saveDITSettings() }
        .onChange(of: engine.projectName) { _, _ in engine.saveDITSettings() }
        .onChange(of: engine.reelSubfolderEnabled) { _, _ in engine.saveDITSettings() }
        .onChange(of: engine.ditCopyProxyEnabled) { _, _ in engine.saveDITSettings() }
        .confirmationDialog(engine.l10n.ditReelResetConfirmTitle,
                            isPresented: $showReelResetConfirm,
                            titleVisibility: .visible) {
            Button(engine.l10n.ditReelResetConfirmAction, role: .destructive) {
                engine.resetReelCounter()
            }
            Button(engine.l10n.buttonCancel, role: .cancel) {}
        } message: {
            Text(engine.l10n.ditReelResetConfirmMessage)
        }
    }

    private var previewLine: String {
        if engine.reelSubfolderEnabled {
            return engine.l10n.ditPreviewWithReel(project: previewProject,
                                                  date: previewDateStamp)
        }
        return engine.l10n.ditPreview(project: previewProject,
                                      date: previewDateStamp)
    }

    private var previewProject: String {
        let raw = engine.projectName.trimmingCharacters(in: .whitespaces)
        return raw.isEmpty ? "PROJET" : raw
    }

    private var previewDateStamp: String {
        let stamp = DateFormatter()
        stamp.dateFormat = "ddMMyy"
        return stamp.string(from: Date())
    }
}
