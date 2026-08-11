//
//  HTMLExporter.swift
//  MisiCopy
//
//  Self-contained HTML report (no external CSS/JS) suitable for opening
//  in any browser. Mirrors the PDF layout in a web-friendly form.
//

import Foundation

enum HTMLExporter {

    nonisolated static func makeHTML(
        source: URL?,
        destinations: [Destination],
        files: [FileItem],
        stats: CopyStats,
        mode: CopyMode,
        algorithm: ChecksumAlgorithm,
        startDate: Date,
        endDate: Date,
        l10n: Localization
    ) -> String {
        let bytesFmt = ByteCountFormatter()
        bytesFmt.countStyle = .file
        let dateFmt = DateFormatter()
        dateFmt.dateStyle = .long
        dateFmt.timeStyle = .short

        let durationFmt = DateComponentsFormatter()
        durationFmt.allowedUnits = [.hour, .minute, .second]
        durationFmt.unitsStyle = .abbreviated
        let duration = durationFmt.string(from: startDate, to: endDate) ?? "—"

        var html = """
        <!DOCTYPE html>
        <html lang="fr">
        <head>
        <meta charset="UTF-8">
        <title>MisiCopy Report — \(dateFmt.string(from: endDate))</title>
        <style>
        :root { color-scheme: light dark; }
        body { font-family: -apple-system, "SF Pro", system-ui, sans-serif; margin: 0; padding: 32px; background: #f4f5f7; color: #1a1a1a; }
        @media (prefers-color-scheme: dark) { body { background: #1a1a1c; color: #eee; } .card { background: #2a2a2d; } th { background: #333; } }
        .container { max-width: 1100px; margin: 0 auto; }
        header { display: flex; align-items: center; gap: 14px; margin-bottom: 28px; }
        .logo { width: 56px; height: 56px; border-radius: 12px; background: linear-gradient(135deg, #34ebff, #3b82f6, #4747f5); display: grid; place-items: center; color: white; font-size: 24px; }
        h1 { font-size: 28px; margin: 0; }
        h1 + p { margin: 0; color: #666; }
        .card { background: white; border-radius: 12px; padding: 18px 22px; margin-bottom: 16px; box-shadow: 0 1px 3px rgba(0,0,0,0.04); }
        .meta { display: grid; grid-template-columns: 1fr 1fr; gap: 10px 24px; }
        .meta div span { display: block; font-size: 10px; color: #888; text-transform: uppercase; font-weight: 600; letter-spacing: 0.5px; }
        .stats { display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px; margin-bottom: 16px; }
        .stat { background: white; border-radius: 10px; padding: 14px; text-align: center; box-shadow: 0 1px 3px rgba(0,0,0,0.04); }
        .stat .label { font-size: 10px; text-transform: uppercase; font-weight: 600; letter-spacing: 0.4px; margin-bottom: 6px; }
        .stat .value { font-size: 30px; font-weight: 700; font-variant-numeric: tabular-nums; }
        .stat.found .label, .stat.found .value { color: #2563eb; }
        .stat.copied .label, .stat.copied .value { color: #6366f1; }
        .stat.verified .label, .stat.verified .value { color: #16a34a; }
        .stat.failed .label, .stat.failed .value { color: #ea580c; }
        table { width: 100%; border-collapse: collapse; }
        th { text-align: left; background: #f0f0f2; padding: 8px 12px; font-size: 10px; text-transform: uppercase; letter-spacing: 0.4px; color: #666; }
        td { padding: 6px 12px; font-size: 12px; border-bottom: 1px solid #eee; font-variant-numeric: tabular-nums; }
        tr:hover td { background: rgba(0,0,0,0.02); }
        .badge { display: inline-block; padding: 2px 6px; border-radius: 4px; font-size: 9px; font-weight: 700; background: rgba(59, 130, 246, 0.15); color: #2563eb; }
        .ok { color: #16a34a; font-weight: 600; }
        .err { color: #dc2626; font-weight: 600; }
        .checksum { font-family: ui-monospace, "SF Mono", Menlo, monospace; font-size: 11px; color: #555; }
        footer { text-align: center; margin-top: 32px; font-size: 11px; color: #888; }
        footer a { color: #3b82f6; text-decoration: none; }
        </style>
        </head>
        <body>
        <div class="container">
        <header>
          <div class="logo">📦</div>
          <div>
            <h1>MisiCopy</h1>
            <p>\(esc(l10n.headerSubtitle))</p>
          </div>
          <div style="margin-left:auto; text-align:right; color:#888; font-size:12px;">
            \(esc(dateFmt.string(from: endDate)))<br>
            <a href="https://www.misicopy.com">www.misicopy.com</a>
          </div>
        </header>

        <div class="card">
          <div class="meta">
            <div><span>\(esc(l10n.sectionSource))</span>\(esc(source?.path(percentEncoded: false) ?? "—"))</div>
            <div><span>\(esc(l10n.sectionDestinations))</span>\(destinations.map { esc($0.path) }.joined(separator: "<br>"))</div>
            <div><span>\(esc(l10n.sectionMode))</span>\(esc(l10n.modeTitle(mode)))</div>
            <div><span>VERIFICATION</span>\(esc(l10n.modeVerificationDetail(mode)))</div>
            <div><span>\(esc(l10n.labelAlgorithm))</span>\(esc(algorithm.displayName))</div>
            <div><span>DURATION</span>\(esc(duration))</div>
            <div><span>TOTAL</span>\(stats.found) — \(esc(bytesFmt.string(fromByteCount: stats.totalBytes)))</div>
          </div>
        </div>

        <div class="stats">
          <div class="stat found"><div class="label">\(esc(l10n.statFound))</div><div class="value">\(stats.found)</div></div>
          <div class="stat copied"><div class="label">\(esc(l10n.statCopied))</div><div class="value">\(stats.copied)</div></div>
          <div class="stat verified"><div class="label">\(esc(l10n.statVerified))</div><div class="value">\(stats.verified)</div></div>
          <div class="stat failed"><div class="label">\(esc(l10n.statFailed))</div><div class="value">\(stats.failed)</div></div>
        </div>

        <div class="card">
          <h2 style="margin-top:0; font-size:14px;">\(esc(l10n.sectionJournal))</h2>
          <table>
            <thead><tr><th>Fichier</th><th>Format</th><th>Taille</th><th>Checksum</th><th>Statut</th></tr></thead>
            <tbody>
        """

        for file in files {
            let ok: String
            let cls: String
            switch file.status {
            case .verified: ok = esc(l10n.statVerified); cls = "ok"
            case .copied:   ok = esc(l10n.statCopied);   cls = "ok"
            case .failed(let r): ok = "✗ " + esc(r);    cls = "err"
            default:        ok = "—";                    cls = ""
            }
            let badge = file.cameraFormat.shortBadge.isEmpty
                ? ""
                : "<span class=\"badge\">\(esc(file.cameraFormat.shortBadge))</span>"
            html += """
                <tr>
                  <td>\(esc(file.relativePath))</td>
                  <td>\(badge)</td>
                  <td>\(esc(bytesFmt.string(fromByteCount: file.size)))</td>
                  <td class="checksum">\(esc(short(file.sourceChecksum)))</td>
                  <td class="\(cls)">\(ok)</td>
                </tr>
            """
        }

        html += """
            </tbody>
          </table>
        </div>

        <footer>\(esc(l10n.footerCredit)) — <a href="https://www.misicopy.com">www.misicopy.com</a></footer>
        </div>
        </body>
        </html>
        """
        return html
    }

    private static func esc(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }

    private static func short(_ s: String?) -> String {
        guard let s, !s.isEmpty else { return "—" }
        if s.count <= 16 { return s }
        return String(s.prefix(8)) + "…" + String(s.suffix(8))
    }
}
