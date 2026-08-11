//
//  QRCodeGenerator.swift
//  MisiCopy
//
//  Tiny CoreImage wrapper that produces a crisp NSImage QR code for the
//  pairing flow. CIQRCodeGenerator does the heavy lifting — we add a nearest-
//  neighbour scale + a quiet-zone margin so the resulting image stays sharp
//  in SwiftUI at any zoom level.
//

import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins
import AppKit

enum QRCodeGenerator {

    /// Renders `string` into a black-on-white QR code at the requested
    /// output side (in points). Returns nil if the data exceeds the QR
    /// capacity at the requested error correction level.
    static func image(for string: String, side: CGFloat = 240) -> NSImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M" // ~15% recoverable

        guard let output = filter.outputImage else { return nil }
        let scale = max(1, side / output.extent.width)
        let scaled = output.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        let context = CIContext(options: [.useSoftwareRenderer: false])
        guard let cg = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        let nsImage = NSImage(cgImage: cg, size: NSSize(width: side, height: side))
        return nsImage
    }
}
