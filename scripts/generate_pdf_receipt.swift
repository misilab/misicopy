#!/usr/bin/env swift
//
//  generate_pdf_receipt.swift
//
//  Pixel-perfect post-purchase welcome PDF for a MisiCopy customer.
//  Rendered with CoreGraphics, A4, single page, branded.
//
//  Usage:
//    swift scripts/generate_pdf_receipt.swift "Nom Client" "email@x.com" \
//          "B4XQ-K7M2-N8P3-R5T6-J9V1" "2026-06-04"
//
//  Output:
//    out/MisiCopy-Welcome-<email>.pdf
//

import Foundation
import AppKit
import CoreGraphics

// ─────────────────────────────────────────────────────────────────────
// CLI
// ─────────────────────────────────────────────────────────────────────

guard CommandLine.arguments.count >= 5 else {
    print("Usage: swift scripts/generate_pdf_receipt.swift <name> <email> <key> <purchase_date>")
    exit(1)
}
let name = CommandLine.arguments[1]
let email = CommandLine.arguments[2]
let key = CommandLine.arguments[3]
let purchaseDate = CommandLine.arguments[4]

let scriptDir = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()
let projectDir = scriptDir.deletingLastPathComponent()
let outDir = projectDir.appending(path: "out")
try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)
let safe = email.replacingOccurrences(of: "@", with: "-at-")
let outURL = outDir.appending(path: "MisiCopy-Welcome-\(safe).pdf")

// ─────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────

let page = CGSize(width: 595, height: 842)  // A4 portrait
var box = CGRect(origin: .zero, size: page)

let brand = NSColor(red: 0.18, green: 0.55, blue: 1.00, alpha: 1)
let brand2 = NSColor(red: 0.28, green: 0.32, blue: 0.96, alpha: 1)
let green = NSColor(red: 0.10, green: 0.78, blue: 0.30, alpha: 1)
let textPrimary = NSColor(white: 0.10, alpha: 1)
let textSecondary = NSColor(white: 0.40, alpha: 1)
let cardBorder = NSColor(white: 0.88, alpha: 1)
let cardBackground = NSColor(white: 0.97, alpha: 1)

let margin: CGFloat = 36

// ─────────────────────────────────────────────────────────────────────
// PDF context
// ─────────────────────────────────────────────────────────────────────

guard let ctx = CGContext(outURL as CFURL, mediaBox: &box, nil) else {
    print("Failed to create PDF context"); exit(1)
}
ctx.beginPDFPage(nil)

let nsCtx = NSGraphicsContext(cgContext: ctx, flipped: false)
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = nsCtx

// White background
ctx.setFillColor(NSColor.white.cgColor)
ctx.fill(box)

// ─────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────

func drawText(_ string: String, at point: CGPoint, font: NSFont, color: NSColor,
              maxWidth: CGFloat? = nil, alignment: NSTextAlignment = .left) {
    let p = NSMutableParagraphStyle()
    p.alignment = alignment
    p.lineBreakMode = .byWordWrapping
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font, .foregroundColor: color, .paragraphStyle: p
    ]
    let s = NSAttributedString(string: string, attributes: attrs)
    if let maxWidth {
        let size = s.boundingRect(with: CGSize(width: maxWidth, height: 9999),
                                  options: [.usesLineFragmentOrigin])
        let rect = CGRect(x: point.x, y: point.y - size.height + font.pointSize + 2,
                          width: maxWidth, height: size.height)
        s.draw(in: rect)
    } else {
        s.draw(at: point)
    }
}

func drawCenteredText(_ string: String, in rect: CGRect, font: NSFont, color: NSColor) {
    let p = NSMutableParagraphStyle(); p.alignment = .center
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font, .foregroundColor: color, .paragraphStyle: p
    ]
    let s = NSAttributedString(string: string, attributes: attrs)
    let size = s.size()
    let y = rect.midY - size.height / 2
    s.draw(in: CGRect(x: rect.minX, y: y, width: rect.width, height: size.height))
}

