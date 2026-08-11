#!/usr/bin/env swift
//
//  generate_manual_pdf.swift
//
//  Renders marketing/manual.md as a branded multi-page A4 PDF with:
//  — a full-bleed cover page (gradient + logo + title)
//  — branded section banners per language
//  — clean typography, tables, code blocks
//  — footer with logo + page number on every content page
//

import Foundation
import AppKit
import CoreGraphics

// ─────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────

let pageSize = CGSize(width: 595, height: 842)  // A4
var mediaBox = CGRect(origin: .zero, size: pageSize)
let margin: CGFloat = 50
let contentTop: CGFloat = pageSize.height - 60     // y from bottom
let contentBottom: CGFloat = 70                    // y from bottom (above footer)

let brandStart  = NSColor(red: 0.13, green: 0.85, blue: 1.00, alpha: 1)
let brandMid    = NSColor(red: 0.18, green: 0.55, blue: 1.00, alpha: 1)
let brandEnd    = NSColor(red: 0.28, green: 0.32, blue: 0.96, alpha: 1)
let textPrimary = NSColor(white: 0.10, alpha: 1)
let textSecondary = NSColor(white: 0.45, alpha: 1)
let cardBorder  = NSColor(white: 0.88, alpha: 1)
let cardBackground = NSColor(white: 0.97, alpha: 1)

// ─────────────────────────────────────────────────────────────────────
// CLI / Paths
// ─────────────────────────────────────────────────────────────────────

let scriptDir = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()
let projectDir = scriptDir.deletingLastPathComponent()
let mdURL = projectDir.appending(path: "marketing/manual.md")
let outURL = projectDir.appending(path: "marketing/MisiCopy-Manuel.pdf")
let logoURL = projectDir.appending(path: "marketing/logo-misicopy.svg")

// Load the brand SVG once. NSImage decodes SVG natively on macOS 14+.
let brandLogo: NSImage? = NSImage(contentsOf: logoURL)
if brandLogo == nil {
    print("⚠️  Logo introuvable : \(logoURL.path) — repli sur le logo synthétique.")
}

guard let raw = try? String(contentsOf: mdURL, encoding: .utf8) else {
    print("Manuel introuvable : \(mdURL.path)"); exit(1)
}

// Split into language blocks. Each block starts with "# 🇫🇷 Français"
// or "# 🇬🇧 English" or "# 🇪🇸 Español".
struct Section { let title: String; let body: String }
struct LanguageBlock {
    let flag: String
    let title: String
    let sections: [Section]
}

func parseBlocks(_ md: String) -> [LanguageBlock] {
    let lines = md.components(separatedBy: "\n")
    var blocks: [LanguageBlock] = []
    var currentFlag = ""
    var currentTitle = ""
    var sections: [Section] = []
    var sectionTitle = ""
    var sectionBody = ""

    func flushSection() {
        if !sectionTitle.isEmpty || !sectionBody.isEmpty {
            sections.append(Section(title: sectionTitle,
                                    body: sectionBody.trimmingCharacters(in: .whitespacesAndNewlines)))
        }
        sectionTitle = ""; sectionBody = ""
    }
    func flushBlock() {
        flushSection()
        if !currentFlag.isEmpty {
            blocks.append(LanguageBlock(flag: currentFlag,
                                        title: currentTitle,
                                        sections: sections))
        }
        sections = []; currentFlag = ""; currentTitle = ""
    }

    for line in lines {
        if line.hasPrefix("# 🇫🇷") || line.hasPrefix("# 🇬🇧") || line.hasPrefix("# 🇪🇸") {
            flushBlock()
            let parts = line.dropFirst(2).split(separator: " ", maxSplits: 1)
            if let first = parts.first { currentFlag = String(first) }
            if parts.count > 1 { currentTitle = String(parts[1]) }
        } else if line.hasPrefix("## ") && !currentFlag.isEmpty {
            flushSection()
            sectionTitle = String(line.dropFirst(3))
        } else if !currentFlag.isEmpty {
            sectionBody += line + "\n"
        }
    }
    flushBlock()
    return blocks
}

let blocks = parseBlocks(raw)

// ─────────────────────────────────────────────────────────────────────
// Context + drawing primitives
// ─────────────────────────────────────────────────────────────────────

