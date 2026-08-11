//
//  AppModel.swift
//  MisiCopy
//
//  Top-level observable container that bundles the engine, the preset
//  store and the sheet-presentation state so it can be shared between
//  the menu bar commands and the SwiftUI view hierarchy.
//

import SwiftUI

@MainActor
@Observable
final class AppModel {
    let license = LicenseManager()
    let engine: CopyEngine
    let presetStore = PresetStore()
    let remoteSync = RemoteSyncService()

    var historySheet: Bool = false
    var savePresetSheet: Bool = false
    var managePresetsSheet: Bool = false

    init() {
        let e = CopyEngine()
        e.license = license
        engine = e
        remoteSync.bind(engine: e)
    }
}
