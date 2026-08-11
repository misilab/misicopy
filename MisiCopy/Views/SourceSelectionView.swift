//
//  SourceSelectionView.swift
//  MisiCopy
//

import SwiftUI
import AppKit

struct SourceSelectionView: View {
    @Bindable var engine: CopyEngine

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                SectionHeader(icon: "tray.and.arrow.down", title: engine.l10n.sectionSource)
                Spacer()
                Button(action: pickSource) {
                    Label(engine.l10n.buttonAdd, systemImage: "plus")
                        .font(.system(size: 11, weight: .semibold))
                }
                .controlSize(.small)
                .buttonStyle(.borderless)
                .foregroundStyle(Color.accentColor)
                .padding(.bottom, 4)
            }

            if let saved = engine.resumableSession {
                ResumeBanner(
                    title: engine.l10n.sessionResumeTitle,
                    subtitle: engine.l10n.sessionResumeSubtitle(savedAt: saved.savedAt),
                    resumeLabel: engine.l10n.buttonResume,
                    dismissLabel: engine.l10n.dismiss,
                    onResume: { engine.resumeLastSession() },
                    onDismiss: { engine.dismissResumableSession() }
                )
            }

            ForEach(engine.suggestedRemovable) { source in
                if let previous = source.previousOffload {
                    // Card memory: this volume was already offloaded —
                    // offer to re-verify (switches to verify-only mode),
                    // re-copy anyway, or dismiss.
                    SuggestedSourceRow(
                        source: source,
                        title: engine.l10n.cardAlreadyOffloaded(
                            source.displayName,
                            when: engine.l10n.formattedDateTime(previous.date),
                            files: previous.files,
                            volume: engine.formatBytes(previous.bytes)),
                        addLabel: engine.l10n.buttonRecopy,
                        reverifyLabel: engine.l10n.buttonReverify,
                        dismissLabel: engine.l10n.dismiss,
                        onAdd: { pickViaOpenPanelForVolume(source) },
                        onReverify: {
                            pickViaOpenPanelForVolume(source)
                            engine.mode = .verifyOnly
                        },
                        onDismiss: { engine.dismissSuggestion(source) }
                    )
                } else {
                    SuggestedSourceRow(
                        source: source,
                        title: engine.l10n.cardDetected(source.displayName),
                        addLabel: engine.l10n.addAsSource,
                        dismissLabel: engine.l10n.dismiss,
                        onAdd: { pickViaOpenPanelForVolume(source) },
                        onDismiss: { engine.dismissSuggestion(source) }
                    )
                }
            }

            if engine.sources.isEmpty {
                DropZone(
                    icon: "questionmark.folder",
                    title: engine.l10n.sourcesEmptyTitle,
                    subtitle: engine.l10n.sourcesEmptySubtitle,
                    buttonTitle: engine.l10n.buttonChoose,
                    onPick: pickSource,
                    onDrop: { url in engine.addSource(url) }
                )
            } else {
                ForEach(engine.sources) { source in
                    SourceRow(
                        source: source,
                        cameraTag: Binding(
                            get: {
                                engine.sources.first(where: { $0.id == source.id })?.cameraTag ?? .a
                            },
                            set: { newTag in
                                guard let idx = engine.sources.firstIndex(where: { $0.id == source.id })
                                else { return }
                                engine.sources[idx].cameraTag = newTag
                            }
                        ),
                        showCameraTag: engine.ditMode,
                        cameraTagLabel: engine.l10n.ditCameraTagLabel
                    ) {
                        engine.removeSource(source)
                    }
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.94).combined(with: .opacity).combined(with: .move(edge: .leading)),
                        removal: .scale(scale: 0.92).combined(with: .opacity).combined(with: .move(edge: .leading))
                    ))
                }
                DropZone(
                    icon: "plus.rectangle.on.folder",
                    title: engine.l10n.sourceAddTitle,
                    subtitle: engine.l10n.destAddSubtitle,
                    buttonTitle: engine.l10n.buttonChoose,
                    onPick: pickSource,
                    onDrop: { url in engine.addSource(url) }
                )
                .opacity(0.85)
            }
        }
        .animation(.spring(response: 0.42, dampingFraction: 0.78), value: engine.sources.map(\.id))
    }

    private func pickSource() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.prompt = engine.l10n.panelSelect
        if panel.runModal() == .OK {
            for url in panel.urls { engine.addSource(url) }
        }
    }

    /// For auto-detected removable volumes, the URL returned by
    /// NSWorkspace doesn't carry a sandbox extension. Re-opening it
    /// through NSOpenPanel (pre-pointed at the volume) gets the user
    /// to grant explicit access via the system file dialog.
    private func pickViaOpenPanelForVolume(_ suggested: Source) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = suggested.url
        panel.prompt = engine.l10n.panelSelect
        panel.title = engine.l10n.cardDetected(suggested.displayName)
        if panel.runModal() == .OK, let url = panel.url {
            engine.addSource(url)
            engine.dismissSuggestion(suggested)
        }
    }
}