guard let ctx = CGContext(outURL as CFURL, mediaBox: &mediaBox, nil) else {
    print("Could not create PDF context"); exit(1)
}
let nsCtx = NSGraphicsContext(cgContext: ctx, flipped: false)
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = nsCtx

var currentPage = 0

func beginPage() {
    ctx.beginPDFPage(nil)
    ctx.setFillColor(NSColor.white.cgColor)
    ctx.fill(mediaBox)
    currentPage += 1
}

func endPage() {
    if currentPage > 1 { drawFooter() }
    ctx.endPDFPage()
}

func drawString(_ s: String, at point: CGPoint, font: NSFont,
                color: NSColor, maxWidth: CGFloat? = nil,
                alignment: NSTextAlignment = .left) -> CGFloat {
    let p = NSMutableParagraphStyle()
    p.alignment = alignment
    p.lineBreakMode = .byWordWrapping
    p.lineSpacing = 2
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font, .foregroundColor: color, .paragraphStyle: p
    ]
    let str = NSAttributedString(string: s, attributes: attrs)
    let width = maxWidth ?? (pageSize.width - 2 * margin)
    let size = str.boundingRect(with: CGSize(width: width, height: 9999),
                                options: [.usesLineFragmentOrigin])
    let drawRect = CGRect(x: point.x, y: point.y - size.height,
                          width: width, height: size.height)
    str.draw(in: drawRect)
    return size.height
}

func roundedRect(_ rect: CGRect, radius: CGFloat,
                 fill: NSColor? = nil, stroke: NSColor? = nil, lineWidth: CGFloat = 1) {
    let path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
    ctx.saveGState()
    if let fill {
        ctx.setFillColor(fill.cgColor)
        ctx.addPath(path); ctx.fillPath()
    }
    if let stroke {
        ctx.setStrokeColor(stroke.cgColor)
        ctx.setLineWidth(lineWidth)
        ctx.addPath(path); ctx.strokePath()
    }
    ctx.restoreGState()
}

func gradient(in rect: CGRect, colors: [CGColor], locations: [CGFloat],
              from: CGPoint, to: CGPoint, cornerRadius: CGFloat = 0) {
    ctx.saveGState()
    let path: CGPath = cornerRadius > 0
        ? CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
        : CGPath(rect: rect, transform: nil)
    ctx.addPath(path); ctx.clip()
    let cs = CGColorSpaceCreateDeviceRGB()
    if let g = CGGradient(colorsSpace: cs, colors: colors as CFArray, locations: locations) {
        ctx.drawLinearGradient(g,
                               start: CGPoint(x: rect.minX + from.x * rect.width,
                                              y: rect.minY + from.y * rect.height),
                               end: CGPoint(x: rect.minX + to.x * rect.width,
                                            y: rect.minY + to.y * rect.height),
                               options: [])
    }
    ctx.restoreGState()
}

func drawLogo(in rect: CGRect) {
    // Prefer the real SVG brand logo when available; fall back to the
    // synthetic gradient version otherwise.
    if let logo = brandLogo {
        logo.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1.0)
        return
    }
    drawLogoSynthetic(in: rect)
}

