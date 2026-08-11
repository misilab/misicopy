//
//  MisiCopyWidgetsBundle.swift
//  MisiCopyWidgets
//
//  Entry point for the Widget Extension target. The bundle declares every
//  widget — including Live Activities — that the iPhone app exposes to
//  iOS. For now there is only the `CopyLiveActivity`; future Home Screen
//  widgets would just be added to the same bundle.
//

import WidgetKit
import SwiftUI

@main
struct MisiCopyWidgetsBundle: WidgetBundle {
    // WidgetKit instantiates the bundle from a non-isolated context at
    // extension launch. The target inherits `SWIFT_DEFAULT_ACTOR_ISOLATION
    // = MainActor`, so we explicitly opt this initializer out of
    // MainActor isolation — otherwise Swift 6 strict mode refuses the
    // protocol conformance.
    nonisolated init() {}

    nonisolated var body: some Widget {
        CopyLiveActivity()
    }
}
