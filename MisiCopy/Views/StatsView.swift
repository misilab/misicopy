//
//  StatsView.swift
//  MisiCopy
//

import SwiftUI

struct StatsView: View {
    @Bindable var engine: CopyEngine

    var body: some View {
        HStack(spacing: 10) {
            StatCard(icon: "magnifyingglass", label: engine.l10n.statFound,
                     value: "\(engine.stats.found)", accent: Theme.Palette.statFound)
            StatCard(icon: "doc.on.doc", label: engine.l10n.statCopied,
                     value: "\(engine.stats.copied)", accent: Theme.Palette.statCopied)
            StatCard(icon: "checkmark.shield", label: engine.l10n.statVerified,
                     value: "\(engine.stats.verified)", accent: Theme.Palette.statVerified)
            StatCard(icon: "exclamationmark.triangle", label: engine.l10n.statFailed,
                     value: "\(engine.stats.failed)", accent: Theme.Palette.statFailed)
        }
    }
}