func drawLogoSynthetic(in rect: CGRect) {
    // Gradient rounded square (squircle look)
    gradient(in: rect,
             colors: [brandStart.cgColor, brandMid.cgColor, brandEnd.cgColor],
             locations: [0, 0.55, 1],
             from: CGPoint(x: 0, y: 1), to: CGPoint(x: 1, y: 0),
             cornerRadius: rect.width * 0.22)
    // Glyph
    let config = NSImage.SymbolConfiguration(pointSize: rect.height * 0.55, weight: .semibold)
        .applying(.init(paletteColors: [.white]))
    if let img = NSImage(systemSymbolName: "shippingbox.fill", accessibilityDescription: nil)?
        .withSymbolConfiguration(config) {
        let inset = rect.height * 0.22
        img.draw(in: rect.insetBy(dx: inset, dy: inset),
                 from: .zero, operation: .sourceOver, fraction: 1.0)
    }
    // Green check badge bottom-right
    let badge = CGRect(x: rect.maxX - rect.width * 0.42,
                       y: rect.minY + rect.width * 0.04,
                       width: rect.width * 0.40, height: rect.width * 0.40)
    ctx.saveGState()
    let bp = CGPath(ellipseIn: badge, transform: nil)
    ctx.addPath(bp); ctx.clip()
    let cs = CGColorSpaceCreateDeviceRGB()
    if let g = CGGradient(colorsSpace: cs,
                          colors: [NSColor(red: 0.55, green: 1, blue: 0.45, alpha: 1).cgColor,
                                   NSColor(red: 0.10, green: 0.78, blue: 0.30, alpha: 1).cgColor] as CFArray,
                          locations: [0, 1]) {
        ctx.drawLinearGradient(g, start: CGPoint(x: badge.midX, y: badge.maxY),
                               end: CGPoint(x: badge.midX, y: badge.minY), options: [])
    }
    ctx.restoreGState()
    ctx.setStrokeColor(NSColor.white.cgColor)
    ctx.setLineWidth(rect.width * 0.025)
    ctx.addPath(bp); ctx.strokePath()
    let checkConfig = NSImage.SymbolConfiguration(pointSize: badge.height * 0.7, weight: .heavy)
        .applying(.init(paletteColors: [.white]))
    if let check = NSImage(systemSymbolName: "checkmark", accessibilityDescription: nil)?
        .withSymbolConfiguration(checkConfig) {
        let s = check.size
        let r = CGRect(x: badge.midX - s.width/2, y: badge.midY - s.height/2,
                       width: s.width, height: s.height)
        check.draw(in: r, from: .zero, operation: .sourceOver, fraction: 1.0)
    }
}

func drawFooter() {
    // Logo mini + misicopy.com + page number
    let y: CGFloat = 30
    let logoRect = CGRect(x: margin, y: y - 6, width: 18, height: 18)
    drawLogo(in: logoRect)
    _ = drawString("MisiCopy · misicopy.com",
                   at: CGPoint(x: margin + 26, y: y + 13),
                   font: .systemFont(ofSize: 9, weight: .medium),
                   color: textSecondary)
    let pageStr = "— \(currentPage) —"
    _ = drawString(pageStr,
                   at: CGPoint(x: pageSize.width - margin - 60, y: y + 13),
                   font: .systemFont(ofSize: 9),
                   color: textSecondary,
                   maxWidth: 60,
                   alignment: .right)
    // Hairline separator
    ctx.saveGState()
    ctx.setStrokeColor(NSColor(white: 0.88, alpha: 1).cgColor)
    ctx.setLineWidth(0.5)
    ctx.move(to: CGPoint(x: margin, y: 56))
    ctx.addLine(to: CGPoint(x: pageSize.width - margin, y: 56))
    ctx.strokePath()
    ctx.restoreGState()
}

// ─────────────────────────────────────────────────────────────────────
// Cover page
// ─────────────────────────────────────────────────────────────────────

