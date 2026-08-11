//
//  PDFReportGenerator.swift
//  MisiCopy
//
//  Generates a one-page (or multi-page) PDF report at the root of each
//  destination folder after a successful copy: branded header, copy
//  metadata, stats grid, and a detailed file table.
//

import Foundation
import AppKit
import CoreGraphics

struct PDFReportInput {
    let sourceURL: URL?
    let destination: Destination
    let mode: CopyMode
    let algorithm: ChecksumAlgorithm
    let files: [FileItem]
    let stats: CopyStats
    let startDate: Date
    let endDate: Date
    let l10n: Localization
    let includeThumbnails: Bool
    /// When non-nil, the PDF is written inside this directory instead of
    /// at the destination root (used by the DIT layout to land it in
    /// `<projet>/00_INFOS/`).
    var outputDirectory: URL? = nil
    /// Optional filename override (the DIT layout uses
    /// `rapport_DIT_<JJMMAA>.pdf` instead of the default timestamp name).
    var filenameOverride: String? = nil
}

enum PDFReportGenerator {

    /// Writes a PDF report at `destination/MisiCopy-report-YYYYMMDD-HHmmss.pdf`.
    /// Returns the produced file URL on success.
    @discardableResult
    static func write(_ input: PDFReportInput) -> URL? {
        let filename: String
        if let override = input.filenameOverride {
            filename = override
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd-HHmmss"
            filename = "MisiCopy-report-\(formatter.string(from: input.endDate)).pdf"
        }
        let baseDir = input.outputDirectory ?? input.destination.url
        try? FileManager.default.createDirectory(at: baseDir, withIntermediateDirectories: true)
        let url = baseDir.appending(path: filename)

        let pageSize = CGSize(width: 595.0, height: 842.0) // A4 portrait
        var mediaBox = CGRect(origin: .zero, size: pageSize)
        guard let context = CGContext(url as CFURL, mediaBox: &mediaBox, nil) else {
            return nil
        }

        let renderer = PDFRenderer(context: context, page: mediaBox, input: input)
        renderer.render()
        context.closePDF()
        return url
    }
}

// MARK: - Renderer

private final class PDFRenderer {
    let ctx: CGContext
    let page: CGRect
    let input: PDFReportInput

    let margin: CGFloat = 36
    var cursorY: CGFloat = 0  // measured from top
    let lineGap: CGFloat = 6

    let brand = NSColor(red: 0.30, green: 0.65, blue: 0.95, alpha: 1)
    let textPrimary = NSColor(white: 0.10, alpha: 1)
    let textSecondary = NSColor(white: 0.45, alpha: 1)
    let cardBorder = NSColor(white: 0.85, alpha: 1)
    let cardBackground = NSColor(white: 0.97, alpha: 1)
    let altRow = NSColor(white: 0.96, alpha: 1)

    init(context: CGContext, page: CGRect, input: PDFReportInput) {
        self.ctx = context
        self.page = page
        self.input = input
    }

    func render() {
        beginPage()
        drawHeader()
        drawMetadata()
        drawStatsRow()
        let rows = ClipRow.build(from: input.files)
        if input.includeThumbnails {
            drawThumbnailsGrid(rows: rows)
        }
        drawFilesTable(rows: rows)
        drawFooter()
        ctx.endPDFPage()
    }

