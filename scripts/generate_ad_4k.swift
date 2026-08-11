#!/usr/bin/env swift
//
//  generate_ad_4k.swift
//  Renders marketing/MisiCopy-Ad-4K.png — a 3840×2160 advertising
//  background (website hero / display ad) in the MisiCopy brand style:
//  deep navy → indigo gradient, cyan data-stream curves, faint checksum
//  hex texture, the app logo and the slogan.
//
//  Run from project root:  swift scripts/generate_ad_4k.swift
//

import AppKit
import CoreGraphics

let W: CGFloat = 3840
let H: CGFloat = 2160

let projectDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let logoURL = projectDir.appending(path: "marketing/logo-misicopy-1024.png")
let outURL = projectDir.appending(path: "marketing/MisiCopy-Ad-4K.png")

// Deterministic pseudo-random so the artwork is reproducible.
var rngState: UInt64 = 0x4D697369  // "Misi"
func rnd() -> CGFloat {
    rngState = rngState &* 6364136223846793005 &+ 1442695040888963407
    return CGFloat((rngState >> 33) & 0xFFFFFF) / CGFloat(0xFFFFFF)
}

let cs = CGColorSpaceCreateDeviceRGB()
guard let ctx = CGContext(data: nil, width: Int(W), height: Int(H),
                          bitsPerComponent: 8, bytesPerRow: 0,
                          space: cs,
                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
else { fatalError("CGContext failed") }

NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)

// ─────────────────────────────────────────────────────────────────────
// 1. Background — deep navy to brand indigo, vertical
// ─────────────────────────────────────────────────────────────────────
let bg = CGGradient(colorsSpace: cs, colors: [
    CGColor(red: 0.030, green: 0.045, blue: 0.140, alpha: 1),   // deep navy (top)
    CGColor(red: 0.060, green: 0.090, blue: 0.280, alpha: 1),
    CGColor(red: 0.110, green: 0.130, blue: 0.420, alpha: 1)    // indigo (bottom)
] as CFArray, locations: [0, 0.55, 1])!
ctx.drawLinearGradient(bg, start: CGPoint(x: 0, y: H), end: CGPoint(x: 0, y: 0), options: [])

// Radial brand-blue glow behind the text block (upper-center-left)
func glow(at center: CGPoint, radius: CGFloat, color: CGColor) {
    let g = CGGradient(colorsSpace: cs, colors: [
        color,
        color.copy(alpha: 0)!
    ] as CFArray, locations: [0, 1])!
    ctx.drawRadialGradient(g, startCenter: center, startRadius: 0,
                           endCenter: center, endRadius: radius, options: [])
}
glow(at: CGPoint(x: W * 0.38, y: H * 0.60), radius: 1500,
     color: CGColor(red: 0.18, green: 0.55, blue: 1.00, alpha: 0.22))
glow(at: CGPoint(x: W * 0.88, y: H * 0.18), radius: 1100,
     color: CGColor(red: 0.20, green: 0.92, blue: 1.00, alpha: 0.10))
glow(at: CGPoint(x: W * 0.10, y: H * 0.08), radius: 900,
     color: CGColor(red: 0.28, green: 0.32, blue: 0.96, alpha: 0.18))

// ─────────────────────────────────────────────────────────────────────
// 2. Faint checksum hex texture — rows of monospaced hex, some cyan
// ─────────────────────────────────────────────────────────────────────
let hexChars = Array("0123456789abcdef")
func hexString(_ n: Int) -> String {
    String((0..<n).map { _ in hexChars[Int(rnd() * 15.99)] })
}
let monoFont = NSFont.monospacedSystemFont(ofSize: 34, weight: .medium)
for row in 0..<26 {
    let y = CGFloat(row) * (H / 25.0) - 20
    var x: CGFloat = -CGFloat(rnd() * 300)
    while x < W {
        let len = 8 + Int(rnd() * 8)
        let s = hexString(len)
        let highlighted = rnd() > 0.93
        let alpha: CGFloat = highlighted ? 0.20 : 0.030 + rnd() * 0.035
        let color = highlighted
            ? NSColor(red: 0.20, green: 0.92, blue: 1.00, alpha: alpha)
            : NSColor(white: 1.0, alpha: alpha)
        let attr = NSAttributedString(string: s, attributes: [
            .font: monoFont, .foregroundColor: color, .kern: 6
        ])
        attr.draw(at: CGPoint(x: x, y: y))
        x += attr.size().width + 90 + rnd() * 140
    }
}

