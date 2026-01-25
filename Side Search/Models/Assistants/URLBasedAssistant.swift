//
//  URLBasedAssistant.swift
//  Side Search
//
//  Created by Cizzuk on 2025/12/24.
//

import Foundation
import SwiftUI

struct URLBasedAssistant: AssistantDescriptionProvider {
    static var assistantName = LocalizedStringResource("")
    static var assistantDescription = LocalizedStringResource("")
    static var assistantSystemImage = ""
    
    static var settingsView: any View { EmptyView() }
    static var userDefaultsKey = "defaultSearchEngine"
    
    static func isAvailable() -> Bool { return true }
}

struct URLBasedAssistantModel: AssistantModel {
    var name: LocalizedStringResource = ""
    var url = ""
    
    static func fromJSON(_ data: Data) -> URLBasedAssistantModel? {
        let decoder = JSONDecoder()
        return try? decoder.decode(URLBasedAssistantModel.self, from: data)
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
