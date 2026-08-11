//
//  FooterView.swift
//  MisiCopy
//

import SwiftUI
import AppKit

struct FooterView: View {
    @Bindable var engine: CopyEngine

    var body: some View {
        ZStack {
            HStack(spacing: 4) {
                Text(engine.l10n.footerCredit)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Text("—")
                    .foregroundStyle(.secondary)
                Link("www.misicopy.com", destination: URL(string: "https://www.misicopy.com")!)
                    .font(.system(size: 11))
            }
            .frame(maxWidth: .infinity, alignment: .center)

            HStack {
                Spacer()
                bugReportButton
                    .padding(.trailing, 12)
            }
        }
        .padding(.top, 6)
    }

    private var bugReportButton: some View {
        Button {
            NSWorkspace.shared.open(bugMailURL)
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "ant")
                    .font(.system(size: 12))
                Text(engine.l10n.bugReportButton)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .overlay(
                Capsule().stroke(Color.secondary.opacity(0.35), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .help(engine.l10n.bugReportTooltip)
    }

    private var bugMailURL: URL {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = "misicopy@misiraca.com"
        components.queryItems = [
            URLQueryItem(name: "subject", value: "MisiCopy, il y a un bug !!")
        ]
        return components.url ?? URL(string: "mailto:misicopy@misiraca.com")!
    }
}