// ─────────────────────────────────────────────────────────────────────
// 3. Data-stream curves — glowing bezier flows crossing the frame
// ─────────────────────────────────────────────────────────────────────
func stream(from a: CGPoint, control1: CGPoint, control2: CGPoint, to b: CGPoint,
            width: CGFloat, color: CGColor, glowPass: Bool) {
    let path = CGMutablePath()
    path.move(to: a)
    path.addCurve(to: b, control1: control1, control2: control2)
    if glowPass {
        ctx.setShadow(offset: .zero, blur: 60,
                      color: color.copy(alpha: 0.9))
    } else {
        ctx.setShadow(offset: .zero, blur: 0, color: nil)
    }
    ctx.addPath(path)
    ctx.setStrokeColor(color)
    ctx.setLineWidth(width)
    ctx.setLineCap(.round)
    ctx.strokePath()
    ctx.setShadow(offset: .zero, blur: 0, color: nil)
}

let cyan = CGColor(red: 0.20, green: 0.92, blue: 1.00, alpha: 1)
let blue = CGColor(red: 0.18, green: 0.55, blue: 1.00, alpha: 1)
let green = CGColor(red: 0.30, green: 0.95, blue: 0.45, alpha: 1)

// Wide soft ribbons (background depth)
for i in 0..<5 {
    let t = CGFloat(i) / 4.0
    let y0 = H * (0.06 + 0.16 * t) + rnd() * 60
    let y1 = H * (0.30 + 0.55 * t) + rnd() * 80
    stream(from: CGPoint(x: -100, y: y0),
           control1: CGPoint(x: W * 0.35, y: y0 + 400 * (rnd() - 0.3)),
           control2: CGPoint(x: W * 0.65, y: y1 - 400 * (rnd() - 0.3)),
           to: CGPoint(x: W + 100, y: y1),
           width: 2 + rnd() * 2.5,
           color: (i % 2 == 0 ? blue : cyan).copy(alpha: 0.10 + rnd() * 0.08)!,
           glowPass: false)
}
// Two hero streams with glow
stream(from: CGPoint(x: -100, y: H * 0.14),
       control1: CGPoint(x: W * 0.30, y: H * 0.42),
       control2: CGPoint(x: W * 0.62, y: H * 0.02),
       to: CGPoint(x: W + 100, y: H * 0.30),
       width: 5, color: cyan.copy(alpha: 0.55)!, glowPass: true)
stream(from: CGPoint(x: -100, y: H * 0.05),
       control1: CGPoint(x: W * 0.42, y: H * 0.30),
       control2: CGPoint(x: W * 0.70, y: H * -0.05),
       to: CGPoint(x: W + 100, y: H * 0.20),
       width: 3.5, color: blue.copy(alpha: 0.45)!, glowPass: true)

// Particles travelling along the bottom-right area
for _ in 0..<130 {
    let x = rnd() * W
    let y = rnd() * H
    let r: CGFloat = 2 + rnd() * 6
    let isCyan = rnd() > 0.4
    let a = 0.05 + rnd() * 0.30
    ctx.setFillColor((isCyan ? cyan : blue).copy(alpha: a)!)
    ctx.fillEllipse(in: CGRect(x: x, y: y, width: r, height: r))
}

// ─────────────────────────────────────────────────────────────────────
// 4. Right-side motif — source card → stream → verified shield
// ─────────────────────────────────────────────────────────────────────
func roundedRect(_ rect: CGRect, radius: CGFloat, fill: CGColor?, stroke: CGColor?, lineWidth: CGFloat = 3) {
    let p = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
    if let fill {
        ctx.addPath(p); ctx.setFillColor(fill); ctx.fillPath()
    }
    if let stroke {
        ctx.addPath(p); ctx.setStrokeColor(stroke); ctx.setLineWidth(lineWidth); ctx.strokePath()
    }
}