private struct SourceRow: View {
    let source: Source
    @Binding var cameraTag: CameraTag
    let showCameraTag: Bool
    let cameraTagLabel: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName(for: source))
                .font(.system(size: 16))
                .foregroundStyle(source.isEjectable ? .cyan : .blue)
            VStack(alignment: .leading, spacing: 1) {
                Text(source.displayName)
                    .font(Theme.Typography.cardTitle())
                Text(source.path)
                    .font(Theme.Typography.cardSubtitle())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer(minLength: 0)
            if showCameraTag {
                Picker(cameraTagLabel, selection: $cameraTag) {
                    ForEach(CameraTag.allCases, id: \.self) { tag in
                        Text(tag.shortLabel).tag(tag)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .controlSize(.small)
                .frame(width: 70)
            }
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Theme.Metrics.cardPaddingH)
        .padding(.vertical, 10)
        .cardStyle()
    }

    private func iconName(for source: Source) -> String {
        if source.isRemovableMedia { return "sdcard.fill" }
        if source.isEjectable { return "externaldrive.fill" }
        return "folder.fill"
    }
}

private struct ResumeBanner: View {
    let title: String
    let subtitle: String
    let resumeLabel: String
    let dismissLabel: String
    let onResume: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.clockwise.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(.indigo)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(Theme.Typography.cardTitle())
                Text(subtitle)
                    .font(Theme.Typography.cardSubtitle())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer(minLength: 0)
            Button(resumeLabel, action: onResume)
                .controlSize(.small)
                .buttonStyle(.borderedProminent)
            Button(dismissLabel, action: onDismiss)
                .controlSize(.small)
                .buttonStyle(.bordered)
        }
        .padding(.horizontal, Theme.Metrics.cardPaddingH)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: Theme.Metrics.cardRadius, style: .continuous)
                .fill(Color.indigo.opacity(0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Metrics.cardRadius, style: .continuous)
                .stroke(Color.indigo.opacity(0.35), lineWidth: 1)
        )
    }
}

private struct SuggestedSourceRow: View {
    let source: Source
    let title: String
    let addLabel: String
    var reverifyLabel: String? = nil
    let dismissLabel: String
    let onAdd: () -> Void
    var onReverify: (() -> Void)? = nil
    let onDismiss: () -> Void

    /// Known cards ("already offloaded") show teal + clock; fresh cards
    /// keep the cyan sdcard look.
    private var isKnownCard: Bool { source.previousOffload != nil }
    private var tint: Color { isKnownCard ? .teal : .cyan }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isKnownCard ? "clock.arrow.circlepath" : "sdcard")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(Theme.Typography.cardTitle())
                Text(source.path)
                    .font(Theme.Typography.cardSubtitle())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer(minLength: 0)
            if let reverifyLabel, let onReverify {
                // Known card: re-verifying is the safe default action.
                Button(reverifyLabel, action: onReverify)
                    .controlSize(.small)
                    .buttonStyle(.borderedProminent)
                    .tint(.teal)
                Button(addLabel, action: onAdd)
                    .controlSize(.small)
                    .buttonStyle(.bordered)
            } else {
                Button(addLabel, action: onAdd)
                    .controlSize(.small)
                    .buttonStyle(.borderedProminent)
            }
            Button(dismissLabel, action: onDismiss)
                .controlSize(.small)
                .buttonStyle(.bordered)
        }
        .padding(.horizontal, Theme.Metrics.cardPaddingH)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: Theme.Metrics.cardRadius, style: .continuous)
                .fill(tint.opacity(0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Metrics.cardRadius, style: .continuous)
                .stroke(tint.opacity(0.35), lineWidth: 1)
        )
    }
}
