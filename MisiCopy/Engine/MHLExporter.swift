//
//  MHLExporter.swift
//  MisiCopy
//
//  Writes a Media Hash List (MHL) XML report describing the copy session.
//

import Foundation

struct MHLExporter {

    static func makeXML(
        source: URL?,
        destinations: [Destination],
        files: [FileItem],
        algorithm: ChecksumAlgorithm,
        startDate: Date,
        endDate: Date
    ) -> String {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]

        let host = ProcessInfo.processInfo.hostName
        let user = NSUserName()

        var xml = ""
        xml += "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        xml += "<hashlist version=\"1.1\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\">\n"
        xml += "  <creatorinfo>\n"
        xml += "    <name>\(escape(user))</name>\n"
        xml += "    <username>\(escape(user))</username>\n"
        xml += "    <hostname>\(escape(host))</hostname>\n"
        xml += "    <tool>MisiCopy 1.0</tool>\n"
        xml += "    <startdate>\(iso.string(from: startDate))</startdate>\n"
        xml += "    <finishdate>\(iso.string(from: endDate))</finishdate>\n"
        xml += "  </creatorinfo>\n"

        if let source {
            xml += "  <source>\n"
            xml += "    <path>\(escape(source.path(percentEncoded: false)))</path>\n"
            xml += "  </source>\n"
        }
        for destination in destinations {
            xml += "  <destination>\n"
            xml += "    <path>\(escape(destination.path))</path>\n"
            xml += "  </destination>\n"
        }

        for file in files {
            xml += "  <hash>\n"
            xml += "    <file>\(escape(file.relativePath))</file>\n"
            xml += "    <size>\(file.size)</size>\n"
            if let checksum = file.sourceChecksum {
                xml += "    <\(algorithm.mhlTag)>\(checksum)</\(algorithm.mhlTag)>\n"
            }
            xml += "    <hashdate>\(iso.string(from: endDate))</hashdate>\n"
            xml += "  </hash>\n"
        }

        xml += "</hashlist>\n"
        return xml
    }

    private static func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}
