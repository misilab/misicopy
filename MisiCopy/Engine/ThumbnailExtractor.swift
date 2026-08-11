//
//  ThumbnailExtractor.swift
//  MisiCopy
//
//  Extracts a representative first-frame thumbnail from common video
//  files via AVFoundation. Returns nil for formats AVFoundation cannot
//  decode (R3D, BRAW, NEV, ARI…) — the PDF renderer then draws a
//  branded placeholder instead of a generic Finder icon.
//

import Foundation
import AVFoundation
import CoreGraphics
import AppKit

enum ThumbnailExtractor {

    /// Formats that AVFoundation can natively decode. Camera-RAW formats
    /// (RED R3D, Blackmagic BRAW, Nikon NEV, ARRI .ari) require vendor
    /// SDKs we don't ship, so we skip extraction for those.
    nonisolated static func canExtract(_ format: CameraFormat, ext: String) -> Bool {
        let raw: Set<String> = ["r3d", "braw", "nev", "ari", "crm"]
        if raw.contains(ext.lowercased()) { return false }
        switch format {
        case .red, .braw, .canon: return false
        default: return true
        }
    }

    nonisolated static func thumbnail(for url: URL, maxDimension: CGFloat = 256) -> CGImage? {
        let ext = url.pathExtension.lowercased()
        let format = CameraFormatDetector.detect(at: url)
        guard canExtract(format, ext: ext) else { return nil }
        return avThumbnail(url: url, maxDimension: maxDimension)
    }

    private nonisolated static func avThumbnail(url: URL, maxDimension: CGFloat) -> CGImage? {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: maxDimension * 2, height: maxDimension * 2)
        let times = [0.0, 0.5, 1.0]
        for seconds in times {
            let time = CMTime(seconds: seconds, preferredTimescale: 600)
            if let cg = try? generator.copyCGImage(at: time, actualTime: nil) {
                return cg
            }
        }
        return nil
    }
}

// MARK: - Brand colors for placeholder thumbnails

extension CameraFormat {
    /// Returns brand-accurate colors for the placeholder card shown in
    /// the PDF when no real thumbnail can be extracted.
    var brandColors: (top: CGColor, bottom: CGColor) {
        switch self {
        case .red:
            return (CGColor(red: 0.95, green: 0.10, blue: 0.10, alpha: 1),
                    CGColor(red: 0.70, green: 0.04, blue: 0.04, alpha: 1))
        case .braw:
            return (CGColor(red: 0.99, green: 0.55, blue: 0.05, alpha: 1),
                    CGColor(red: 0.85, green: 0.35, blue: 0.02, alpha: 1))
        case .arri:
            return (CGColor(red: 0.00, green: 0.30, blue: 0.55, alpha: 1),
                    CGColor(red: 0.00, green: 0.18, blue: 0.38, alpha: 1))
        case .sony:
            return (CGColor(red: 0.15, green: 0.15, blue: 0.18, alpha: 1),
                    CGColor(red: 0.05, green: 0.05, blue: 0.08, alpha: 1))
        case .canon:
            return (CGColor(red: 0.85, green: 0.07, blue: 0.07, alpha: 1),
                    CGColor(red: 0.55, green: 0.03, blue: 0.03, alpha: 1))
        case .dji:
            return (CGColor(red: 0.20, green: 0.20, blue: 0.22, alpha: 1),
                    CGColor(red: 0.05, green: 0.05, blue: 0.07, alpha: 1))
        case .prores:
            return (CGColor(red: 0.60, green: 0.60, blue: 0.65, alpha: 1),
                    CGColor(red: 0.35, green: 0.35, blue: 0.40, alpha: 1))
        case .mxf, .mov, .unknown:
            return (CGColor(red: 0.35, green: 0.40, blue: 0.50, alpha: 1),
                    CGColor(red: 0.20, green: 0.25, blue: 0.35, alpha: 1))
        }
    }
}
