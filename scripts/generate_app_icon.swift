#!/usr/bin/env swift
//
//  generate_app_icon.swift
//  MisiCopy
//
//  Renders all required macOS app-icon PNG sizes from the brand design
//  (gradient cyan→blue squircle + shippingbox + green check badge).
//
//  Usage: swift scripts/generate_app_icon.swift
//

import Foundation
import AppKit
import CoreGraphics

let outputFolder = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("MisiCopy/Assets.xcassets/AppIcon.appiconset")

// macOS icon set: (pixel size, filename)
let sizes: [(Int, String)] = [
    (16,   "icon_16.png"),
    (32,   "icon_16@2x.png"),
    (32,   "icon_32.png"),
    (64,   "icon_32@2x.png"),
    (128,  "icon_128.png"),
    (256,  "icon_128@2x.png"),
    (256,  "icon_256.png"),
    (512,  "icon_256@2x.png"),
    (512,  "icon_512.png"),
    (1024, "icon_512@2x.png")
]

func writePNG(_ image: NSImage, to url: URL) throws {
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let data = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "iconGen", code: 1)
    }
    try data.write(to: url)
}

func renderIcon(size: Int) -> NSImage {
    let s = CGFloat(size)
    let image = NSImage(size: NSSize(width: s, height: s))
    image.lockFocus()
    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus(); return image
    }

    let rect = CGRect(x: 0, y: 0, width: s, height: s)

    // 1. Squircle clip
    let corner = s * 0.225
    let squircle = CGPath(roundedRect: rect, cornerWidth: corner, cornerHeight: corner, transform: nil)
    ctx.saveGState()
    ctx.addPath(squircle); ctx.clip()

    // 2. Gradient background (top-leading cyan → bottom-trailing deep blue)
    let colors = [
        CGColor(red: 0.20, green: 0.92, blue: 1.00, alpha: 1.0),
        CGColor(red: 0.18, green: 0.55, blue: 1.00, alpha: 1.0),
        CGColor(red: 0.28, green: 0.32, blue: 0.96, alpha: 1.0)
    ] as CFArray
    let cs = CGColorSpaceCreateDeviceRGB()
    if let gradient = CGGradient(colorsSpace: cs, colors: colors, locations: [0, 0.55, 1]) {
        ctx.drawLinearGradient(gradient,
                               start: CGPoint(x: 0, y: s),
                               end: CGPoint(x: s, y: 0),
                               options: [])
    }

    // 3. Top shine
    let shineColors = [
        CGColor(red: 1, green: 1, blue: 1, alpha: 0.30),
        CGColor(red: 1, green: 1, blue: 1, alpha: 0.0)
    ] as CFArray
    if let shine = CGGradient(colorsSpace: cs, colors: shineColors, locations: [0, 1]) {
        ctx.drawLinearGradient(shine,
                               start: CGPoint(x: s/2, y: s),
                               end: CGPoint(x: s/2, y: s * 0.55),
                               options: [])
    }

    ctx.restoreGState()

    // 4. Inner stroke (highlight rim)
    let inset = s * 0.012
    let strokeRect = rect.insetBy(dx: inset, dy: inset)
    let strokePath = CGPath(roundedRect: strokeRect,
                            cornerWidth: corner - inset,
                            cornerHeight: corner - inset,
                            transform: nil)
    ctx.saveGState()
    ctx.setLineWidth(s * 0.012)
    ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.35))
    ctx.addPath(strokePath); ctx.strokePath()
    ctx.restoreGState()

    // 5. Shippingbox glyph (SF Symbol → drawn white)
    let glyphSize = s * 0.52
    let glyphRect = CGRect(x: (s - glyphSize) / 2,
                           y: (s - glyphSize) / 2 + s * 0.02,
                           width: glyphSize, height: glyphSize)
    let config = NSImage.SymbolConfiguration(pointSize: glyphSize, weight: .semibold)
        .applying(.init(paletteColors: [NSColor.white]))
    if let glyph = NSImage(systemSymbolName: "shippingbox.fill", accessibilityDescription: nil)?
        .withSymbolConfiguration(config) {
        // Shadow
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: -s * 0.015),
                      blur: s * 0.03,
                      color: CGColor(red: 0.05, green: 0.20, blue: 0.55, alpha: 0.55))
        glyph.draw(in: glyphRect, from: .zero, operation: .sourceOver, fraction: 1.0)
        ctx.restoreGState()
    }

    // 6. Green check badge bottom-right
    let badgeSize = s * 0.32
    let badgeRect = CGRect(x: s - badgeSize - s * 0.06,
                           y: s * 0.06,
                           width: badgeSize, height: badgeSize)

    // Drop shadow
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -s * 0.012),
                  blur: s * 0.022,
                  color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.20))
    // Green gradient circle
    let badgePath = CGPath(ellipseIn: badgeRect, transform: nil)
    ctx.addPath(badgePath); ctx.clip(using: .evenOdd)
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(badgePath); ctx.clip()
    let greenColors = [
        CGColor(red: 0.55, green: 1.00, blue: 0.45, alpha: 1.0),
        CGColor(red: 0.10, green: 0.78, blue: 0.30, alpha: 1.0)
    ] as CFArray
    if let g = CGGradient(colorsSpace: cs, colors: greenColors, locations: [0, 1]) {
        ctx.drawLinearGradient(g,
                               start: CGPoint(x: badgeRect.midX, y: badgeRect.maxY),
                               end: CGPoint(x: badgeRect.midX, y: badgeRect.minY),
                               options: [])
    }
    ctx.restoreGState()

    // Badge white ring
    ctx.saveGState()
    ctx.setLineWidth(s * 0.018)
    ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
    ctx.addPath(badgePath); ctx.strokePath()
    ctx.restoreGState()

    // Check mark
    let checkConfig = NSImage.SymbolConfiguration(pointSize: badgeSize * 0.55, weight: .heavy)
        .applying(.init(paletteColors: [NSColor.white]))
    if let check = NSImage(systemSymbolName: "checkmark", accessibilityDescription: nil)?
        .withSymbolConfiguration(checkConfig) {
        let cs2 = check.size
        let checkRect = CGRect(
            x: badgeRect.midX - cs2.width / 2,
            y: badgeRect.midY - cs2.height / 2,
            width: cs2.width, height: cs2.height
        )
        check.draw(in: checkRect, from: .zero, operation: .sourceOver, fraction: 1.0)
    }

    image.unlockFocus()
    return image
}