func drawCover() {
    beginPage()
    // Full-bleed gradient
    gradient(in: mediaBox,
             colors: [brandStart.cgColor, brandMid.cgColor, brandEnd.cgColor],
             locations: [0, 0.55, 1],
             from: CGPoint(x: 0, y: 1), to: CGPoint(x: 1, y: 0))

    // Subtle radial highlight (top-left bright spot)
    ctx.saveGState()
    if let radial = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                               colors: [CGColor(red: 1, green: 1, blue: 1, alpha: 0.35),
                                        CGColor(red: 1, green: 1, blue: 1, alpha: 0)] as CFArray,
                               locations: [0, 1]) {
        ctx.drawRadialGradient(radial,
                               startCenter: CGPoint(x: 80, y: pageSize.height - 80),
                               startRadius: 0,
                               endCenter: CGPoint(x: 80, y: pageSize.height - 80),
                               endRadius: 280, options: [])
    }
    ctx.restoreGState()

    // Logo centered, slightly above center
    let logoSize: CGFloat = 200
    let logoY: CGFloat = pageSize.height / 2 + 60
    drawLogo(in: CGRect(x: (pageSize.width - logoSize) / 2,
                        y: logoY,
                        width: logoSize, height: logoSize))

    // Main title
    let titleY: CGFloat = logoY - 36
    _ = drawString("MisiCopy",
                   at: CGPoint(x: 0, y: titleY),
                   font: .systemFont(ofSize: 56, weight: .black),
                   color: .white,
                   maxWidth: pageSize.width,
                   alignment: .center)

    // Subtitle in 3 languages
    let subY: CGFloat = titleY - 64
    _ = drawString("Manuel utilisateur · User Manual · Manual de usuario",
                   at: CGPoint(x: 0, y: subY),
                   font: .systemFont(ofSize: 14, weight: .medium),
                   color: NSColor.white.withAlphaComponent(0.92),
                   maxWidth: pageSize.width,
                   alignment: .center)

    // Version pill
    let pillRect = CGRect(x: (pageSize.width - 100) / 2,
                          y: subY - 50,
                          width: 100, height: 24)
    roundedRect(pillRect, radius: 12, fill: NSColor.white.withAlphaComponent(0.18))
    let p = NSMutableParagraphStyle(); p.alignment = .center
    let pillStr = NSAttributedString(string: "VERSION 1.11.0",
        attributes: [.font: NSFont.systemFont(ofSize: 10, weight: .heavy),
                     .foregroundColor: NSColor.white, .paragraphStyle: p,
                     .kern: 1.2])
    pillStr.draw(in: CGRect(x: pillRect.minX, y: pillRect.midY - 6,
                            width: pillRect.width, height: 12))

    // Bottom credit
    _ = drawString("misicopy.com",
                   at: CGPoint(x: 0, y: 60),
                   font: .systemFont(ofSize: 12, weight: .semibold),
                   color: .white,
                   maxWidth: pageSize.width,
                   alignment: .center)
    _ = drawString("© 2026 Matthieu Misiraca",
                   at: CGPoint(x: 0, y: 42),
                   font: .systemFont(ofSize: 9),
                   color: NSColor.white.withAlphaComponent(0.7),
                   maxWidth: pageSize.width,
                   alignment: .center)

    endPage()
}

// ─────────────────────────────────────────────────────────────────────
// Content layout
// ─────────────────────────────────────────────────────────────────────

/// Tracks the y cursor (measured from top of page). Decreases as we draw down.
var cursor: CGFloat = contentTop

func currentY() -> CGFloat { cursor }

func ensureSpace(_ needed: CGFloat) {
    if cursor - needed < contentBottom {
        endPage()
        beginPage()
        cursor = contentTop
    }
}

func drawLanguageBanner(_ block: LanguageBlock) {
    ensureSpace(100)  // banner takes ~60 + breathing
    let bannerRect = CGRect(x: margin, y: cursor - 56,
                            width: pageSize.width - 2 * margin, height: 56)
    gradient(in: bannerRect,
             colors: [brandStart.cgColor, brandMid.cgColor],
             locations: [0, 1],
             from: CGPoint(x: 0, y: 0.5), to: CGPoint(x: 1, y: 0.5),
             cornerRadius: 10)
    // Flag
    _ = drawString(block.flag,
                   at: CGPoint(x: bannerRect.minX + 22, y: bannerRect.midY + 14),
                   font: .systemFont(ofSize: 24),
                   color: .white)
    // Title
    _ = drawString(block.title,
                   at: CGPoint(x: bannerRect.minX + 64, y: bannerRect.midY + 12),
                   font: .systemFont(ofSize: 22, weight: .bold),
                   color: .white)
    cursor -= 56 + 18
}

func drawSectionHeader(_ title: String) {
    ensureSpace(40)
    // Small brand dot
    let dot = CGRect(x: margin, y: cursor - 8, width: 6, height: 6)
    roundedRect(dot, radius: 3, fill: brandMid)
    let height = drawString(title,
                            at: CGPoint(x: margin + 16, y: cursor),
                            font: .systemFont(ofSize: 14, weight: .bold),
                            color: textPrimary,
                            maxWidth: pageSize.width - 2 * margin - 16)
    cursor -= height + 8
}

