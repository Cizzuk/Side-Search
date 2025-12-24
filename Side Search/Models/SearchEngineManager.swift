//
//  SearchEngineManager.swift
//  Side Search
//
//  Created by Cizzuk on 2025/12/24.
//

// Save & Load Search Engine Data

import Combine
import Foundation

class SearchEngineManager {
    static let shared = SearchEngineManager()
    
    @Published var searchEngines: [SearchEngineModel] = []
    
    private init() {
        loadAll()
    }
    
    private func loadAll() {
        let rawStrings = UserDefaults.standard.array(forKey: "searchEngines") as? [String] ?? []
        for rawString in rawStrings {
            if let data = rawString.data(using: .utf8),
               let engine = SearchEngineModel.fromJSON(data) {
                searchEngines.append(engine)
            }
        }
    }
    
    private func saveAll() {
        let rawStrings = searchEngines.compactMap { engine -> String? in
            if let data = engine.toJSON(),
               let jsonString = String(data: data, encoding: .utf8) {
                return jsonString
            }
        }
        UserDefaults.standard.set(rawStrings, forKey: "searchEngines")
    }
    
    func addEngine(_ engine: SearchEngineModel) {
        searchEngines.append(engine)
        saveAll()
    }
}

    