    private func drawThumbnailsGrid(rows: [ClipRow]) {
        // Draw thumbnails for clips that either have a recognised camera
        // format OR are image sequences grouped as a single plan.
        let candidates = rows.filter { row in
            row.frameCount > 1 || row.representative.cameraFormat != .unknown
        }
        if candidates.isEmpty { return }

        let cols: Int = 4
        let gridWidth = page.width - margin * 2
        let cellWidth = (gridWidth - CGFloat(cols - 1) * 6) / CGFloat(cols)
        let cellHeight = cellWidth * 9 / 16
        let rowHeight = cellHeight + 14 // cell + filename strip
        let titleHeight: CGFloat = 14

        newPageIfNeeded(titleHeight + rowHeight + 4)
        drawText(labelize("CLIPS"),
                 at: CGPoint(x: margin, y: page.height - cursorY - 9),
                 font: .systemFont(ofSize: 9, weight: .semibold),
                 color: textSecondary)
        cursorY += titleHeight

        for (index, row) in candidates.enumerated() {
            let file = row.representative
            let colIdx = index % cols
            if colIdx == 0 {
                newPageIfNeeded(rowHeight + 4)
            }

            let x = margin + CGFloat(colIdx) * (cellWidth + 6)
            let y = page.height - cursorY - cellHeight

            let rect = CGRect(x: x, y: y, width: cellWidth, height: cellHeight)
            let path = CGPath(roundedRect: rect, cornerWidth: 6, cornerHeight: 6, transform: nil)

            if let thumb = ThumbnailExtractor.thumbnail(for: file.sourceURL, maxDimension: 320) {
                ctx.saveGState()
                ctx.setFillColor(NSColor.black.cgColor)
                ctx.addPath(path); ctx.fillPath()
                ctx.restoreGState()

                ctx.saveGState()
                ctx.addPath(path); ctx.clip()
                ctx.draw(thumb, in: aspectFillRect(image: thumb, target: rect))
                ctx.restoreGState()
            } else {
                drawBrandedPlaceholder(in: rect, file: file)
            }

            // Badge — camera brand for known formats, otherwise the
            // sequence extension + frame count (e.g. "DPX 500").
            let badgeText: String
            if row.frameCount > 1 {
                badgeText = "\((file.sourceURL.pathExtension).uppercased()) \(row.frameCount)"
            } else {
                badgeText = file.cameraFormat.shortBadge
            }
            if !badgeText.isEmpty {
                let badgeWidth: CGFloat = row.frameCount > 1 ? 52 : 38
                let badgeRect = CGRect(x: x + 4, y: y + 4, width: badgeWidth, height: 12)
                ctx.saveGState()
                ctx.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 0.55))
                let bp = CGPath(roundedRect: badgeRect, cornerWidth: 3, cornerHeight: 3, transform: nil)
                ctx.addPath(bp); ctx.fillPath()
                ctx.restoreGState()
                drawTextCentered(badgeText,
                                 in: CGRect(x: badgeRect.minX, y: badgeRect.minY + 1,
                                            width: badgeRect.width, height: 10),
                                 font: .systemFont(ofSize: 7, weight: .bold),
                                 color: .white)
            }

            drawText(row.thumbnailLabel,
                     at: CGPoint(x: x, y: y - 12),
                     font: .systemFont(ofSize: 7, weight: .medium),
                     color: textPrimary,
                     maxWidth: cellWidth)

