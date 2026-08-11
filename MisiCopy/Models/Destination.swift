//
//  Destination.swift
//  MisiCopy
//

import Foundation

struct Destination: Identifiable, Hashable {
    let id = UUID()
    var url: URL
    /// Cascade destinations are NOT written from the source card: they
    /// are fed from the first non-cascade destination once the primary
    /// copy is fully verified. The card is released (and auto-ejected)
    /// at the end of the primary phase, while slow backup drives fill
    /// up afterwards.
    var isCascade: Bool = false

    var displayName: String { url.lastPathComponent }
    var path: String { url.path(percentEncoded: false) }
}

/// DIT-standard camera tag for a source. Determines which `*_CAM` folder
/// it lands in when the DIT folder structure is active.
enum CameraTag: String, Hashable, CaseIterable, Codable {
    case a, b, c, d, son, autre

    /// Folder name written under `01_RUSHES/<date>/`.
    var folderName: String {
        switch self {
        case .a:     return "A_CAM"
        case .b:     return "B_CAM"
        case .c:     return "C_CAM"
        case .d:     return "D_CAM"
        case .son:   return "SON"
        case .autre: return "AUTRE"
        }
    }

    var shortLabel: String {
        switch self {
        case .a:     return "A"
        case .b:     return "B"
        case .c:     return "C"
        case .d:     return "D"
        case .son:   return "SON"
        case .autre: return "AUTRE"
        }
    }
}

/// Summary of the most recent successful offload of a volume, matched
/// from the session history when a card is (re)inserted. Lets the UI
/// warn "this card was already offloaded yesterday" before the user
/// copies it twice — or formats it believing it was never dumped.
struct PreviousOffload: Hashable {
    let date: Date
    let files: Int
    let bytes: Int64
}

struct Source: Identifiable, Hashable {
    let id = UUID()
    var url: URL
    /// Cached at add-time: the volume root that owns `url`. Used for eject.
    var volumeURL: URL? = nil
    /// True if the underlying volume can be ejected by the user (SD card,
    /// USB stick, external SSD/HDD, optical media…).
    var isEjectable: Bool = false
    /// True only for physically removable media (SD card, USB stick).
    /// Used to distinguish the auto-detection banner icon/text.
    var isRemovableMedia: Bool = false
    /// Camera tag used when the DIT folder structure is active.
    /// Auto-detected from the first clip name (A001_, B001_, …) when
    /// the source is added; user can override via the source's dropdown.
    var cameraTag: CameraTag = .a
    /// Non-nil when the history says this volume was already offloaded
    /// successfully — drives the "already offloaded" suggestion banner.
    var previousOffload: PreviousOffload? = nil

    var displayName: String { url.lastPathComponent }
    var path: String { url.path(percentEncoded: false) }
    var volumeName: String { (volumeURL ?? url).lastPathComponent }
}
