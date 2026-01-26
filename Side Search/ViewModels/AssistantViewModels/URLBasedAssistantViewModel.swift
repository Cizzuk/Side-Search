//
//  URLBasedAssistantViewModel.swift
//  Side Search
//
//  Created by Cizzuk on 2026/01/26.
//

import UIKit

class URLBasedAssistantViewModel: AssistantViewModel {
    
    // MARK: - Assistant Settings
    
    private var assistantModel: URLBasedAssistantModel = {
        if let rawData = UserDefaults.standard.data(forKey: URLBasedAssistant.userDefaultsKey),
           let model = URLBasedAssistantModel.fromJSON(rawData) {
            return model
        }
        return URLBasedAssistantModel()
    }()
    
    // MARK: - Initialization
    
    override init() {
        super.init()
    }
    
    // MARK: - Override Methods
    
    override func startAssistant() {
        if !assistantModel.checkURLAvailability() {
            return
        }
        if !startWithMicMuted {
            startRecording()
        }
    }
    
    override func confirmInput() {
        // Stop recording before searching
        stopRecording()
        
        if let url = assistantModel.makeSearchURL(query: inputText) {
            switch assistantModel.openIn {
            case .inAppBrowser:
                self.searchURL = url
                self.showSafariView = true
            case .defaultApp:
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                onDismiss?()
            }
        } else {
            // Handle invalid URL error
            self.errorMessage = "Invalid Search URL. Please check your settings."
            self.showError = true
        }
    }
}