            if colIdx == cols - 1 || index == candidates.count - 1 {
                cursorY += rowHeight
            }
        }
        cursorY += 4
    }

    private func drawBrandedPlaceholder(in rect: CGRect, file: FileItem) {
        let colors = file.cameraFormat.brandColors
        let path = CGPath(roundedRect: rect, cornerWidth: 6, cornerHeight: 6, transform: nil)

        // Gradient background using brand colors
        ctx.saveGState()
        ctx.addPath(path); ctx.clip()
        let cs = CGColorSpaceCreateDeviceRGB()
        if let gradient = CGGradient(colorsSpace: cs,
                                     colors: [colors.top, colors.bottom] as CFArray,
                                     locations: [0, 1]) {
            ctx.drawLinearGradient(gradient,
                                   start: CGPoint(x: rect.midX, y: rect.maxY),
                                   end: CGPoint(x: rect.midX, y: rect.minY),
                                   options: [])
        }

        // Subtle diagonal sheen
        if let sheen = CGGradient(colorsSpace: cs,
                                  colors: [CGColor(red: 1, green: 1, blue: 1, alpha: 0.12),
                                           CGColor(red: 1, green: 1, blue: 1, alpha: 0)] as CFArray,
                                  locations: [0, 1]) {
            ctx.drawLinearGradient(sheen,
                                   start: CGPoint(x: rect.minX, y: rect.maxY),
                                   end: CGPoint(x: rect.maxX, y: rect.midY),
                                   options: [])
        }
        ctx.restoreGState()

        // Large camera badge / format name in the centre
        let label = file.cameraFormat.shortBadge.isEmpty
            ? (file.displayName as NSString).pathExtension.uppercased()
            : file.cameraFormat.shortBadge
        let labelRect = CGRect(x: rect.minX,
                               y: rect.midY - 8,
                               width: rect.width,
                               height: 18)
        drawTextCentered(label,
                         in: labelRect,
                         font: .systemFont(ofSize: rect.height * 0.22, weight: .heavy),
                         color: NSColor(white: 1, alpha: 0.95))

        // Sub-label: "Aperçu non disponible"
        let subRect = CGRect(x: rect.minX,
                             y: rect.midY - rect.height * 0.18,
                             width: rect.width,
                             height: 10)
        drawTextCentered(input.l10n.pdfPreviewUnavailable,
                         in: subRect,
                         font: .systemFont(ofSize: 7, weight: .medium),
                         color: NSColor(white: 1, alpha: 0.70))
    }

    private func aspectFillRect(image: CGImage, target: CGRect) -> CGRect {
        let iw = CGFloat(image.width), ih = CGFloat(image.height)
        let tr = target.width / target.height
        let ir = iw / ih
        if ir > tr {
            // Image wider than target — crop sides
            let scaledWidth = target.height * ir
            return CGRect(x: target.midX - scaledWidth / 2,
                          y: target.minY,
                          width: scaledWidth, height: target.height)
        } else {
            let scaledHeight = target.width / ir
            return CGRect(x: target.minX,
                          y: target.midY - scaledHeight / 2,
                          width: target.width, height: scaledHeight)
        }
    }

    // MARK: - Page helpers

    private func beginPage() {
        ctx.beginPDFPage(nil)
        // White background
        ctx.setFillColor(NSColor.white.cgColor)
        ctx.fill(page)
        cursorY = margin
    }

    private func newPageIfNeeded(_ needed: CGFloat) {
        if cursorY + needed > page.height - margin - 20 {
            drawFooter()
            ctx.endPDFPage()
            beginPage()
        }
    }

    // MARK: - Header

    private func drawHeader() {
        let badgeSize: CGFloat = 46
        let originY = page.height - margin - badgeSize
        let badge = CGRect(x: margin, y: originY, width: badgeSize, height: badgeSize)

        // Rounded brand square
        ctx.saveGState()
        ctx.setFillColor(brand.cgColor)
        let path = CGPath(roundedRect: badge, cornerWidth: 10, cornerHeight: 10, transform: nil)
        ctx.addPath(path)
        ctx.fillPath()
        ctx.restoreGState()

        // Logo glyph in badge
        drawSymbol("shippingbox.and.arrow.backward.fill",
                   in: badge.insetBy(dx: 10, dy: 10),
                   tint: .white,
                   weight: .semibold)

        // Title block to the right of the badge
        let textX = margin + badgeSize + 12
        drawText("MisiCopy",
                 at: CGPoint(x: textX, y: originY + 22),
                 font: .systemFont(ofSize: 22, weight: .bold),
                 color: textPrimary)
        drawText(input.l10n.headerSubtitle,
                 at: CGPoint(x: textX, y: originY + 4),
                 font: .systemFont(ofSize: 11),
                 color: textSecondary)

        // Date in top-right
        let dateFmt = DateFormatter()
        dateFmt.dateStyle = .long
        dateFmt.timeStyle = .short
        let dateStr = dateFmt.string(from: input.endDate)
        drawTextRightAligned(dateStr,
                             at: CGPoint(x: page.width - margin, y: originY + 22),
                             font: .systemFont(ofSize: 10, weight: .medium),
                             color: textSecondary)
        drawTextRightAligned("www.misicopy.com",
                             at: CGPoint(x: page.width - margin, y: originY + 6),
                             font: .systemFont(ofSize: 9),
                             color: brand)

        // Separator
        cursorY = page.height - originY + 14
        drawSeparator()
        cursorY += 12
    }

    // MARK: - Metadata

    private func drawMetadata() {
        let labelFont = NSFont.systemFont(ofSize: 9, weight: .semibold)
        let valueFont = NSFont.systemFont(ofSize: 10)

        let durationFormatter = DateComponentsFormatter()
        durationFormatter.allowedUnits = [.hour, .minute, .second]
        durationFormatter.unitsStyle = .abbreviated
        let duration = durationFormatter.string(from: input.startDate, to: input.endDate) ?? "—"

        let bytesFmt = ByteCountFormatter()
        bytesFmt.countStyle = .file

        let rows: [(String, String)] = [
            (labelize(input.l10n.sectionSource),
             input.sourceURL?.path(percentEncoded: false) ?? "—"),
            (labelize(input.l10n.sectionDestinations),
             input.destination.path),
            (labelize(input.l10n.sectionMode),
             input.l10n.modeTitle(input.mode)),
            ("VERIFICATION",
             input.l10n.modeVerificationDetail(input.mode)),
            (labelize(input.l10n.labelAlgorithm),
             input.algorithm.displayName),
            ("DURATION",
             duration),
            ("TOTAL",
             "\(input.stats.found) — \(bytesFmt.string(fromByteCount: input.stats.totalBytes))")
        ]

        // Two-column metadata card
        let cardHeight = CGFloat(rows.count / 2 + rows.count % 2) * 22 + 18
        drawCard(height: cardHeight)

        let colWidth = (page.width - margin * 2 - 24) / 2
        var x = margin + 12
        var y = cursorY + 12
        for (index, row) in rows.enumerated() {
            drawText(row.0, at: CGPoint(x: x, y: page.height - y - 9),
                     font: labelFont, color: textSecondary)
            drawText(row.1, at: CGPoint(x: x, y: page.height - y - 22),
                     font: valueFont, color: textPrimary,
                     maxWidth: colWidth - 8)
            if index % 2 == 0 {
                x += colWidth
            } else {
                x = margin + 12
                y += 22
            }
        }
        cursorY += cardHeight + 14
    }

    // MARK: - Stats

    private func drawStatsRow() {
        let cellHeight: CGFloat = 56
        let cellWidth = (page.width - margin * 2 - 30) / 4

        let cells: [(String, String, NSColor)] = [
            (input.l10n.statFound, "\(input.stats.found)",
             NSColor.systemBlue),
            (input.l10n.statCopied, "\(input.stats.copied)",
             NSColor.systemIndigo),
            (input.l10n.statVerified, "\(input.stats.verified)",
             NSColor.systemGreen),
            (input.l10n.statFailed, "\(input.stats.failed)",
             NSColor.systemOrange)
        ]

        var x = margin
        for cell in cells {
            let rect = CGRect(x: x,
                              y: page.height - cursorY - cellHeight,
                              width: cellWidth,
                              height: cellHeight)
            ctx.saveGState()
            ctx.setFillColor(cell.2.withAlphaComponent(0.10).cgColor)
            let path = CGPath(roundedRect: rect, cornerWidth: 8, cornerHeight: 8, transform: nil)
            ctx.addPath(path)
            ctx.fillPath()
            ctx.setStrokeColor(cell.2.withAlphaComponent(0.30).cgColor)
            ctx.setLineWidth(0.5)
            ctx.addPath(path)
            ctx.strokePath()
            ctx.restoreGState()

            drawTextCentered(cell.0.uppercased(),
                             in: CGRect(x: rect.minX,
                                        y: rect.minY + cellHeight - 16,
                                        width: rect.width,
                                        height: 12),
                             font: .systemFont(ofSize: 8, weight: .semibold),
                             color: cell.2)
            drawTextCentered(cell.1,
                             in: CGRect(x: rect.minX,
                                        y: rect.minY + 12,
                                        width: rect.width,
                                        height: 26),
                             font: .systemFont(ofSize: 22, weight: .bold),
                             color: textPrimary)

            x += cellWidth + 10
        }
        cursorY += cellHeight + 16
    }

    // MARK: - Files table

    private func drawFilesTable(rows: [ClipRow]) {
        let title = labelize(input.l10n.sectionJournal)
        drawText(title,
                 at: CGPoint(x: margin, y: page.height - cursorY - 9),
                 font: .systemFont(ofSize: 9, weight: .semibold),
                 color: textSecondary)
        cursorY += 16

        let columns = TableColumns(pageWidth: page.width, margin: margin, language: input.l10n.language)
        drawTableHeader(columns: columns)

        for (index, row) in rows.enumerated() {
            newPageIfNeeded(20)
            drawTableRow(row: row,
                         columns: columns,
                         alternating: index.isMultiple(of: 2))
        }
    }

    private func drawTableHeader(columns: TableColumns) {
        let rect = CGRect(x: margin,
                          y: page.height - cursorY - 20,
                          width: page.width - margin * 2,
                          height: 20)
        ctx.saveGState()
        ctx.setFillColor(NSColor(white: 0.93, alpha: 1).cgColor)
        ctx.fill(rect)
        ctx.restoreGState()

        let headers = columns.headers(l10n: input.l10n)
        let font = NSFont.systemFont(ofSize: 8, weight: .semibold)
        for (col, label) in headers {
            drawText(label.uppercased(),
                     at: CGPoint(x: col.x + 6, y: page.height - cursorY - 14),
                     font: font, color: textSecondary)
        }
        cursorY += 20
    }

    private func drawTableRow(row: ClipRow, columns: TableColumns, alternating: Bool) {
        let rowHeight: CGFloat = 18
        let rect = CGRect(x: margin,
                          y: page.height - cursorY - rowHeight,
                          width: page.width - margin * 2,
                          height: rowHeight)
        if alternating {
            ctx.saveGState()
            ctx.setFillColor(altRow.cgColor)
            ctx.fill(rect)
            ctx.restoreGState()
        }

        let font = NSFont.systemFont(ofSize: 9)
        let monoFont = NSFont.monospacedSystemFont(ofSize: 8, weight: .regular)
        let bytesFmt = ByteCountFormatter()
        bytesFmt.countStyle = .file

        let (statusLabel, statusColor) = statusInfo(for: row.aggregatedStatus)

        let cells: [TableColumns.Column: (String, NSFont, NSColor)] = [
            columns.file: (row.journalLabel, font, textPrimary),
            columns.size: (bytesFmt.string(fromByteCount: row.totalSize), font, textPrimary),
            columns.checksum: (truncatedHash(row.checksumDisplay), monoFont, textSecondary),
            columns.status: (statusLabel, font, statusColor)
        ]

        for col in columns.ordered {
            guard let (text, f, color) = cells[col] else { continue }
            drawText(text,
                     at: CGPoint(x: col.x + 6, y: page.height - cursorY - 12),
                     font: f, color: color,
                     maxWidth: col.width - 12)
        }

        cursorY += rowHeight
    }

    private func truncatedHash(_ hash: String?) -> String {
        guard let h = hash, !h.isEmpty else { return "—" }
        if h.count <= 16 { return h }
        return String(h.prefix(8)) + "…" + String(h.suffix(8))
    }

    private func statusInfo(for status: FileStatus) -> (String, NSColor) {
        switch status {
        case .verified:
            return (input.l10n.statVerified, NSColor.systemGreen)
        case .copied:
            return (input.l10n.statCopied, NSColor.systemIndigo)
        case .failed(let reason):
            return ("✗ \(reason)", NSColor.systemRed)
        case .skipped:
            return ("—", textSecondary)
        default:
            return ("…", textSecondary)
        }
    }

    // MARK: - Footer

    private func drawFooter() {
        let y = margin - 8
        drawTextCentered(input.l10n.footerCredit + " — www.misicopy.com",
                         in: CGRect(x: 0, y: y, width: page.width, height: 14),
                         font: .systemFont(ofSize: 8),
                         color: textSecondary)
    }

    // MARK: - Primitives

    private func drawCard(height: CGFloat) {
        let rect = CGRect(x: margin,
                          y: page.height - cursorY - height,
                          width: page.width - margin * 2,
                          height: height)
        ctx.saveGState()
        ctx.setFillColor(cardBackground.cgColor)
        ctx.setStrokeColor(cardBorder.cgColor)
        ctx.setLineWidth(0.5)
        let path = CGPath(roundedRect: rect, cornerWidth: 8, cornerHeight: 8, transform: nil)
        ctx.addPath(path)
        ctx.drawPath(using: .fillStroke)
        ctx.restoreGState()
    }

    private func drawSeparator() {
        let y = page.height - cursorY
        ctx.saveGState()
        ctx.setStrokeColor(cardBorder.cgColor)
        ctx.setLineWidth(0.5)
        ctx.move(to: CGPoint(x: margin, y: y))
        ctx.addLine(to: CGPoint(x: page.width - margin, y: y))
        ctx.strokePath()
        ctx.restoreGState()
    }

    private func drawText(_ string: String,
                          at point: CGPoint,
                          font: NSFont,
                          color: NSColor,
                          maxWidth: CGFloat? = nil) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        let text = NSAttributedString(string: string, attributes: attrs)
        let frame: CGRect
        if let maxWidth {
            frame = CGRect(x: point.x, y: point.y, width: maxWidth, height: font.pointSize + 2)
        } else {
            let size = text.size()
            frame = CGRect(x: point.x, y: point.y, width: size.width, height: size.height)
        }
        draw(attrString: text, in: frame, alignment: .left, lineBreak: maxWidth != nil ? .byTruncatingMiddle : .byClipping)
    }

    private func drawTextRightAligned(_ string: String,
                                      at point: CGPoint,
                                      font: NSFont,
                                      color: NSColor) {
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let text = NSAttributedString(string: string, attributes: attrs)
        let size = text.size()
        let frame = CGRect(x: point.x - size.width, y: point.y, width: size.width, height: size.height)
        draw(attrString: text, in: frame, alignment: .right, lineBreak: .byClipping)
    }

    private func drawTextCentered(_ string: String,
                                  in rect: CGRect,
                                  font: NSFont,
                                  color: NSColor) {
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let text = NSAttributedString(string: string, attributes: attrs)
        draw(attrString: text, in: rect, alignment: .center, lineBreak: .byTruncatingTail)
    }

    private func draw(attrString: NSAttributedString,
                      in rect: CGRect,
                      alignment: NSTextAlignment,
                      lineBreak: NSLineBreakMode) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = alignment
        paragraph.lineBreakMode = lineBreak
        let mutable = NSMutableAttributedString(attributedString: attrString)
        mutable.addAttribute(.paragraphStyle, value: paragraph,
                             range: NSRange(location: 0, length: mutable.length))

        NSGraphicsContext.saveGraphicsState()
        let nsCtx = NSGraphicsContext(cgContext: ctx, flipped: false)
        NSGraphicsContext.current = nsCtx
        mutable.draw(in: rect)
        NSGraphicsContext.restoreGraphicsState()
    }

    private func drawSymbol(_ name: String, in rect: CGRect, tint: NSColor, weight: NSFont.Weight) {
        let config = NSImage.SymbolConfiguration(pointSize: rect.height, weight: weight)
            .applying(.init(paletteColors: [tint]))
        guard let image = NSImage(systemSymbolName: name, accessibilityDescription: nil)?
            .withSymbolConfiguration(config) else { return }
        NSGraphicsContext.saveGraphicsState()
        let nsCtx = NSGraphicsContext(cgContext: ctx, flipped: false)
        NSGraphicsContext.current = nsCtx
        image.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1.0)
        NSGraphicsContext.restoreGraphicsState()
    }

    private func labelize(_ s: String) -> String { s.uppercased() }
}