/// Renders inline markdown (bold, code) on a single line.
func renderInlineAttributed(_ raw: String, font: NSFont, color: NSColor) -> NSAttributedString {
    let result = NSMutableAttributedString(string: raw, attributes: [
        .font: font, .foregroundColor: color
    ])
    // **bold**
    let boldRegex = try! NSRegularExpression(pattern: #"\*\*([^*]+)\*\*"#)
    let cs = result.string as NSString
    let matches = boldRegex.matches(in: result.string,
                                    range: NSRange(location: 0, length: cs.length))
    for m in matches.reversed() {
        let innerRange = m.range(at: 1)
        let inner = cs.substring(with: innerRange)
        let replacement = NSAttributedString(string: inner, attributes: [
            .font: NSFontManager.shared.convert(font, toHaveTrait: .boldFontMask),
            .foregroundColor: color
        ])
        result.replaceCharacters(in: m.range, with: replacement)
    }
    // `code`
    let codeRegex = try! NSRegularExpression(pattern: #"`([^`]+)`"#)
    let cs2 = result.string as NSString
    let matches2 = codeRegex.matches(in: result.string,
                                     range: NSRange(location: 0, length: cs2.length))
    for m in matches2.reversed() {
        let innerRange = m.range(at: 1)
        let inner = cs2.substring(with: innerRange)
        let monoFont = NSFont.monospacedSystemFont(ofSize: font.pointSize - 0.5, weight: .regular)
        let replacement = NSAttributedString(string: inner, attributes: [
            .font: monoFont,
            .foregroundColor: NSColor(white: 0.18, alpha: 1),
            .backgroundColor: NSColor(white: 0.95, alpha: 1)
        ])
        result.replaceCharacters(in: m.range, with: replacement)
    }
    return result
}

func drawAttributed(_ attr: NSAttributedString, maxWidth: CGFloat) -> CGFloat {
    let p = NSMutableParagraphStyle()
    p.lineSpacing = 3
    p.lineBreakMode = .byWordWrapping
    let mut = NSMutableAttributedString(attributedString: attr)
    mut.addAttribute(.paragraphStyle, value: p, range: NSRange(location: 0, length: mut.length))
    let size = mut.boundingRect(with: CGSize(width: maxWidth, height: 9999),
                                options: [.usesLineFragmentOrigin])
    let drawRect = CGRect(x: margin, y: cursor - size.height,
                          width: maxWidth, height: size.height)
    mut.draw(in: drawRect)
    return size.height
}

func drawParagraph(_ text: String) {
    let attr = renderInlineAttributed(text, font: .systemFont(ofSize: 10.5),
                                      color: textPrimary)
    let needed = attr.boundingRect(with: CGSize(width: pageSize.width - 2*margin, height: 9999),
                                   options: [.usesLineFragmentOrigin]).height + 8
    ensureSpace(needed)
    let h = drawAttributed(attr, maxWidth: pageSize.width - 2*margin)
    cursor -= h + 6
}

func drawBullet(_ text: String) {
    let attr = renderInlineAttributed(text, font: .systemFont(ofSize: 10.5),
                                      color: textPrimary)
    let bulletInset: CGFloat = 14
    let needed = attr.boundingRect(with: CGSize(width: pageSize.width - 2*margin - bulletInset, height: 9999),
                                   options: [.usesLineFragmentOrigin]).height + 6
    ensureSpace(needed)
    // Bullet
    let dot = CGRect(x: margin + 3, y: cursor - 8, width: 3, height: 3)
    roundedRect(dot, radius: 1.5, fill: brandMid)
    // Text indented
    let p = NSMutableParagraphStyle()
    p.lineSpacing = 3
    let mut = NSMutableAttributedString(attributedString: attr)
    mut.addAttribute(.paragraphStyle, value: p, range: NSRange(location: 0, length: mut.length))
    let width = pageSize.width - 2*margin - bulletInset
    let size = mut.boundingRect(with: CGSize(width: width, height: 9999),
                                options: [.usesLineFragmentOrigin])
    mut.draw(in: CGRect(x: margin + bulletInset, y: cursor - size.height,
                        width: width, height: size.height))
    cursor -= size.height + 4
}

func drawTableRow(_ left: String, _ right: String, isHeader: Bool = false) {
    let rowHeight: CGFloat = isHeader ? 22 : 20
    ensureSpace(rowHeight)
    let rect = CGRect(x: margin, y: cursor - rowHeight,
                      width: pageSize.width - 2*margin, height: rowHeight)
    if isHeader {
        ctx.saveGState()
        ctx.setFillColor(NSColor(white: 0.92, alpha: 1).cgColor)
        ctx.fill(rect)
        ctx.restoreGState()
    }
    let leftFont = isHeader
        ? NSFont.systemFont(ofSize: 9, weight: .bold)
        : NSFont.monospacedSystemFont(ofSize: 10, weight: .semibold)
    let rightFont = NSFont.systemFont(ofSize: isHeader ? 9 : 10,
                                      weight: isHeader ? .bold : .regular)
    _ = drawString(left,
                   at: CGPoint(x: margin + 12, y: cursor - 6),
                   font: leftFont,
                   color: textPrimary,
                   maxWidth: 140)
    _ = drawString(right,
                   at: CGPoint(x: margin + 160, y: cursor - 6),
                   font: rightFont,
                   color: textPrimary,
                   maxWidth: rect.width - 172)
    // Bottom border
    ctx.saveGState()
    ctx.setStrokeColor(NSColor(white: 0.88, alpha: 1).cgColor)
    ctx.setLineWidth(0.5)
    ctx.move(to: CGPoint(x: margin, y: cursor - rowHeight))
    ctx.addLine(to: CGPoint(x: pageSize.width - margin, y: cursor - rowHeight))
    ctx.strokePath()
    ctx.restoreGState()
    cursor -= rowHeight
}

// ─────────────────────────────────────────────────────────────────────
// Body parser: emit primitives from a section's body
// ─────────────────────────────────────────────────────────────────────

func emit(body: String) {
    let lines = body.components(separatedBy: "\n")
    var inTable = false
    var i = 0
    while i < lines.count {
        let line = lines[i]
        // Empty: paragraph break
        if line.trimmingCharacters(in: .whitespaces).isEmpty {
            inTable = false
            cursor -= 4
            i += 1; continue
        }
        // Table row
        if line.hasPrefix("|") && line.hasSuffix("|") {
            // Detect separator row (---|---) and skip
            if line.contains("---") {
                inTable = true; i += 1; continue
            }
            let parts = line.dropFirst().dropLast().split(separator: "|", omittingEmptySubsequences: false)
            let left = parts.count > 0 ? String(parts[0]).trimmingCharacters(in: .whitespaces) : ""
            let right = parts.count > 1 ? String(parts[1]).trimmingCharacters(in: .whitespaces) : ""
            drawTableRow(left, right, isHeader: !inTable)
            inTable = true
            i += 1; continue
        }
        // Bullet list
        if line.hasPrefix("- ") {
            drawBullet(String(line.dropFirst(2)))
            i += 1; continue
        }
        // Ordered list (1. foo)
        let orderedRegex = try! NSRegularExpression(pattern: #"^\d+\.\s+(.+)$"#)
        if let m = orderedRegex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
           let inner = Range(m.range(at: 1), in: line) {
            drawBullet(String(line[inner]))
            i += 1; continue
        }
        // Sub-heading
        if line.hasPrefix("### ") {
            cursor -= 4
            ensureSpace(20)
            let h = drawString(String(line.dropFirst(4)),
                               at: CGPoint(x: margin, y: cursor),
                               font: .systemFont(ofSize: 11, weight: .bold),
                               color: textPrimary,
                               maxWidth: pageSize.width - 2*margin)
            cursor -= h + 4
            i += 1; continue
        }
        // Paragraph
        drawParagraph(line)
        i += 1
    }
    cursor -= 6
}

// ─────────────────────────────────────────────────────────────────────
// Render
// ─────────────────────────────────────────────────────────────────────

drawCover()
beginPage()
cursor = contentTop

for block in blocks {
    drawLanguageBanner(block)
    for s in block.sections {
        drawSectionHeader(s.title)
        emit(body: s.body)
    }
    // Page break between languages
    endPage()
    beginPage()
    cursor = contentTop
}

// Final page may be blank if we just opened one — close it cleanly.
endPage()

NSGraphicsContext.restoreGraphicsState()
ctx.closePDF()

print("✅ Manuel PDF généré : \(outURL.path)")
