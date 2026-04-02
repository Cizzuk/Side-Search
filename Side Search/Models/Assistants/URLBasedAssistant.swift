//
//  URLBasedAssistant.swift
//  Side Search
//
//  Created by Cizzuk on 2025/12/24.
//

import SwiftUI
import MergeCodablePackage

struct URLBasedAssistant: AssistantDescriptionProvider {
    static var assistantDescription = LocalizedStringResource("This can be used by setting URLs for AI assistants, search engines, etc. The assistant will open in the in-app browser or the default app. Side Search's speech recognition is optional.")
    static var assistantImage = Image(systemName: "magnifyingglass")
    static var assistantGradient = Gradient(colors: [
        Color(red: 51/255, green: 102/255,  blue: 255/255),
        Color(red: 51/255, green: 153/255,  blue: 255/255),
        Color(red: 51/255, green: 102/255,  blue: 255/255),
    ])
    static var assistantShapeStyle: AnyShapeStyle {
        AnyShapeStyle(LinearGradient(
            stops: [
                Gradient.Stop(color: Color(red: 51/255, green: 153/255,  blue: 255/255), location: 0.0),
                Gradient.Stop(color: Color(red: 51/255, green: 102/255,  blue: 255/255), location: 0.7),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ))
    }
    
    static var assistantIsAI: Bool = false
    static var backgroundSupports: Bool = false
    
    static func isAvailable() -> Bool { return true }
}

struct URLBasedAssistantModel: AssistantModel, MergeCodable {
    private static let userDefaultsKey = "urlBasedAssistantSettings"
    
    // Model Settings
    var url: String
    static let url_default: String = SearchEnginePresets.defaultSearchEngine.url
    
    // Deprecated
    var openIn: OpenInOption?
    static let openIn_default: OpenInOption? = nil
    
    init() {
        self.url = Self.url_default
        self.openIn = Self.openIn_default
    }
    
    static func load() -> Self {
        guard let rawData = UserDefaults.standard.data(forKey: Self.userDefaultsKey) else {
            return Self()
        }
        return decode(from: rawData)
    }
    
    func save() {
        if let data = encode() {
            UserDefaults.standard.set(data, forKey: Self.userDefaultsKey)
        }
    }
}

extension URLBasedAssistantModel {
    enum OpenInOption: String, Codable, CaseIterable {
        case inAppBrowser, defaultApp
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
    
    func needQueryInput() -> Bool {
        return self.url.contains("%s")
    }
}