// MARK: - Table layout

private struct TableColumns {
    struct Column: Hashable {
        let x: CGFloat
        let width: CGFloat
    }

    let file: Column
    let size: Column
    let checksum: Column
    let status: Column
    let language: AppLanguage

    init(pageWidth: CGFloat, margin: CGFloat, language: AppLanguage) {
        self.language = language
        let total = pageWidth - margin * 2
        let sizeW: CGFloat = 70
        let hashW: CGFloat = 130
        let statusW: CGFloat = 90
        let fileW = total - sizeW - hashW - statusW
        file = Column(x: margin, width: fileW)
        size = Column(x: margin + fileW, width: sizeW)
        checksum = Column(x: margin + fileW + sizeW, width: hashW)
        status = Column(x: margin + fileW + sizeW + hashW, width: statusW)
    }

    var ordered: [Column] { [file, size, checksum, status] }

    func headers(l10n: Localization) -> [(Column, String)] {
        let fileLabel: String
        let sizeLabel: String
        let hashLabel: String
        let statusLabel: String
        switch language {
        case .fr:
            fileLabel = "Fichier"; sizeLabel = "Taille"; hashLabel = "Checksum"; statusLabel = "Statut"
        case .en:
            fileLabel = "File"; sizeLabel = "Size"; hashLabel = "Checksum"; statusLabel = "Status"
        case .es:
            fileLabel = "Archivo"; sizeLabel = "Tamaño"; hashLabel = "Checksum"; statusLabel = "Estado"
        }
        return [
            (file, fileLabel),
            (size, sizeLabel),
            (checksum, hashLabel),
            (status, statusLabel)
        ]
    }
}

