#!/usr/bin/env swift
//
//  generate_readme_pdf.swift
//
//  Converts marketing/README-client.md to a styled PDF stored at
//  marketing/MisiCopy-Guide-utilisateur.pdf, ready to bundle in the DMG
//  or attach to emails.
//

import Foundation
import AppKit

func regexReplace(_ s: String, _ pattern: String, _ template: String,
                  _ options: NSRegularExpression.Options = []) -> String {
    guard let re = try? NSRegularExpression(pattern: pattern, options: options) else { return s }
    let ns = s as NSString
    return re.stringByReplacingMatches(in: s, range: NSRange(location: 0, length: ns.length),
                                       withTemplate: template)
}

func mdToHTML(_ md: String) -> String {
    var s = md
    s = regexReplace(s, #"(?m)^# (.*)$"#, "<h1>$1</h1>")
    s = regexReplace(s, #"(?m)^## (.*)$"#, "<h2>$1</h2>")
    s = regexReplace(s, #"(?m)^### (.*)$"#, "<h3>$1</h3>")
    s = regexReplace(s, #"(?m)^---+$"#, "<hr/>")
    s = regexReplace(s, #"\*\*([^*]+)\*\*"#, "<strong>$1</strong>")
    s = regexReplace(s, #"\*([^*]+)\*"#, "<em>$1</em>")
    s = regexReplace(s, #"`([^`]+)`"#, "<code>$1</code>")
    s = regexReplace(s, #"\[([^\]]+)\]\(([^)]+)\)"#, "<a href=\"$2\">$1</a>")

    // Block quotes
    s = regexReplace(s, #"(?m)^> (.*)$"#, "<blockquote>$1</blockquote>")

    // Tables (very light): wrap | rows | as table rows
    s = regexReplace(s, #"(?m)^\|(.+)\|$"#, "<tr><td>$1</td></tr>")
    s = regexReplace(s, #"\|"#, "</td><td>")
    s = regexReplace(s,
                     #"(<tr>(?:.*?)</tr>(?:\n<tr>(?:.*?)</tr>)*)"#,
                     "<table>$1</table>",
                     [.dotMatchesLineSeparators])
    // Drop header separator row (---|---|---)
    s = regexReplace(s, #"<tr><td>(?:\s*-+\s*</td><td>)+\s*-+\s*</td></tr>\n?"#, "")

    // Ordered list items "1. text" / "2. text"
    s = regexReplace(s, #"(?m)^\d+\. (.*)$"#, "<oli>$1</oli>")
    s = regexReplace(s, #"(<oli>(?:.*?)</oli>(?:\n<oli>(?:.*?)</oli>)*)"#,
                     "<ol>$1</ol>", [.dotMatchesLineSeparators])
    s = s.replacingOccurrences(of: "<oli>", with: "<li>")
         .replacingOccurrences(of: "</oli>", with: "</li>")

    // Unordered list items "- text"
    s = regexReplace(s, #"(?m)^- (.*)$"#, "<uli>$1</uli>")
    s = regexReplace(s, #"(<uli>(?:.*?)</uli>(?:\n<uli>(?:.*?)</uli>)*)"#,
                     "<ul>$1</ul>", [.dotMatchesLineSeparators])
    s = s.replacingOccurrences(of: "<uli>", with: "<li>")
         .replacingOccurrences(of: "</uli>", with: "</li>")

    // Paragraph breaks
    s = regexReplace(s, #"\n\n"#, "<br/><br/>")
    return s
}

let css = """
<style>
body { font-family: -apple-system, "SF Pro Text", system-ui, sans-serif;
       color: #1a1a1a; max-width: 680px; margin: 28px auto; padding: 0 36px;
       line-height: 1.55; font-size: 12.5px; }
h1 { font-size: 26px; color: #2E8CFF; margin: 0 0 6px 0; }
h2 { font-size: 16px; margin: 26px 0 8px 0; color: #1a1a1a;
     padding-bottom: 4px; border-bottom: 1px solid #eee; }
h3 { font-size: 13px; margin: 18px 0 6px 0; color: #444; }
hr { border: none; border-top: 1px solid #ddd; margin: 18px 0; }
a  { color: #2E8CFF; text-decoration: none; }
strong { color: #1a1a1a; }
code { font-family: ui-monospace, "SF Mono", Menlo, monospace;
       background: #f3f4f6; padding: 2px 5px; border-radius: 3px; font-size: 11px; }
blockquote { border-left: 3px solid #2E8CFF; margin: 10px 0;
             padding: 6px 12px; background: #f7fbff; color: #444;
             font-size: 12px; }
table { width: 100%; border-collapse: collapse; margin: 8px 0 12px 0; }
td { padding: 6px 8px; border-bottom: 1px solid #eee; font-size: 12px;
     vertical-align: top; }
td:first-child { font-weight: 600; width: 30%; }
ul, ol { padding-left: 22px; margin: 6px 0; }
li { margin: 4px 0; }
</style>
"""

// ─── CLI ──────────────────────────────────────────────────────────

let scriptDir = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()
let projectDir = scriptDir.deletingLastPathComponent()
let templateURL = projectDir.appending(path: "marketing/README-client.md")
let outURL = projectDir.appending(path: "marketing/MisiCopy-Guide-utilisateur.pdf")

guard let md = try? String(contentsOf: templateURL, encoding: .utf8) else {
    print("Template introuvable : \(templateURL.path)"); exit(1)
}

let html = "<!DOCTYPE html><html><head><meta charset='utf-8'>\(css)</head><body>\(mdToHTML(md))</body></html>"

guard let data = html.data(using: .utf8),
      let attr = try? NSAttributedString(
        data: data,
        options: [.documentType: NSAttributedString.DocumentType.html,
                  .characterEncoding: String.Encoding.utf8.rawValue],
        documentAttributes: nil
      ) else {
    print("HTML parse failed"); exit(1)
}

// Render to A4 with auto pagination
let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
let textView = NSTextView(frame: pageRect)
textView.textStorage?.setAttributedString(attr)
textView.isEditable = false
textView.backgroundColor = .white
textView.textContainerInset = NSSize(width: 0, height: 12)
textView.layoutManager?.ensureLayout(for: textView.textContainer!)
let height = textView.layoutManager?.usedRect(for: textView.textContainer!).height ?? 800
textView.frame = NSRect(x: 0, y: 0, width: pageRect.width, height: max(pageRect.height, height + 60))

let info = NSPrintInfo()
info.paperSize = pageRect.size
info.topMargin = 36; info.bottomMargin = 36
info.leftMargin = 36; info.rightMargin = 36
info.orientation = .portrait
info.horizontalPagination = .fit
info.verticalPagination = .automatic

let op = NSPrintOperation.pdfOperation(with: textView,
                                       inside: pageRect,
                                       toPath: outURL.path,
                                       printInfo: info)
op.showsPrintPanel = false
op.showsProgressPanel = false
op.run()

print("✅ PDF généré : \(outURL.path)")
