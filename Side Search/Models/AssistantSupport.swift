//
//  AssistantSupport.swift
//  Side Search
//
//  Created by Cizzuk on 2026/01/14.
//

import Foundation

struct AssistantSupport {
    static func makeSearchURL(query: String? = nil) -> URL? {
        // Get defaultSearchEngine
        guard let rawData = UserDefaults.standard.data(forKey: "defaultSearchEngine"),
              let engine: SearchEngineModel = SearchEngineModel.fromJSON(rawData)
        else { return nil }
        
        var urlString = engine.url
        
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
    
    static func checkURLAvailability() -> Bool {
        if AssistantSupport.makeSearchURL(query: "test") == nil {
            return false
        }
        return true
    }
    
    static func checkSafariViewAvailability() -> Bool {
        if let url = AssistantSupport.makeSearchURL(query: "test"),
           SafariView.checkAvailability(at: url) {
            return true
        } else {
            return false
        }
    }
    
    static func needQueryInput() -> Bool {
        // Get defaultSearchEngine
        guard let rawData = UserDefaults.standard.data(forKey: "defaultSearchEngine"),
              let engine: SearchEngineModel = SearchEngineModel.fromJSON(rawData)
        else { return false }
        
        return engine.url.contains("%s")
    }
}
