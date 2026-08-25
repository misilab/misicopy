//
//  LicenseSettingsView.swift
//  MisiCopy
//

import SwiftUI
import AppKit

struct LicenseSettingsView: View {
    @Bindable var license: LicenseManager
    let l10n: Localization

    @State private var email: String = ""
    @State private var key: String = ""
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section {
                statusRow
                if case .licensed(let activeEmail) = license.status {
                    Text(activeEmail)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                    Button(l10n.licenseDeactivate, role: .destructive) {
                        license.deactivate()
                    }
                }
            } header: {
                Label(l10n.sectionLicense, systemImage: "key.fill")
            }

            if !license.status.isLicensedCase {
                Section {
                    TextField(l10n.licenseFieldKey, text: $key,
                              prompt: Text("XXXX-XXXX-XXXX-XXXX-XXXX"))
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                    TextField(l10n.emailFieldLabel, text: $email,
                              prompt: Text(l10n.emailFieldHint))
                        .textFieldStyle(.roundedBorder)
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    HStack {
                        Button(l10n.licenseActivate) { activate() }
                            .keyboardShortcut(.defaultAction)
                            .disabled(key.count < 16)
                        Spacer()
                        Button {
                            if let url = URL(string: LicenseConfig.purchaseURL) {
                                NSWorkspace.shared.open(url)
                            }
                        } label: {
                            Label(l10n.licenseBuyAt(LicenseConfig.priceLabel), systemImage: "cart.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                    }
                } header: {
                    Label(l10n.licenseFieldKey, systemImage: "key.fill")
                } footer: {
                    Text(l10n.licenseTwoMachineHint)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .onAppear { license.refreshStatus() }
    }

    @ViewBuilder
    private var statusRow: some View {
        switch license.status {
        case .trial(let days, let transfers):
            row(icon: "clock.fill", color: .orange,
                title: l10n.licenseStateTrial,
                subtitle: l10n.licenseTrialRemaining(days: days, transfers: transfers))
        case .licensed:
            row(icon: "checkmark.seal.fill", color: .green,
                title: l10n.licenseStateActive,
                subtitle: nil)
        case .expired:
            row(icon: "xmark.circle.fill", color: .red,
                title: l10n.licenseStateExpired,
                subtitle: l10n.logLicenseExpired)
        }
    }

    private func row(icon: String, color: Color, title: String, subtitle: String?) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.system(size: 13, weight: .semibold))
                if let subtitle {
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
    }

    private func activate() {
        errorMessage = nil
        if license.activate(email: email, key: key) {
            email = ""
            key = ""
        } else {
            errorMessage = l10n.licenseInvalid
        }
    }
}

private extension LicenseStatus {
    var isLicensedCase: Bool {
        if case .licensed = self { return true }
        return false
    }
}
