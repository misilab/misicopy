//
//  JSONFileStore.swift
//  MisiCopy
//
//  Tiny helper that handles reading/writing a JSON-encoded Codable to
//  `~/Library/Application Support/MisiCopy/<filename>`. Used by all
//  on-disk stores (history, presets, last-session) to keep the pattern
//  in one place and surface failures via NSLog instead of `try?`.
//

import Foundation

struct JSONFileStore {
    let url: URL

    init(filename: String) {
        let support = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first ?? URL(fileURLWithPath: NSHomeDirectory())
        let dir = support.appending(path: "MisiCopy")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        url = dir.appending(path: filename)
    }

    func load<T: Decodable>(as type: T.Type) -> T? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            NSLog("MisiCopy/JSONFileStore: decode failed for %@ — %@",
                  url.lastPathComponent, error.localizedDescription)
            return nil
        }
    }

    func save<T: Encodable>(_ value: T) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        do {
            let data = try encoder.encode(value)
            try data.write(to: url, options: .atomic)
        } catch {
            NSLog("MisiCopy/JSONFileStore: save failed for %@ — %@",
                  url.lastPathComponent, error.localizedDescription)
        }
    }

    func clear() {
        do {
            try FileManager.default.removeItem(at: url)
        } catch CocoaError.fileNoSuchFile {
            // Nothing to remove — fine.
        } catch let nsError as NSError where nsError.code == NSFileNoSuchFileError {
            // Same condition, different framework.
        } catch {
            NSLog("MisiCopy/JSONFileStore: clear failed for %@ — %@",
                  url.lastPathComponent, error.localizedDescription)
        }
    }
}
