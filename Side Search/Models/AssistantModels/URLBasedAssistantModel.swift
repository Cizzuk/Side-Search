//
//  URLBasedAssistantModel.swift
//  Side Search
//
//  Created by Cizzuk on 2025/12/24.
//

import Foundation
import MergeCodablePackage

struct URLBasedAssistantModel: AssistantModel, MergeCodable {
    private static let userDefaultsKey = "urlBasedAssistantSettings"
    
    // Model Settings
    var url: String = SearchEnginePresets.defaultSearchEngine.url
    
    // Deprecated
    var openIn: OpenInOption? = nil
    
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
