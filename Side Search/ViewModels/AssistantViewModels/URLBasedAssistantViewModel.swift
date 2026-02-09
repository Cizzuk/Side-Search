//
//  URLBasedAssistantViewModel.swift
//  Side Search
//
//  Created by Cizzuk on 2026/01/26.
//

import UIKit

class URLBasedAssistantViewModel: AssistantViewModel {
    
    // MARK: - Assistant Settings
    
    private var assistantModel = URLBasedAssistantModel.load()
    
    // MARK: - Initialization
    
    override init() {
        super.init()
    }
    
    // MARK: - Override Methods
    
    override func confirmInput() {
        // Stop recording before searching
        stopRecording()
        
        // Add user message to history
        let userInput = inputText
        inputText = ""
        var userMessage = AssistantMessage(from: .user, content: userInput)
        
        if let url = assistantModel.makeSearchURL(query: userInput) {
            switch assistantModel.openIn {
            case .inAppBrowser:
                self.openSafariView(at: url)
            case .defaultApp:
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
            userMessage.sources.append(
                AssistantMessage.Source(title: url.absoluteString, url: url)
            )
        } else {
            // Handle invalid URL error
            self.errorMessage = "Invalid Search URL. Please check your settings."
            self.showError = true
        }
        
        messageHistory.append(userMessage)
    }
}
