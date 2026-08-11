//
//  HeaderView.swift
//  MisiCopy
//

import SwiftUI
import AppKit

struct HeaderView: View {
    @Bindable var engine: CopyEngine
    @Bindable var license: LicenseManager

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            AppIconView(cornerStyle: .ui)
                .frame(width: 50, height: 50)
                .shadow(color: Color.black.opacity(0.08), radius: 6, y: 2)

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 8) {
                    Text("MisiCopy")
                        .font(.system(size: 22, weight: .bold))
                    if engine.isRunning {
                        RunningPulse()
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                Text(engine.l10n.headerSubtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .animation(.snappy, value: engine.isRunning)

            Spacer(minLength: 0)

            if let today = todaySummaryText {
                Text(today)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.secondary.opacity(0.08)))
                    .overlay(Capsule().stroke(Color.primary.opacity(0.08), lineWidth: 0.5))
            }

            donationControl

            languagePicker
        }
        .padding(.horizontal, 4)
    }

    /// "Today: 3 card(s) · 1.2 TB · 0 errors" — aggregated from the
    /// session history, real transfers only. Hidden until the first
    /// completed session of the day.
    private var todaySummaryText: String? {
        let today = engine.history.records.filter {
            Calendar.current.isDateInToday($0.startDate) && !$0.simulation
        }
        guard !today.isEmpty else { return nil }
        let cards = today.reduce(0) { $0 + $1.sourcePaths.count }
        let bytes = today.reduce(Int64(0)) { $0 + $1.totalBytes }
        let errors = today.reduce(0) { $0 + $1.failed }
        return engine.l10n.todaySummary(cards: cards,
                                        volume: engine.formatBytes(bytes),
                                        errors: errors)
    }

    private var languagePicker: some View {
        Menu {
            ForEach(AppLanguage.allCases) { lang in
                Button {
                    engine.language = lang
                } label: {
                    HStack {
                        Text(lang.displayName)
                        if engine.language == lang {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "globe")
                Text(engine.language.shortCode)
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(.secondary)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
    }

    @ViewBuilder
    private var donationControl: some View {
        if case .licensed = license.status {
            HStack(spacing: 4) {
                Image(systemName: "heart.fill").foregroundStyle(.pink)
                Text(engine.l10n.donateBadge).font(.system(size: 11, weight: .bold))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color.pink.opacity(0.12)))
        } else {
            Button {
                if let url = URL(string: LicenseConfig.purchaseURL) {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                    Text(engine.l10n.donateButton).font(.system(size: 11, weight: .semibold))
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.pink)
            .controlSize(.small)
        }
    }
}

/// Tiny green dot with an expanding ring — appears next to "MisiCopy" while
/// a copy is running. Telegraphs activity at a glance without taking room.
private struct RunningPulse: View {
    @State private var pulse: CGFloat = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.green.opacity(0.5), lineWidth: 1.5)
                .frame(width: 14, height: 14)
                .scaleEffect(1 + pulse * 0.8)
                .opacity(1 - pulse)
            Circle()
                .fill(Color.green)
                .frame(width: 8, height: 8)
                .shadow(color: Color.green.opacity(0.6), radius: 4)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2).repeatForever(autoreverses: false)) {
                pulse = 1
            }
        }
    }
}

// MARK: - Preset sheets (presented from the App scene via AppModel)

struct SavePresetSheet: View {
    @Bindable var engine: CopyEngine
    @Bindable var store: PresetStore
    let onClose: () -> Void
    @State private var name: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(engine.l10n.dialogPresetNameTitle)
                .font(.headline)
            TextField(engine.l10n.dialogPresetNamePrompt, text: $name)
                .textFieldStyle(.roundedBorder)
                .frame(width: 360)
            HStack {
                Spacer()
                Button(engine.l10n.buttonCancel, action: onClose)
                    .keyboardShortcut(.cancelAction)
                Button(engine.l10n.buttonSave) {
                    let trimmed = name.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else { return }
                    let preset = engine.capturePreset(named: trimmed)
                    store.add(preset)
                    engine.log(.success, engine.l10n.logPresetSaved(preset.name))
                    onClose()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
    }
}

struct ManagePresetsSheet: View {
    @Bindable var engine: CopyEngine
    @Bindable var store: PresetStore
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(engine.l10n.menuPresetsManage)
                .font(.headline)
            List {
                ForEach(store.presets) { preset in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(preset.name).font(.system(size: 13, weight: .semibold))
                            Text("\(engine.l10n.modeTitle(preset.mode)) · \(preset.algorithm.displayName)")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button(engine.l10n.buttonDelete) { store.remove(preset) }
                            .controlSize(.small)
                    }
                    .padding(.vertical, 2)
                }
            }
            .frame(width: 420, height: 240)
            HStack {
                Spacer()
                Button(engine.l10n.buttonClose, action: onClose)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
    }
}
