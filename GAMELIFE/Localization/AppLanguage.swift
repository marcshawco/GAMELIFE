//
//  AppLanguage.swift
//  GAMELIFE
//
//  [SYSTEM]: Localization matrix initialized.
//

import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english = "en"
    case german = "de"
    case russian = "ru"
    case french = "fr"
    case italian = "it"
    case spanish = "es"

    var id: String { rawValue }

    var localeIdentifier: String? {
        switch self {
        case .system:
            return nil
        case .english, .german, .russian, .french, .italian, .spanish:
            return rawValue
        }
    }

    var displayName: String {
        switch self {
        case .system:
            return "System Default"
        case .english:
            return "English"
        case .german:
            return "Deutsch"
        case .russian:
            return "Русский"
        case .french:
            return "Français"
        case .italian:
            return "Italiano"
        case .spanish:
            return "Español"
        }
    }

    var locale: Locale {
        if let localeIdentifier {
            return Locale(identifier: localeIdentifier)
        }
        return .autoupdatingCurrent
    }
}

func localizedAppString(_ key: String) -> String {
    NSLocalizedString(key, comment: "")
}

extension GameTab {
    var localizedTitle: String {
        localizedAppString(title)
    }
}
