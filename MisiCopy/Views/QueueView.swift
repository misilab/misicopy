//
//  QueueView.swift
//  MisiCopy
//
//  Compact list of pending copy jobs that the engine will run after the
//  current one finishes.
//

import SwiftUI

struct QueueView: View {
    @Bindable var engine: CopyEngine

    var body: some View {
        if !engine.queue.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    SectionHeader(
                        icon: "list.bullet.indent",
                        title: "\(engine.l10n.sectionQueue) (\(engine.queue.count))"
                    )
                    Spacer()
                    Button(engine.l10n.buttonClearQueue) {
                        engine.clearQueue()
                    }
                    .font(.system(size: 11))
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 4)
                }
                VStack(spacing: 4) {
                    ForEach(Array(engine.queue.enumerated()), id: \.element.id) { index, job in
                        QueueRow(
                            job: job,
                            canMoveUp: index > 0,
                            canMoveDown: index < engine.queue.count - 1,
                            onMoveUp: { engine.moveQueueJob(job.id, up: true) },
                            onMoveDown: { engine.moveQueueJob(job.id, up: false) },
                            onRemove: { engine.removeFromQueue(job.id) }
                        )
                    }
                }
            }
        }
    }
}

private struct QueueRow: View {
    let job: CopyJob
    let canMoveUp: Bool
    let canMoveDown: Bool
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 13))
                .foregroundStyle(Color.indigo)
            VStack(alignment: .leading, spacing: 0) {
                Text(job.summary)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(jobDetail)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Button(action: onMoveUp) {
                Image(systemName: "arrow.up.circle")
                    .foregroundStyle(canMoveUp ? Color.indigo : Color.secondary.opacity(0.35))
            }
            .buttonStyle(.plain)
            .disabled(!canMoveUp)
            Button(action: onMoveDown) {
                Image(systemName: "arrow.down.circle")
                    .foregroundStyle(canMoveDown ? Color.indigo : Color.secondary.opacity(0.35))
            }
            .buttonStyle(.plain)
            .disabled(!canMoveDown)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.indigo.opacity(0.07))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.indigo.opacity(0.20), lineWidth: 1)
        )
    }

    private var jobDetail: String {
        "\(job.mode.rawValue.prefix(1).uppercased())\(job.mode.rawValue.dropFirst()) · \(job.algorithm.displayName)"
    }
}
