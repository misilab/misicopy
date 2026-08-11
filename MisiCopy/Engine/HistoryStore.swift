//
//  HistoryStore.swift
//  MisiCopy
//
//  Persists completed sessions in Application Support / MisiCopy / history.json
//  Newest sessions first. Capped to keep the file size sane.
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class HistoryStore {
    private(set) var records: [SessionRecord] = []
    private let store = JSONFileStore(filename: "history.json")
    private let maxRecords = 500

    init() {
        records = store.load(as: [SessionRecord].self) ?? []
    }

    private func persist() {
        store.save(records)
    }

    func append(_ record: SessionRecord) {
        records.insert(record, at: 0)
        if records.count > maxRecords { records = Array(records.prefix(maxRecords)) }
        persist()
    }

    func remove(_ id: UUID) {
        records.removeAll { $0.id == id }
        persist()
    }

    func clear() {
        records.removeAll()
        persist()
    }
}