// MARK: - Clip grouping

/// One row in the report's thumbnail grid + journal table. For ordinary
/// standalone files this represents a single FileItem. For image
/// sequences (DPX/EXR/…) it represents the whole "plan" (N frames as 1
/// row with aggregated size and status).
struct ClipRow {
    let representative: FileItem
    let frameCount: Int
    let totalSize: Int64
    let aggregatedStatus: FileStatus
    let allChecksums: [String]

    var checksumDisplay: String? {
        if frameCount == 1 { return representative.sourceChecksum }
        // For sequences, the per-frame hash isn't meaningful at the plan
        // level — show "—" rather than misleading the reader.
        return nil
    }

    var journalLabel: String {
        if frameCount == 1 { return representative.relativePath }
        // Replace the trailing frame number with "####" so it reads as a sequence.
        let rel = representative.relativePath
        let ext = (rel as NSString).pathExtension
        let stem = (rel as NSString).deletingPathExtension
        var endDigits = stem.endIndex
        while endDigits > stem.startIndex {
            let prev = stem.index(before: endDigits)
            if stem[prev].isASCII && stem[prev].isNumber { endDigits = prev } else { break }
        }
        let base = String(stem[..<endDigits])
        return "\(base)####.\(ext) — \(frameCount) frames"
    }

