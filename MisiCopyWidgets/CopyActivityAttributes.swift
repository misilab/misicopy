//
//  CopyActivityAttributes.swift
//  MisiCopyWidgets
//
//  Duplicate of the iPhone app's file. Keeping a copy inside the Widget
//  Extension target avoids cross-target file references in the pbxproj
//  (which Xcode's file-system-synchronized groups don't handle), at the
//  cost of having to keep both in sync by hand. The two structs MUST
//  match field-for-field — `CopyActivityAttributes` is the type-id key
//  ActivityKit uses to route updates between the app and the widget.
//

import Foundation
import ActivityKit

struct CopyActivityAttributes: ActivityAttributes {
    var machineName: String
    var sessionID: String

    public struct ContentState: Codable, Hashable {
        var status: Status
        var progress: Double
        var copiedCount: Int
        var failedCount: Int
        var currentFile: String?
        var bytesPerSecond: Int64
        var etaSeconds: Int?

        public enum Status: String, Codable, Hashable {
            case running, paused, finished, failed
        }
    }
}
