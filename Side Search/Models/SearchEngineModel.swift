//
//  SearchEngineModel.swift
//  Side Search
//
//  Created by Cizzuk on 2025/12/24.
//

import Foundation

struct SearchEngineModel: Identifiable, Codable {
    var id = UUID()
    var name: LocalizedStringResource = ""
    var url = ""
}

extension SearchEngineModel {
    static func fromJSON(_ data: Data) -> SearchEngineModel? {
        let decoder = JSONDecoder()
        return try? decoder.decode(SearchEngineModel.self, from: data)
    }
    
    func toJSON() -> Data? {
        let encoder = JSONEncoder()
        return try? encoder.encode(self)
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