func roundedRect(_ rect: CGRect, radius: CGFloat,
                 fill: NSColor? = nil, stroke: NSColor? = nil, strokeWidth: CGFloat = 1) {
    let path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
    ctx.saveGState()
    if let fill {
        ctx.setFillColor(fill.cgColor)
        ctx.addPath(path); ctx.fillPath()
    }
    if let stroke {
        ctx.setStrokeColor(stroke.cgColor)
        ctx.setLineWidth(strokeWidth)
        ctx.addPath(path); ctx.strokePath()
    }
    ctx.restoreGState()
}

func linearGradient(in rect: CGRect, colors: [CGColor], locations: [CGFloat],
                    from: CGPoint, to: CGPoint, cornerRadius: CGFloat = 0) {
    ctx.saveGState()
    // Always clip to the rect — without this the gradient bleeds across
    // the entire page.
    let path: CGPath = cornerRadius > 0
        ? CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
        : CGPath(rect: rect, transform: nil)
    ctx.addPath(path); ctx.clip()

    let cs = CGColorSpaceCreateDeviceRGB()
    if let grad = CGGradient(colorsSpace: cs, colors: colors as CFArray, locations: locations) {
        ctx.drawLinearGradient(grad,
                               start: CGPoint(x: rect.minX + from.x * rect.width,
                                              y: rect.minY + from.y * rect.height),
                               end: CGPoint(x: rect.minX + to.x * rect.width,
                                            y: rect.minY + to.y * rect.height),
                               options: [])
    }
    ctx.restoreGState()
}

