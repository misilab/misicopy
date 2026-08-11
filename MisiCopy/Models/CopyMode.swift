//
//  CopyMode.swift
//  MisiCopy
//

import SwiftUI

enum CopyMode: String, CaseIterable, Identifiable, Hashable, Codable {
    case verified
    case doubleVerified
    case fast
    case verifyOnly

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .verified: return "checkmark.shield.fill"
        case .doubleVerified: return "checkmark.shield"
        case .fast: return "bolt.fill"
        case .verifyOnly: return "magnifyingglass.circle.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .verified: return .blue
        case .doubleVerified: return .indigo
        case .fast: return .mint
        case .verifyOnly: return .teal
        }
    }
}
