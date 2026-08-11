//
//  MHLVerifier.swift
//  MisiCopy
//
//  Parses an MHL file and re-computes each file's checksum to detect
//  bit-rot, missing files, or accidental modification.
//

import Foundation

struct MHLEntry: Hashable {
    let relativePath: String
    let size: Int64
    let algorithm: ChecksumAlgorithm
    let expectedHash: String
}

enum MHLVerificationStatus: Hashable {
    case match
    case mismatch(found: String)
    case missing
    case readError(String)
}

struct MHLVerificationResult: Hashable {
    let entry: MHLEntry
    let status: MHLVerificationStatus
}

enum MHLVerifierError: Error {
    case unreadable
    case malformed
}

struct MHLVerifier {

    /// Parses an MHL file and returns the list of entries.
    nonisolated static func parse(_ url: URL) throws -> [MHLEntry] {
        guard let data = try? Data(contentsOf: url) else {
            throw MHLVerifierError.unreadable
        }
        let parser = XMLParser(data: data)
        let handler = MHLParseHandler()
        parser.delegate = handler
        guard parser.parse() else { throw MHLVerifierError.malformed }
        return handler.entries
    }

    /// Verifies a single entry by recomputing the checksum from `root`.
    nonisolated static func verify(
        entry: MHLEntry,
        in root: URL
    ) async -> MHLVerificationResult {
        let fileURL = root.appending(path: entry.relativePath)
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            return MHLVerificationResult(entry: entry, status: .missing)
        }
        do {
            let hash = try await ChecksumCalculator.checksum(for: fileURL, algorithm: entry.algorithm)
            if hash.lowercased() == entry.expectedHash.lowercased() {
                return MHLVerificationResult(entry: entry, status: .match)
            }
            return MHLVerificationResult(entry: entry, status: .mismatch(found: hash))
        } catch {
            return MHLVerificationResult(entry: entry,
                                         status: .readError(error.localizedDescription))
        }
    }
}

// MARK: - XML parsing

private final class MHLParseHandler: NSObject, XMLParserDelegate {
    var entries: [MHLEntry] = []

    private var currentElement: String = ""
    private var buffer: String = ""
    private var currentFile: String?
    private var currentSize: Int64 = 0
    private var currentAlgorithm: ChecksumAlgorithm?
    private var currentHash: String?
    private var inHashElement = false

    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?,
                attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName.lowercased()
        buffer = ""
        if currentElement == "hash" {
            currentFile = nil
            currentSize = 0
            currentAlgorithm = nil
            currentHash = nil
            inHashElement = true
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        buffer += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?) {
        let name = elementName.lowercased()
        let trimmed = buffer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard inHashElement else {
            if name == "hash" { inHashElement = false }
            return
        }
        switch name {
        case "file": currentFile = trimmed
        case "size": currentSize = Int64(trimmed) ?? 0
        case "xxhash64":
            currentAlgorithm = .xxhash64
            currentHash = trimmed
        case "md5":
            currentAlgorithm = .md5
            currentHash = trimmed
        case "sha1":
            currentAlgorithm = .sha1
            currentHash = trimmed
        case "sha256":
            currentAlgorithm = .sha256
            currentHash = trimmed
        case "hash":
            if let file = currentFile, let algo = currentAlgorithm, let hash = currentHash {
                entries.append(MHLEntry(relativePath: file,
                                        size: currentSize,
                                        algorithm: algo,
                                        expectedHash: hash))
            }
            inHashElement = false
        default: break
        }
        buffer = ""
    }
}
