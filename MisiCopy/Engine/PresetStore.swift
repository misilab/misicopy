//
//  PresetStore.swift
//  MisiCopy
//
//  Persists user presets in Application Support / MisiCopy / presets.json.
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class PresetStore {
    private(set) var presets: [Preset] = []
    private let store = JSONFileStore(filename: "presets.json")

    init() {
        presets = store.load(as: [Preset].self) ?? []
    }

    private func persist() {
        store.save(presets)
    }

    func add(_ preset: Preset) {
        presets.append(preset)
        persist()
    }

    func update(_ preset: Preset) {
        guard let idx = presets.firstIndex(where: { $0.id == preset.id }) else { return }
        presets[idx] = preset
        persist()
    }

    func remove(_ preset: Preset) {
        presets.removeAll { $0.id == preset.id }
        persist()
    }
}
