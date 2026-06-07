//
//  GeoHelper.swift
//  Side Search
//
//  Created by Cizzuk on 2026/01/26.
//

import Foundation

class GeoHelper {
    static let currentRegion = Locale.current.region?.identifier
    static let preferredLanguages = Locale.preferredLanguages
    
    static func containsLanguage(_ languageCode: String) -> Bool {
        return preferredLanguages.contains { language in
            if language.hasPrefix(languageCode + "-") {
                return true
            }
            let locale = Locale(identifier: language)
            return locale.language.languageCode?.identifier == languageCode
        }
    }
}