// ---- Generate all sizes ----

try FileManager.default.createDirectory(at: outputFolder, withIntermediateDirectories: true)

for (size, name) in sizes {
    let img = renderIcon(size: size)
    let target = outputFolder.appendingPathComponent(name)
    try writePNG(img, to: target)
    print("Wrote \(name) (\(size)×\(size))")
}

// ---- Update Contents.json with filenames ----

let contents: [String: Any] = [
    "info": ["author": "xcode", "version": 1],
    "images": [
        ["idiom": "mac", "scale": "1x", "size": "16x16",   "filename": "icon_16.png"],
        ["idiom": "mac", "scale": "2x", "size": "16x16",   "filename": "icon_16@2x.png"],
        ["idiom": "mac", "scale": "1x", "size": "32x32",   "filename": "icon_32.png"],
        ["idiom": "mac", "scale": "2x", "size": "32x32",   "filename": "icon_32@2x.png"],
        ["idiom": "mac", "scale": "1x", "size": "128x128", "filename": "icon_128.png"],
        ["idiom": "mac", "scale": "2x", "size": "128x128", "filename": "icon_128@2x.png"],
        ["idiom": "mac", "scale": "1x", "size": "256x256", "filename": "icon_256.png"],
        ["idiom": "mac", "scale": "2x", "size": "256x256", "filename": "icon_256@2x.png"],
        ["idiom": "mac", "scale": "1x", "size": "512x512", "filename": "icon_512.png"],
        ["idiom": "mac", "scale": "2x", "size": "512x512", "filename": "icon_512@2x.png"]
    ]
]
let json = try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
try json.write(to: outputFolder.appendingPathComponent("Contents.json"))
print("Wrote Contents.json")
print("✅ App icons generated at \(outputFolder.path)")
