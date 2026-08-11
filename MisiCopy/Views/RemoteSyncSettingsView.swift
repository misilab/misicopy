//
//  RemoteSyncSettingsView.swift
//  MisiCopy
//
//  Settings tab for the iPhone Remote feature. Lets the user enable the
//  local Wi-Fi server, see who's connected and rotate the pairing secret.
//  The actual QR pairing UI lands in a future session.
//

import SwiftUI
import AppKit

struct RemoteSyncSettingsView: View {
    @Bindable var service: RemoteSyncService
    let l10n: Localization

    var body: some View {
        Form {
            Section {
                Toggle(l10n.remoteToggleEnable, isOn: $service.isEnabled)
                if service.isEnabled {
                    compactStatusRow
                }
            } header: {
                Label(l10n.remoteSectionLocal, systemImage: "wifi")
            } footer: {
                Text(l10n.remoteToggleFooter)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if service.isEnabled {
                Section {
                    HStack(alignment: .top, spacing: 20) {
                        pairingColumn
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Divider()
                        secretColumn
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .formStyle(.grouped)
    }

    @ViewBuilder
    private var compactStatusRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 18) {
                statusBadge
                if let port = service.listeningPort {
                    statusChip(icon: "network",
                               label: l10n.remotePortLabel,
                               value: String(port))
                }
                statusChip(icon: "iphone.gen2",
                           label: l10n.remoteClientsLabel,
                           value: "\(service.connectedClientsCount)")
                Spacer(minLength: 0)
            }
            cloudStatusRow
        }
        .padding(.top, 4)
    }

    /// Surface the CloudKit publisher's live state so the user can see
    /// when the iPhone-via-iCloud path is broken (schema not deployed to
    /// Production, iCloud signed out, network down, …). Without this the
    /// failure was completely silent.
    @ViewBuilder
    private var cloudStatusRow: some View {
        HStack(spacing: 6) {
            Image(systemName: cloudIcon)
                .foregroundStyle(cloudColor)
            Text("iCloud").font(.system(size: 13, weight: .semibold))
            Text("·").foregroundStyle(.secondary)
            Text(cloudText)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    private var cloudIcon: String {
        switch service.cloudStatus {
        case .idle: return "icloud.slash"
        case .ready: return "icloud"
        case .publishing: return "icloud.and.arrow.up"
        case .unavailable: return "exclamationmark.icloud"
        }
    }

    private var cloudColor: Color {
        switch service.cloudStatus {
        case .idle: return .secondary
        case .ready: return .green
        case .publishing: return .blue
        case .unavailable: return .red
        }
    }

    private var cloudText: String {
        switch service.cloudStatus {
        case .idle:
            return l10n.cloudStatusWaitingFirstUpload
        case .ready:
            if let d = service.cloudLastUploadAt {
                let f = RelativeDateTimeFormatter(); f.unitsStyle = .short
                return l10n.cloudStatusSyncedRelative(f.localizedString(for: d, relativeTo: Date()))
            }
            return l10n.cloudStatusReady
        case .publishing:
            return l10n.cloudStatusPublishing
        case .unavailable(let reason):
            switch reason {
            case .noAccount: return l10n.cloudReasonNoAccount
            case .restricted: return l10n.cloudReasonRestricted
            case .undetermined: return l10n.cloudReasonUndetermined
            case .temporarilyUnavailable: return l10n.cloudReasonTempUnavailable
            case .unknown: return l10n.cloudReasonUnknown
            case .other(let msg): return msg
            }
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        if service.listeningPort != nil {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                Text(l10n.remoteStatusListening).font(.system(size: 14, weight: .semibold))
            }
        } else {
            HStack(spacing: 6) {
                Image(systemName: "hourglass").foregroundStyle(.cyan)
                Text(l10n.remoteStatusStarting).font(.system(size: 14, weight: .semibold))
            }
        }
    }

    private func statusChip(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).foregroundStyle(.secondary)
            Text(label).font(.system(size: 13)).foregroundStyle(.secondary)
            Text(value).font(.system(size: 14, design: .monospaced))
        }
    }

    @ViewBuilder
    private var pairingColumn: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(l10n.remoteSectionPairing, systemImage: "qrcode")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
            pairingQRRow
            Text(l10n.remotePairingFooter)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var secretColumn: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(l10n.remoteSectionSecret, systemImage: "key.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
            secretRow
            Button(l10n.remoteRegenerateSecret, role: .destructive) {
                service.regenerateSecret()
            }
            .controlSize(.regular)
            Text(l10n.remoteSecretFooter)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var pairingQRRow: some View {
        if let qr = qrImage {
            VStack(spacing: 6) {
                Image(nsImage: qr)
                    .interpolation(.none)
                    .resizable()
                    .frame(width: 180, height: 180)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.25), lineWidth: 0.5)
                    )
                Text(service.displayHostname)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                Button {
                    copyPayloadToClipboard()
                } label: {
                    Label(l10n.remoteCopyPayload, systemImage: "doc.on.doc")
                        .font(.system(size: 13))
                }
                .buttonStyle(.borderless)
            }
            .frame(maxWidth: .infinity)
        } else {
            Text(l10n.remotePairingError)
                .font(.caption)
                .foregroundStyle(.red)
        }
    }

    private func copyPayloadToClipboard() {
        guard let json = try? service.pairingPayload().encoded() else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(json, forType: .string)
    }

    private var qrImage: NSImage? {
        guard let json = try? service.pairingPayload().encoded() else { return nil }
        return QRCodeGenerator.image(for: json, side: 200)
    }

    private var secretRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(l10n.remoteSecretLabel)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
            Text(service.sharedSecret)
                .font(.system(size: 12, design: .monospaced))
                .textSelection(.enabled)
                .lineLimit(2)
                .truncationMode(.middle)
        }
    }
}
