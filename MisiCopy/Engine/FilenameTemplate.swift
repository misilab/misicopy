//
//  FilenameTemplate.swift
//  MisiCopy
//
//  Token-based filename renamer for DIT workflows.
//
//  Supported tokens (case-insensitive):
//    {filename}  — original name without extension
//    {ext}       — original extension (no leading dot)
//    {source}    — last path component of the source root
//    {camera}    — detected camera brand short badge (RED, BRAW, ARRI…)
//    {date}      — YYYY-MM-DD of the copy start
//    {time}      — HH-MM-SS of the copy start
//    {year} {month} {day}
//    {hour} {minute} {second}
//    {counter}   — 1-based incrementing index (per session)
//    {counter:NN} — padded counter, e.g. {counter:04} → 0001
//
//  Empty template = original filename is preserved.
//

import Foundation

struct FilenameTemplate {
    let raw: String
    var isEnabled: Bool { !raw.trimmingCharacters(in: .whitespaces).isEmpty }

    /// Counter regex compiled once and reused across all `apply()` calls
    /// (called for every file copied).
    private static let counterRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: #"\{counter:?(\d*)\}"#,
                                 options: .caseInsensitive)
    }()

    nonisolated func apply(
        to item: FileItem,
        counter: Int,
        sessionStart: Date
    ) -> String {
        guard isEnabled else { return item.displayName }

        let original = (item.displayName as NSString).deletingPathExtension
        let ext = (item.displayName as NSString).pathExtension

        let dateFmt = DateFormatter()
        dateFmt.dateFormat = "yyyy-MM-dd"
        let timeFmt = DateFormatter()
        timeFmt.dateFormat = "HH-mm-ss"
        let yearFmt = DateFormatter(); yearFmt.dateFormat = "yyyy"
        let monthFmt = DateFormatter(); monthFmt.dateFormat = "MM"
        let dayFmt = DateFormatter(); dayFmt.dateFormat = "dd"
        let hourFmt = DateFormatter(); hourFmt.dateFormat = "HH"
        let minFmt = DateFormatter(); minFmt.dateFormat = "mm"
        let secFmt = DateFormatter(); secFmt.dateFormat = "ss"

        var result = raw
        let replacements: [String: String] = [
            "{filename}": original,
            "{ext}":      ext,
            "{source}":   item.sourceRootName,
            "{camera}":   item.cameraFormat.shortBadge.isEmpty
                          ? "RAW" : item.cameraFormat.shortBadge,
            "{date}":     dateFmt.string(from: sessionStart),
            "{time}":     timeFmt.string(from: sessionStart),
            "{year}":     yearFmt.string(from: sessionStart),
            "{month}":    monthFmt.string(from: sessionStart),
            "{day}":      dayFmt.string(from: sessionStart),
            "{hour}":     hourFmt.string(from: sessionStart),
            "{minute}":   minFmt.string(from: sessionStart),
            "{second}":   secFmt.string(from: sessionStart)
        ]
        for (key, value) in replacements {
            result = result.replacingOccurrences(of: key, with: value, options: .caseInsensitive)
        }

        // Padded counter: {counter:NN}
        if let regex = Self.counterRegex {
            let ns = result as NSString
            let matches = regex.matches(in: result, range: NSRange(location: 0, length: ns.length))
            for match in matches.reversed() {
                let widthRange = match.range(at: 1)
                let widthStr = widthRange.location == NSNotFound
                    ? "" : ns.substring(with: widthRange)
                let width = Int(widthStr) ?? 0
                let formatted = width > 0
                    ? String(format: "%0\(width)d", counter)
                    : "\(counter)"
                result = ns.replacingCharacters(in: match.range, with: formatted)
            }
        }

        // Ensure extension is present (if user template didn't include one).
        let resultExt = (result as NSString).pathExtension
        if resultExt.isEmpty && !ext.isEmpty {
            result += ".\(ext)"
        }

        // Sanitize: replace illegal path chars.
        let illegal: Set<Character> = ["/", "\\", ":", "*", "?", "\"", "<", ">", "|"]
        result = String(result.map { illegal.contains($0) ? "_" : $0 })
        return result
    }
}
