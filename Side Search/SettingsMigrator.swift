//
//  SettingsMigrator.swift
//  Side Search
//
//  Created by Cizzuk on 2026/03/31.
//

import Foundation

final class SettingsMigrator {
    static func migrateOpenURLsIn() -> UserSettings.URLOpeningOption? {
        var assistantModel = URLBasedAssistantModel.load()
        
        // < v2.9
        if let previousOpenIn = assistantModel.openIn {
            assistantModel.openIn = nil
            assistantModel.save()
            
            switch previousOpenIn {
            case .inAppBrowser:
                return .inAppBrowser
            case .defaultApp:
                return .defaultApp
            }
        }
        
        // < v2.0
        if let previousData = UserDefaults.standard.data(forKey: "defaultSearchEngine") {
            defer {
                UserDefaults.standard.removeObject(forKey: "defaultSearchEngine")
                UserDefaults.standard.removeObject(forKey: "openIn")
            }
            
            // Migrate URL
            guard let jsonDict = try? JSONSerialization.jsonObject(with: previousData) as? [String: Any]
            else { return nil }
            if let url = jsonDict["url"] as? String {
                assistantModel.url = url
            }
            
            assistantModel.save()
            
            // Migrate OpenIn
            guard let previousOpenIn = UserDefaults.standard.string(forKey: "openIn"),
                  let option = UserSettings.URLOpeningOption(rawValue: previousOpenIn)
            else { return nil }
            
            return option
        }
        
        return nil
    }
}
