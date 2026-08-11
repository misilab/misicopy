//
//  HistoryView.swift
//  MisiCopy
//
//  Sheet listing past copy sessions with stats, duration and the option
//  to remove single entries or clear all.
//

import SwiftUI

struct HistoryView: View {
    @Bindable var engine: CopyEngine
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(engine.l10n.menuHistory).font(.headline)
                Spacer()
                Button(engine.l10n.buttonClearHistory) {
                    engine.history.clear()
                }
                .controlSize(.small)
                .disabled(engine.history.records.isEmpty)
            }

            if engine.history.records.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.system(size: 28))
                        .foregroundStyle(.secondary)
                    Text(engine.l10n.historyEmpty)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 240)
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(engine.history.records) { record in
                            HistoryRow(record: record,
                                       l10n: engine.l10n,
                                       onRemove: { engine.history.remove(record.id) })
                        }
                    }
                }
                .frame(width: 560, height: 360)
            }

            HStack {
                Spacer()
                Button(engine.l10n.buttonClose, action: onClose)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 620)
    }
}

private struct HistoryRow: View {
    let record: SessionRecord
    let l10n: Localization
    let onRemove: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: record.didSucceed ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(record.didSucceed ? .green : .red)
                .font(.system(size: 14))
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 1) {
                Text("\(record.sourceSummary) → \(record.destinationSummary)")
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                    .truncationMode(.middle)
                HStack(spacing: 8) {
                    Text(dateString)
                    Text("·")
                    Text("\(record.copied)/\(record.found) \(l10n.statCopied.lowercased())")
                    Text("·")
                    Text(formatBytes(record.totalBytes))
                    Text("·")
                    Text(formatDuration(record.duration))
                    Text("·")
                    Text(l10n.modeTitle(record.mode))
                }
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.04))
        )
    }

    private var dateString: String {
        l10n.formatShortDateTime(record.startDate)
    }

    private func formatBytes(_ b: Int64) -> String {
        let f = ByteCountFormatter(); f.countStyle = .file
        return f.string(fromByteCount: b)
    }

    private func formatDuration(_ d: TimeInterval) -> String {
        let total = Int(d.rounded())
        let h = total / 3600, m = (total % 3600) / 60, s = total % 60
        return h > 0 ? String(format: "%dh%02dm", h, m) :
               m > 0 ? String(format: "%dm%02ds", m, s) :
                       String(format: "%ds", s)
    }
}
