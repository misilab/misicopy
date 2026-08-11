//
//  ASCMHLExporter.swift
//  MisiCopy
//
//  Produces an ASCMHL v2 sidecar (XML) — the modern Media Hash List
//  format standardized by the ASC (American Society of Cinematographers).
//  Reference: https://github.com/ascmitchell/ascmhl
//

import Foundation

struct ASCMHLExporter {

    nonisolated static func makeXML(
        source: URL?,
        destinations: [Destination],
        files: [FileItem],
        algorithm: ChecksumAlgorithm,
        startDate: Date,
        endDate: Date
    ) -> String {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]
        let user = NSUserName()
        let host = ProcessInfo.processInfo.hostName

        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        xml += "<hashlist version=\"2.0\" xmlns=\"urn:ASC:MHL:v2.0\">\n"

        // Creator info
        xml += "  <creatorinfo>\n"
        xml += "    <creationdate>\(iso.string(from: endDate))</creationdate>\n"
        xml += "    <hostname>\(escape(host))</hostname>\n"
        xml += "    <tool name=\"MisiCopy\" version=\"1.0\"/>\n"
        xml += "    <author>\n"
        xml += "      <name>\(escape(user))</name>\n"
        xml += "    </author>\n"
        xml += "  </creatorinfo>\n"

        // Process info
        xml += "  <processinfo>\n"
        xml += "    <process>verify</process>\n"
        xml += "    <hashlist_custom_basic_location/>\n"
        xml += "    <ignore/>\n"
        xml += "  </processinfo>\n"

        // Hashes
        xml += "  <hashes>\n"
        for file in files {
            xml += "    <hash>\n"
            xml += "      <path size=\"\(file.size)\">\(escape(file.relativePath))</path>\n"
            if let checksum = file.sourceChecksum {
                xml += "      <\(algorithm.mhlTag) action=\"verified\" hashdate=\"\(iso.string(from: endDate))\">\(checksum)</\(algorithm.mhlTag)>\n"
            }
            xml += "    </hash>\n"
        }
        xml += "  </hashes>\n"

        // References (sources / destinations)
        xml += "  <references>\n"
        if let source {
            xml += "    <hashlist path=\"\(escape(source.path(percentEncoded: false)))\" role=\"source\"/>\n"
        }
        for destination in destinations {
            xml += "    <hashlist path=\"\(escape(destination.path))\" role=\"destination\"/>\n"
        }
        xml += "  </references>\n"

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
