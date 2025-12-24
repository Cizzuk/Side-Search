//
//  AssistantViewModel.swift
//  Side Search
//
//  Created by Cizzuk on 2025/12/24.
//

import Combine
import UIKit

class AssistantViewModel: ObservableObject {
    @Published var isAssistantActivated = false
    
    @Published var SearchEngine: SearchEngineModel = {
        if let rawData = UserDefaults.standard.data(forKey: "defaultSearchEngine"),
           let engine = SearchEngineModel.fromJSON(rawData) {
            return engine
        }
        return SearchEngineModel()
    }()
}
