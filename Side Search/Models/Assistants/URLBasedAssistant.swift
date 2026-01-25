//
//  URLBasedAssistant.swift
//  Side Search
//
//  Created by Cizzuk on 2025/12/24.
//

import Foundation
import SwiftUI

struct URLBasedAssistant: AssistantDescriptionProvider {
    static var assistantName = LocalizedStringResource("URL Based Assistant")
    static var assistantDescription = LocalizedStringResource("")
    static var assistantSystemImage = "magnifyingglass"
    
    static func makeSettingsView() -> some View {
        URLBasedAssistantSettingsView()
    }
    static var userDefaultsKey = "defaultSearchEngine"
    
    static func isAvailable() -> Bool { return true }
}

struct URLBasedAssistantModel: AssistantModel {
    var name: LocalizedStringResource = ""
    var url = ""
    var openIn: OpenInOption = .inAppBrowser
    
    static func fromJSON(_ data: Data) -> URLBasedAssistantModel? {
        let decoder = JSONDecoder()
        var model = try? decoder.decode(URLBasedAssistantModel.self, from: data)
        
        // Get previous OpenIn setting
        if let previousOpenIn = UserDefaults.standard.string(forKey: "openIn") {
            if let option = OpenInOption(rawValue: previousOpenIn) {
                model?.openIn = option
                UserDefaults.standard.removeObject(forKey: "openIn")
            }
        }
        return model
    }
    
    func toJSON() -> Data? {
        let encoder = JSONEncoder()
        return try? encoder.encode(self)
    }
    
    func isValidSettings() -> Bool {
        return checkURLAvailability()
    }
}

extension URLBasedAssistantModel {
    enum OpenInOption: String, Codable, CaseIterable {
        case inAppBrowser, defaultApp
        
        var localizedName: LocalizedStringResource {
            switch self {
            case .inAppBrowser:
                return "In-App Browser"
            case .defaultApp:
                return "Default App"
            }
        }
    }
    
    func makeSearchURL(query: String? = nil) -> URL? {
        var urlString = self.url
        
        // Handle query if provided
        if let searchQuery = query {
            // Replace the placeholder with the query
            urlString = urlString.replacingOccurrences(of: "%s", with: searchQuery)
        }
        
        // Create the URL
        if let createdURL = URL(string: urlString) {
            return createdURL
        } else {
            return nil
        }
    }
    
    func checkURLAvailability() -> Bool {
        if makeSearchURL(query: "test") == nil {
            return false
        }
        return true
    }
    
    func checkSafariViewAvailability() -> Bool {
        if let url = makeSearchURL(query: "test"),
           SafariView.checkAvailability(at: url) {
            return true
        } else {
            return false
        }
    }
    
    func needQueryInput() -> Bool {
        return self.url.contains("%s")
    }
}