// SD card silhouette (outlined, ghost style) — right side, mid-height
let cardOrigin = CGPoint(x: W * 0.685, y: H * 0.36)
let cardSize = CGSize(width: 380, height: 480)
do {
    ctx.saveGState()
    // card body with clipped corner
    let p = CGMutablePath()
    let o = cardOrigin, s = cardSize
    let notch: CGFloat = 90
    p.move(to: CGPoint(x: o.x + 28, y: o.y))
    p.addLine(to: CGPoint(x: o.x + s.width - 28, y: o.y))
    p.addQuadCurve(to: CGPoint(x: o.x + s.width, y: o.y + 28), control: CGPoint(x: o.x + s.width, y: o.y))
    p.addLine(to: CGPoint(x: o.x + s.width, y: o.y + s.height - notch))
    p.addLine(to: CGPoint(x: o.x + s.width - notch, y: o.y + s.height))
    p.addLine(to: CGPoint(x: o.x + 28, y: o.y + s.height))
    p.addQuadCurve(to: CGPoint(x: o.x, y: o.y + s.height - 28), control: CGPoint(x: o.x, y: o.y + s.height))
    p.addLine(to: CGPoint(x: o.x, y: o.y + 28))
    p.addQuadCurve(to: CGPoint(x: o.x + 28, y: o.y), control: CGPoint(x: o.x, y: o.y))
    p.closeSubpath()
    ctx.addPath(p)
    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.05))
    ctx.fillPath()
    ctx.setShadow(offset: .zero, blur: 40, color: cyan.copy(alpha: 0.5))
    ctx.addPath(p)
    ctx.setStrokeColor(cyan.copy(alpha: 0.75)!)
    ctx.setLineWidth(6)
    ctx.strokePath()
    ctx.setShadow(offset: .zero, blur: 0, color: nil)
    // contact pins
    for i in 0..<5 {
        let px = o.x + 55 + CGFloat(i) * 58
        roundedRect(CGRect(x: px, y: o.y + s.height - 64 - (CGFloat(i) == 4 ? 0 : 0), width: 30, height: 52),
                    radius: 8, fill: cyan.copy(alpha: 0.35), stroke: nil)
    }
    // "4K" label on the card
    let lbl = NSAttributedString(string: "RUSHS", attributes: [
        .font: NSFont.systemFont(ofSize: 64, weight: .heavy),
        .foregroundColor: NSColor(red: 1, green: 1, blue: 1, alpha: 0.55),
        .kern: 8
    ])
    lbl.draw(at: CGPoint(x: o.x + 62, y: o.y + 90))
    ctx.restoreGState()
}

// Verified shield — bottom right of card, overlapping
do {
    let c = CGPoint(x: cardOrigin.x + cardSize.width + 260, y: cardOrigin.y + 40)
    let R: CGFloat = 190
    ctx.setShadow(offset: .zero, blur: 90, color: green.copy(alpha: 0.55))
    let ring = CGGradient(colorsSpace: cs, colors: [
        CGColor(red: 0.55, green: 1.00, blue: 0.45, alpha: 1),
        CGColor(red: 0.10, green: 0.78, blue: 0.30, alpha: 1)
    ] as CFArray, locations: [0, 1])!
    ctx.saveGState()
    ctx.addEllipse(in: CGRect(x: c.x - R, y: c.y - R, width: 2*R, height: 2*R))
    ctx.clip()
    ctx.drawLinearGradient(ring, start: CGPoint(x: c.x, y: c.y + R), end: CGPoint(x: c.x, y: c.y - R), options: [])
    ctx.restoreGState()
    ctx.setShadow(offset: .zero, blur: 0, color: nil)
    // white check
    ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
    ctx.setLineWidth(44)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)
    ctx.move(to: CGPoint(x: c.x - 78, y: c.y + 2))
    ctx.addLine(to: CGPoint(x: c.x - 18, y: c.y - 62))
    ctx.addLine(to: CGPoint(x: c.x + 88, y: c.y + 66))
    ctx.strokePath()
    // dotted stream card → shield
    ctx.setStrokeColor(cyan.copy(alpha: 0.8)!)
    ctx.setLineWidth(8)
    ctx.setLineDash(phase: 0, lengths: [2, 34])
    ctx.setLineCap(.round)
    let sp = CGMutablePath()
    sp.move(to: CGPoint(x: cardOrigin.x + cardSize.width - 30, y: cardOrigin.y + 60))
    sp.addQuadCurve(to: CGPoint(x: c.x - R - 24, y: c.y),
                    control: CGPoint(x: cardOrigin.x + cardSize.width + 110, y: cardOrigin.y - 40))
    ctx.addPath(sp)
    ctx.strokePath()
    ctx.setLineDash(phase: 0, lengths: [])
}

// ─────────────────────────────────────────────────────────────────────
// 5. Logo + wordmark + slogan (left block)
// ─────────────────────────────────────────────────────────────────────
let textX: CGFloat = W * 0.075

