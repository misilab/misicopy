//
//  AppLanguage.swift
//  MisiCopy
//

import Foundation

enum AppLanguage: String, CaseIterable, Identifiable, Hashable {
    case fr, en, es

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fr: return "Français"
        case .en: return "English"
        case .es: return "Español"
        }
    }

    var shortCode: String {
        switch self {
        case .fr: return "FR"
        case .en: return "EN"
        case .es: return "ES"
        }
    }
}