    var thumbnailLabel: String {
        if frameCount == 1 {
            return (representative.displayName as NSString).lastPathComponent
        }
        let stem = (representative.displayName as NSString).deletingPathExtension
        var endDigits = stem.endIndex
        while endDigits > stem.startIndex {
            let prev = stem.index(before: endDigits)
            if stem[prev].isASCII && stem[prev].isNumber { endDigits = prev } else { break }
        }
        let base = String(stem[..<endDigits])
        let ext = (representative.displayName as NSString).pathExtension
        return "\(base)####.\(ext)"
    }

    static func build(from files: [FileItem]) -> [ClipRow] {
        var rows: [ClipRow] = []
        var groups: [String: [FileItem]] = [:]
        var groupOrder: [String] = []

        for file in files {
            if let family = file.clipFamily {
                if groups[family] == nil {
                    groups[family] = []
                    groupOrder.append(family)
                }
                groups[family]?.append(file)
            } else {
                rows.append(ClipRow(representative: file,
                                    frameCount: 1,
                                    totalSize: file.size,
                                    aggregatedStatus: file.status,
                                    allChecksums: [file.sourceChecksum].compactMap { $0 }))
            }
        }

        // Emit grouped sequences (sorted by relative path within each family).
        for family in groupOrder {
            let frames = (groups[family] ?? []).sorted { $0.relativePath < $1.relativePath }
            guard let first = frames.first else { continue }
            let totalSize = frames.reduce(Int64(0)) { $0 + $1.size }
            let aggregated = aggregateStatus(frames.map(\.status))
            rows.append(ClipRow(representative: first,
                                frameCount: frames.count,
                                totalSize: totalSize,
                                aggregatedStatus: aggregated,
                                allChecksums: frames.compactMap(\.sourceChecksum)))
        }

        return rows.sorted { $0.representative.relativePath < $1.representative.relativePath }
    }

    private static func aggregateStatus(_ statuses: [FileStatus]) -> FileStatus {
        // Failure wins. Otherwise the "lowest" progress wins.
        for s in statuses {
            if case .failed = s { return s }
        }
        if statuses.allSatisfy({ if case .verified = $0 { true } else { false } }) {
            return .verified
        }
        if statuses.allSatisfy({
            if case .verified = $0 { true }
            else if case .copied = $0 { true }
            else { false }
        }) {
            return .copied
        }
        if statuses.contains(where: { if case .skipped = $0 { true } else { false } }) {
            return .skipped
        }
        return .pending
    }
}
