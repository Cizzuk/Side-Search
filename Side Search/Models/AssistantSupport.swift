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
        if var searchQuery = query {
            // Handle Max Query Length
            if let maxLength = engine.maxQueryLength {
                if searchQuery.count > maxLength {
                    searchQuery = String(searchQuery.prefix(maxLength))
                }
            }
            
            // Handle Percent Encoding
            if !engine.disablePercentEncoding {
                if let encoded = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                    searchQuery = encoded
                }
            }
            
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
    
    static func checkAvailability() -> Bool {
        if AssistantSupport.makeSearchURL(query: "test") == nil {
            return false
        }
        return true
    }
}
