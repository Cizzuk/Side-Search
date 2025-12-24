//
//  SettingsViewModel.swift
//  Side Search
//
//  Created by Cizzuk on 2025/12/24.
//

import AppIntents
import Combine
import UIKit

class SettingsViewModel: ObservableObject {
    @Published var isAssistantActivated = false
    
    @Published var defaultSE: SearchEngineModel = {
        if let rawData = UserDefaults.standard.data(forKey: "defaultSearchEngine"),
           let engine = SearchEngineModel.fromJSON(rawData) {
            return engine
        }
        return SearchEngineModel()
    }() {
        didSet {
            if let data = defaultSE.toJSON() {
                UserDefaults.standard.set(data, forKey: "defaultSearchEngine")
            }
        }
    }
}