// Logo
if let logo = NSImage(contentsOf: logoURL),
   let logoCG = logo.cgImage(forProposedRect: nil, context: nil, hints: nil) {
    let logoSide: CGFloat = 330
    let logoRect = CGRect(x: textX, y: H * 0.66, width: logoSide, height: logoSide)
    ctx.setShadow(offset: CGSize(width: 0, height: -14), blur: 60,
                  color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.45))
    ctx.draw(logoCG, in: logoRect)
    ctx.setShadow(offset: .zero, blur: 0, color: nil)

    // Wordmark next to logo
    let name = NSAttributedString(string: "MisiCopy", attributes: [
        .font: NSFont.systemFont(ofSize: 170, weight: .heavy),
        .foregroundColor: NSColor.white,
        .kern: 1
    ])
    name.draw(at: CGPoint(x: logoRect.maxX + 70, y: H * 0.685))
    let tagline = NSAttributedString(string: "COPIE SÉCURISÉE PROFESSIONNELLE · MAC", attributes: [
        .font: NSFont.systemFont(ofSize: 44, weight: .semibold),
        .foregroundColor: NSColor(red: 0.20, green: 0.92, blue: 1.00, alpha: 0.95),
        .kern: 10
    ])
    tagline.draw(at: CGPoint(x: logoRect.maxX + 78, y: H * 0.645))
}

// Slogan — three punch words, three colors
do {
    let y = H * 0.42
    let fontBig = NSFont.systemFont(ofSize: 230, weight: .black)
    var x = textX
    let words: [(String, NSColor)] = [
        ("Copié. ", .white),
        ("Vérifié. ", NSColor(red: 0.20, green: 0.92, blue: 1.00, alpha: 1)),
        ("Certifié.", NSColor(red: 0.45, green: 0.98, blue: 0.55, alpha: 1))
    ]
    ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 50,
                  color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.5))
    for (word, color) in words {
        let a = NSAttributedString(string: word, attributes: [
            .font: fontBig, .foregroundColor: color, .kern: -2
        ])
        a.draw(at: CGPoint(x: x, y: y))
        x += a.size().width
    }
    ctx.setShadow(offset: .zero, blur: 0, color: nil)

    // Sub-slogan
    let sub = NSAttributedString(
        string: "Vos rushs copiés et vérifiés octet par octet — checksum xxHash3, rapports PDF & MHL.",
        attributes: [
            .font: NSFont.systemFont(ofSize: 62, weight: .medium),
            .foregroundColor: NSColor(white: 1, alpha: 0.85),
            .kern: 0.5
        ])
    sub.draw(at: CGPoint(x: textX + 6, y: y - 130))
}

// Bottom bar: site + platform pill
do {
    let site = NSAttributedString(string: "misicopy.com", attributes: [
        .font: NSFont.systemFont(ofSize: 70, weight: .bold),
        .foregroundColor: NSColor.white,
        .kern: 2
    ])
    site.draw(at: CGPoint(x: textX + 6, y: H * 0.11))

    let pillText = NSAttributedString(string: "TÉLÉCHARGEMENT GRATUIT", attributes: [
        .font: NSFont.systemFont(ofSize: 44, weight: .heavy),
        .foregroundColor: NSColor(red: 0.03, green: 0.08, blue: 0.25, alpha: 1),
        .kern: 6
    ])
    let tw = pillText.size().width
    let pillRect = CGRect(x: textX + site.size().width + 120, y: H * 0.105,
                          width: tw + 120, height: 108)
    let pillGrad = CGGradient(colorsSpace: cs, colors: [cyan, blue] as CFArray, locations: [0, 1])!
    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: 50, color: cyan.copy(alpha: 0.5))
    ctx.addPath(CGPath(roundedRect: pillRect, cornerWidth: 54, cornerHeight: 54, transform: nil))
    ctx.clip()
    ctx.drawLinearGradient(pillGrad,
                           start: CGPoint(x: pillRect.minX, y: pillRect.midY),
                           end: CGPoint(x: pillRect.maxX, y: pillRect.midY), options: [])
    ctx.restoreGState()
    ctx.setShadow(offset: .zero, blur: 0, color: nil)
    pillText.draw(at: CGPoint(x: pillRect.minX + 60, y: pillRect.minY + 28))
}

// Subtle vignette so website content pops on top
do {
    let v = CGGradient(colorsSpace: cs, colors: [
        CGColor(red: 0, green: 0, blue: 0, alpha: 0.0),
        CGColor(red: 0, green: 0, blue: 0, alpha: 0.35)
    ] as CFArray, locations: [0.55, 1])!
    ctx.drawRadialGradient(v, startCenter: CGPoint(x: W/2, y: H/2), startRadius: H * 0.4,
                           endCenter: CGPoint(x: W/2, y: H/2), endRadius: W * 0.75, options: [])
}

// ─────────────────────────────────────────────────────────────────────
// Save PNG
// ─────────────────────────────────────────────────────────────────────
guard let image = ctx.makeImage() else { fatalError("makeImage failed") }
let rep = NSBitmapImageRep(cgImage: image)
guard let png = rep.representation(using: .png, properties: [:]) else { fatalError("png failed") }
try png.write(to: outURL)
print("✅ 4K ad generated: \(outURL.path) (\(png.count / 1024) KB)")
