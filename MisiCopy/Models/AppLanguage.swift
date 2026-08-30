//
//  AppLanguage.swift
//  MisiCopy
//

import Foundation

enum AppLanguage: String, CaseIterable, Identifiable, Hashable {
    case fr, en, es, de, it

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fr: return "Français"
        case .en: return "English"
        case .es: return "Español"
        case .de: return "Deutsch"
        case .it: return "Italiano"
        }
    }

    var shortCode: String {
        switch self {
        case .fr: return "FR"
        case .en: return "EN"
        case .es: return "ES"
        case .de: return "DE"
        case .it: return "IT"
        }
    }
}