func drawLogo(in rect: CGRect) {
    // Gradient rounded square
    linearGradient(
        in: rect,
        colors: [
            NSColor(red: 0.20, green: 0.92, blue: 1.00, alpha: 1).cgColor,
            NSColor(red: 0.18, green: 0.55, blue: 1.00, alpha: 1).cgColor,
            NSColor(red: 0.28, green: 0.32, blue: 0.96, alpha: 1).cgColor
        ],
        locations: [0, 0.55, 1],
        from: CGPoint(x: 0, y: 1), to: CGPoint(x: 1, y: 0),
        cornerRadius: rect.width * 0.22
    )
    // Glyph
    let g = NSImage.SymbolConfiguration(pointSize: rect.height * 0.55, weight: .semibold)
        .applying(.init(paletteColors: [.white]))
    if let img = NSImage(systemSymbolName: "shippingbox.fill", accessibilityDescription: nil)?
        .withSymbolConfiguration(g) {
        let inset = rect.height * 0.22
        let drawRect = rect.insetBy(dx: inset, dy: inset)
        img.draw(in: drawRect, from: .zero, operation: .sourceOver, fraction: 1.0)
    }
    // Check badge
    let badge = CGRect(
        x: rect.maxX - rect.width * 0.40,
        y: rect.minY + rect.width * 0.04,
        width: rect.width * 0.38, height: rect.width * 0.38
    )
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
    // Check mark
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

// ─────────────────────────────────────────────────────────────────────
// 1. Header band with brand gradient
// ─────────────────────────────────────────────────────────────────────

let headerHeight: CGFloat = 130
let headerRect = CGRect(x: 0, y: page.height - headerHeight, width: page.width, height: headerHeight)
linearGradient(
    in: headerRect,
    colors: [
        NSColor(red: 0.20, green: 0.92, blue: 1.00, alpha: 1).cgColor,
        NSColor(red: 0.18, green: 0.55, blue: 1.00, alpha: 1).cgColor,
        NSColor(red: 0.28, green: 0.32, blue: 0.96, alpha: 1).cgColor
    ],
    locations: [0, 0.55, 1],
    from: CGPoint(x: 0, y: 1), to: CGPoint(x: 1, y: 0)
)

// Logo top-left
let logoSize: CGFloat = 64
let logoRect = CGRect(x: margin, y: page.height - headerHeight/2 - logoSize/2,
                      width: logoSize, height: logoSize)
drawLogo(in: logoRect)

// Title + subtitle
drawText("MisiCopy",
         at: CGPoint(x: margin + logoSize + 16, y: page.height - 58),
         font: .systemFont(ofSize: 28, weight: .bold),
         color: .white)
drawText("Bienvenue à bord",
         at: CGPoint(x: margin + logoSize + 16, y: page.height - 86),
         font: .systemFont(ofSize: 14, weight: .medium),
         color: NSColor.white.withAlphaComponent(0.85))

// Top-right: date
let dateFmt = DateFormatter()
dateFmt.dateStyle = .long
dateFmt.locale = Locale(identifier: "fr_FR")
let displayDate: String = {
    if let d = ISO8601DateFormatter().date(from: purchaseDate + "T00:00:00Z") {
        return dateFmt.string(from: d)
    }
    return purchaseDate
}()
drawText(displayDate,
         at: CGPoint(x: page.width - margin - 200, y: page.height - 58),
         font: .systemFont(ofSize: 11, weight: .medium),
         color: .white,
         maxWidth: 200, alignment: .right)
drawText("www.misiraca.com",
         at: CGPoint(x: page.width - margin - 200, y: page.height - 72),
         font: .systemFont(ofSize: 10),
         color: NSColor.white.withAlphaComponent(0.85),
         maxWidth: 200, alignment: .right)

// ─────────────────────────────────────────────────────────────────────
// 2. Greeting
// ─────────────────────────────────────────────────────────────────────

var cursorY: CGFloat = page.height - headerHeight - 36

drawText("Merci pour votre achat, \(name) !",
         at: CGPoint(x: margin, y: cursorY),
         font: .systemFont(ofSize: 18, weight: .bold),
         color: textPrimary,
         maxWidth: page.width - 2*margin)
cursorY -= 26

drawText("Voici votre licence et tout ce qu'il faut pour démarrer en 30 secondes.",
         at: CGPoint(x: margin, y: cursorY),
         font: .systemFont(ofSize: 12),
         color: textSecondary,
         maxWidth: page.width - 2*margin)
cursorY -= 32

// ─────────────────────────────────────────────────────────────────────
// 3. License card (the hero)
// ─────────────────────────────────────────────────────────────────────

let licenseCardHeight: CGFloat = 110
let licenseCardRect = CGRect(x: margin, y: cursorY - licenseCardHeight,
                              width: page.width - 2*margin, height: licenseCardHeight)
linearGradient(
    in: licenseCardRect,
    colors: [
        NSColor(red: 0.12, green: 0.18, blue: 0.30, alpha: 1).cgColor,
        NSColor(red: 0.07, green: 0.10, blue: 0.20, alpha: 1).cgColor
    ],
    locations: [0, 1],
    from: CGPoint(x: 0, y: 1), to: CGPoint(x: 1, y: 0),
    cornerRadius: 12
)

drawText("VOTRE LICENCE",
         at: CGPoint(x: margin + 20, y: licenseCardRect.maxY - 22),
         font: .systemFont(ofSize: 9, weight: .semibold),
         color: NSColor(red: 0.20, green: 0.92, blue: 1.00, alpha: 1))

drawText("Email d'achat",
         at: CGPoint(x: margin + 20, y: licenseCardRect.maxY - 44),
         font: .systemFont(ofSize: 9, weight: .semibold),
         color: NSColor.white.withAlphaComponent(0.55))
drawText(email,
         at: CGPoint(x: margin + 20, y: licenseCardRect.maxY - 60),
         font: NSFont.monospacedSystemFont(ofSize: 12, weight: .medium),
         color: .white)

drawText("Clé de licence",
         at: CGPoint(x: margin + 20, y: licenseCardRect.minY + 32),
         font: .systemFont(ofSize: 9, weight: .semibold),
         color: NSColor.white.withAlphaComponent(0.55))
drawText(key,
         at: CGPoint(x: margin + 20, y: licenseCardRect.minY + 12),
         font: NSFont.monospacedSystemFont(ofSize: 16, weight: .bold),
         color: NSColor(red: 0.20, green: 0.92, blue: 1.00, alpha: 1))

cursorY = licenseCardRect.minY - 24

// ─────────────────────────────────────────────────────────────────────
// 4. Installation steps
// ─────────────────────────────────────────────────────────────────────

drawText("INSTALLATION EN 30 SECONDES",
         at: CGPoint(x: margin, y: cursorY),
         font: .systemFont(ofSize: 10, weight: .bold),
         color: textPrimary)
cursorY -= 18

let steps: [(String, String)] = [
    ("Téléchargez",  "misiraca.com/misicopy/download — fichier MisiCopy-1.0.dmg"),
    ("Glissez",      "Faites glisser l'icône dans le dossier Applications"),
    ("Lancez",       "Ouvrez MisiCopy depuis Applications ou Launchpad"),
    ("Réglages ⌘,",  "Ouvrez les Réglages puis l'onglet « Licence »"),
    ("Activez",      "Collez votre email + clé puis cliquez Activer. Terminé.")
]

for (i, step) in steps.enumerated() {
    let y = cursorY - CGFloat(i) * 32
    // Numbered bubble
    let bubble = CGRect(x: margin, y: y - 22, width: 22, height: 22)
    roundedRect(bubble, radius: 11, fill: brand)
    drawCenteredText("\(i+1)", in: bubble,
                     font: .systemFont(ofSize: 11, weight: .bold),
                     color: .white)
    // Title + subtitle
    drawText(step.0,
             at: CGPoint(x: margin + 34, y: y - 12),
             font: .systemFont(ofSize: 12, weight: .semibold),
             color: textPrimary)
    drawText(step.1,
             at: CGPoint(x: margin + 34, y: y - 24),
             font: .systemFont(ofSize: 10),
             color: textSecondary,
             maxWidth: page.width - 2*margin - 34)
}
cursorY -= CGFloat(steps.count) * 32 + 12

// ─────────────────────────────────────────────────────────────────────
// 5. Bottom bar: 2 machines + shortcut + support
// ─────────────────────────────────────────────────────────────────────

let barHeight: CGFloat = 80
let barRect = CGRect(x: margin, y: cursorY - barHeight,
                     width: page.width - 2*margin, height: barHeight)
roundedRect(barRect, radius: 10, fill: cardBackground, stroke: cardBorder)

let colW = barRect.width / 3
let cols: [(String, String, String)] = [
    ("2",  "2 postes",
     "Réinstallez sur un autre Mac avec le même email + clé"),
    ("⌘",  "Raccourcis",
     "⌘R Lancer · ⌘P Pause · ⌘E Exporter MHL · ⌘, Réglages"),
    ("@",  "Support",
     "misicopy@misiraca.com — réponse sous 24h")
]
for (i, col) in cols.enumerated() {
    let x = barRect.minX + CGFloat(i) * colW + 14
    let y = barRect.maxY - 14
    // Round badge with brand color and large glyph
    let badge = CGRect(x: x, y: y - 22, width: 22, height: 22)
    roundedRect(badge, radius: 11, fill: brand.withAlphaComponent(0.12))
    drawCenteredText(col.0, in: badge,
                     font: .systemFont(ofSize: 13, weight: .bold),
                     color: brand)
    drawText(col.1,
             at: CGPoint(x: x + 32, y: y - 12),
             font: .systemFont(ofSize: 11, weight: .bold),
             color: textPrimary)
    drawText(col.2,
             at: CGPoint(x: x + 32, y: y - 30),
             font: .systemFont(ofSize: 9),
             color: textSecondary,
             maxWidth: colW - 46)
    if i > 0 {
        ctx.saveGState()
        ctx.setStrokeColor(cardBorder.cgColor)
        ctx.setLineWidth(0.5)
        ctx.move(to: CGPoint(x: barRect.minX + CGFloat(i)*colW, y: barRect.minY + 14))
        ctx.addLine(to: CGPoint(x: barRect.minX + CGFloat(i)*colW, y: barRect.maxY - 14))
        ctx.strokePath()
        ctx.restoreGState()
    }
}
cursorY = barRect.minY - 20

// ─────────────────────────────────────────────────────────────────────
// 6. Footer
// ─────────────────────────────────────────────────────────────────────

drawCenteredText("MisiCopy © 2026 Matthieu Misiraca — misiraca.com — Bons tournages.",
                 in: CGRect(x: 0, y: 24, width: page.width, height: 12),
                 font: .systemFont(ofSize: 8),
                 color: textSecondary)

// ─────────────────────────────────────────────────────────────────────
// Finalise
// ─────────────────────────────────────────────────────────────────────

NSGraphicsContext.restoreGraphicsState()
ctx.endPDFPage()
ctx.closePDF()

print("✅ PDF généré : \(outURL.path)")
