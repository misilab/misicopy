//
//  SettingsView.swift
//  MisiCopy
//
//  Application preferences (⌘,). Persists via @AppStorage so the
//  values survive relaunches and are independent of the active copy job.
//

import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var appModel
    @AppStorage("showStatusItem") private var showStatusItem: Bool = false

    var body: some View {
        let l = appModel.engine.l10n
        TabView {
            general
                .tabItem { Label(l.settingsTabGeneral, systemImage: "gear") }
            license
                .tabItem { Label(l.sectionLicense, systemImage: "key.fill") }
            renaming
                .tabItem { Label(l.settingsTabRenaming, systemImage: "character.cursor.ibeam") }
            dit
                .tabItem { Label(l.settingsTabDIT, systemImage: "folder.badge.gearshape") }
            filters
                .tabItem { Label(l.settingsTabFilters, systemImage: "line.3.horizontal.decrease.circle") }
            watch
                .tabItem { Label(l.settingsTabWatch, systemImage: "eye") }
            integrations
                .tabItem { Label(l.settingsTabIntegrations, systemImage: "link") }
            remoteSync
                .tabItem { Label(l.settingsTabRemote, systemImage: "iphone.gen2.radiowaves.left.and.right") }
            advanced
                .tabItem { Label(l.settingsTabAdvanced, systemImage: "wrench.and.screwdriver") }
        }
        .frame(width: 780, height: 640)
    }

    private var remoteSync: some View {
        RemoteSyncSettingsView(service: appModel.remoteSync, l10n: appModel.engine.l10n)
    }

    private var license: some View {
        LicenseSettingsView(license: appModel.license, l10n: appModel.engine.l10n)
    }

    private var watch: some View {
        @Bindable var engine = appModel.engine
        let l = engine.l10n
        return Form {
            Section {
                Toggle(l.settingsWatchAutoAdd, isOn: $engine.watchAutoAddSource)
                Toggle(l.settingsWatchAutoStart, isOn: $engine.watchAutoStart)
                    .disabled(!engine.watchAutoAddSource)
            } header: {
                Label(l.settingsWatchSectionTitle, systemImage: "eye")
            } footer: {
                Text(l.settingsWatchFooter)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    private var integrations: some View {
        @Bindable var engine = appModel.engine
        let l = engine.l10n
        return Form {
            Section {
                TextField(l.settingsIntegrationsSlackPlaceholder, text: $engine.slackWebhookURL,
                          prompt: Text("https://hooks.slack.com/services/…"))
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
            } header: {
                Label(l.settingsIntegrationsSlackHeader, systemImage: "bubble.left.and.bubble.right")
            } footer: {
                Text(l.settingsIntegrationsSlackFooter)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                TextField(l.settingsIntegrationsWebhookPlaceholder, text: $engine.genericWebhookURL,
                          prompt: Text(l.settingsIntegrationsWebhookExample))
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
            } header: {
                Label(l.settingsIntegrationsWebhookHeader, systemImage: "globe")
            } footer: {
                Text(l.settingsIntegrationsWebhookFooter)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

        }
        .formStyle(.grouped)
    }

    private var advanced: some View {
        @Bindable var engine = appModel.engine
        let l = engine.l10n
        return Form {
            Section(l.settingsAdvancedFinderSection) {
                Toggle(l.settingsAdvancedFinderToggle, isOn: $engine.preserveFinderTags)
            }
            Section(l.settingsAdvancedSymlinksSection) {
                Toggle(l.settingsAdvancedSymlinksToggle, isOn: $engine.followSymbolicLinks)
            }
            Section {
                Toggle(l.settingsParallelToggle, isOn: $engine.parallelSourceCopies)
            } header: {
                Label(l.settingsParallelSection, systemImage: "square.stack.3d.down.right")
            } footer: {
                Text(l.settingsParallelFooter)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    private var filters: some View {
        @Bindable var engine = appModel.engine
        let l = engine.l10n
        return Form {
            Section {
                TextField(l.settingsFiltersIncludePlaceholder, text: $engine.extensionWhitelist,
                          prompt: Text("mxf, mov, wav, r3d, braw"))
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                Text(.init(l.settingsFiltersIncludeFooter))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Label(l.settingsFiltersIncludeHeader, systemImage: "checkmark.circle")
            }

            Section {
                TextField(l.settingsFiltersExcludePlaceholder, text: $engine.extensionBlacklist,
                          prompt: Text("xmp, log, thm, txt"))
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                Text(.init(l.settingsFiltersExcludeFooter))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Label(l.settingsFiltersExcludeHeader, systemImage: "xmark.circle")
            }

            Section {
                Text(l.settingsFiltersSeparatorHint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    private var general: some View {
        @Bindable var engine = appModel.engine
        let l = engine.l10n
        return Form {
            Section(l.settingsGeneralSection) {
                Toggle(isOn: $showStatusItem) {
                    Label(l.settingsGeneralStatusItem,
                          systemImage: "menubar.rectangle")
                }
                .onChange(of: showStatusItem) { _, newValue in
                    StatusItemController.shared.setEnabled(newValue)
                }
                Toggle(isOn: $engine.completionDialogEnabled) {
                    Label(l.settingsCompletionDialogToggle,
                          systemImage: "checkmark.bubble")
                }
            }
            Section {
                Picker(l.labelAlgorithm, selection: $engine.algorithm) {
                    ForEach(ChecksumAlgorithm.allCases) { algo in
                        Text(algo.displayName).tag(algo)
                    }
                }
                .pickerStyle(.menu)
            } header: {
                Label(l.settingsAlgorithmSection, systemImage: "number.square")
            } footer: {
                Text(l.settingsAlgorithmFooter)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    private var dit: some View {
        @Bindable var engine = appModel.engine
        let l = engine.l10n
        return Form {
            Section {
                TextField(l.settingsDITLabelInfos, text: $engine.ditFolderInfos,
                          prompt: Text(CopyEngine.defaultDITFolderInfos))
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                TextField(l.settingsDITLabelRushes, text: $engine.ditFolderRushes,
                          prompt: Text(CopyEngine.defaultDITFolderRushes))
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                TextField(l.settingsDITLabelMHL, text: $engine.ditFolderMHL,
                          prompt: Text(CopyEngine.defaultDITFolderMHL))
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                TextField(l.settingsDITLabelProxy, text: $engine.ditFolderProxy,
                          prompt: Text(CopyEngine.defaultDITFolderProxy))
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                TextField(l.settingsDITLabelLUT, text: $engine.ditFolderLUT,
                          prompt: Text(CopyEngine.defaultDITFolderLUT))
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
            } header: {
                Label(l.settingsDITFoldersHeader, systemImage: "folder.fill")
            } footer: {
                Text(l.settingsDITFoldersFooter)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                TextField(l.settingsDITReportPrefix, text: $engine.ditReportPrefix,
                          prompt: Text(CopyEngine.defaultDITReportPrefix))
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                Text(l.settingsDITReportPreview(prefix: prefixPreview, date: datePreview))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            } header: {
                Label(l.settingsDITReportHeader, systemImage: "doc.text.fill")
            }

            Section {
                ForEach(engine.ditExtraFolders.indices, id: \.self) { idx in
                    HStack {
                        TextField(l.settingsDITExtraPlaceholder,
                                  text: $engine.ditExtraFolders[idx],
                                  prompt: Text("05_EDIT, 06_DELIVERABLES, …"))
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                        Button {
                            engine.ditExtraFolders.remove(at: idx)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }
                Button {
                    engine.ditExtraFolders.append("")
                } label: {
                    Label(l.settingsDITAddFolder, systemImage: "plus.circle")
                }
            } header: {
                Label(l.settingsDITExtraHeader, systemImage: "folder.badge.plus")
            } footer: {
                Text(l.settingsDITExtraFooter)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button(l.settingsDITReset) {
                    engine.ditFolderInfos = CopyEngine.defaultDITFolderInfos
                    engine.ditFolderRushes = CopyEngine.defaultDITFolderRushes
                    engine.ditFolderMHL = CopyEngine.defaultDITFolderMHL
                    engine.ditFolderProxy = CopyEngine.defaultDITFolderProxy
                    engine.ditFolderLUT = CopyEngine.defaultDITFolderLUT
                    engine.ditReportPrefix = CopyEngine.defaultDITReportPrefix
                    engine.ditExtraFolders = []
                    engine.saveDITSettings()
                }
            }
        }
        .formStyle(.grouped)
        .onChange(of: engine.ditFolderInfos) { _, _ in engine.saveDITSettings() }
        .onChange(of: engine.ditFolderRushes) { _, _ in engine.saveDITSettings() }
        .onChange(of: engine.ditFolderMHL) { _, _ in engine.saveDITSettings() }
        .onChange(of: engine.ditFolderProxy) { _, _ in engine.saveDITSettings() }
        .onChange(of: engine.ditFolderLUT) { _, _ in engine.saveDITSettings() }
        .onChange(of: engine.ditReportPrefix) { _, _ in engine.saveDITSettings() }
        .onChange(of: engine.ditExtraFolders) { _, _ in engine.saveDITSettings() }
    }

    private var prefixPreview: String {
        let raw = appModel.engine.ditReportPrefix.trimmingCharacters(in: .whitespaces)
        return raw.isEmpty ? CopyEngine.defaultDITReportPrefix : raw
    }

    private var datePreview: String {
        let fmt = DateFormatter(); fmt.dateFormat = "ddMMyy"
        return fmt.string(from: Date())
    }

    private var renaming: some View {
        @Bindable var engine = appModel.engine
        let l = engine.l10n
        return Form {
            Section(l.settingsRenamingSection) {
                TextField(l.settingsRenamingTemplate, text: $engine.renamingTemplate,
                          prompt: Text("{source}_{counter:04}.{ext}"))
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))

                if !engine.renamingTemplate.isEmpty {
                    HStack {
                        Text(l.settingsRenamingPreview)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(preview(template: engine.renamingTemplate))
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.primary)
                    }
                }

                Button(l.settingsRenamingClear) {
                    engine.renamingTemplate = ""
                }
                .disabled(engine.renamingTemplate.isEmpty)
            }

            Section(l.settingsRenamingTokensSection) {
                tokenRow("{filename}",   l.settingsRenamingTokenFilename)
                tokenRow("{ext}",        l.settingsRenamingTokenExt)
                tokenRow("{source}",     l.settingsRenamingTokenSource)
                tokenRow("{camera}",     l.settingsRenamingTokenCamera)
                tokenRow("{date}",       l.settingsRenamingTokenDate)
                tokenRow("{time}",       l.settingsRenamingTokenTime)
                tokenRow("{counter}",    l.settingsRenamingTokenCounter)
                tokenRow("{counter:04}", l.settingsRenamingTokenCounterPadded)
            }
        }
        .formStyle(.grouped)
    }

    private func tokenRow(_ token: String, _ description: String) -> some View {
        HStack(spacing: 12) {
            Text(token)
                .font(.system(.caption, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.accentColor.opacity(0.15))
                )
                .frame(width: 110, alignment: .leading)
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    private func preview(template: String) -> String {
        let now = Date()
        let dummyURL = URL(fileURLWithPath: "/Volumes/A001_C001/CLIP_0001.MXF")
        let dummyRoot = URL(fileURLWithPath: "/Volumes/A001_C001")
        var item = FileItem(sourceRoot: dummyRoot,
                            sourceURL: dummyURL,
                            relativePath: "CLIP_0001.MXF",
                            size: 0)
        item.cameraFormat = .arri
        return FilenameTemplate(raw: template).apply(to: item, counter: 1, sessionStart: now)
    }
}
