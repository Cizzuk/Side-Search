//
//  SideBridgeAssistantViewModel.swift
//  Side Search
//
//  Created by Cizzuk on 2026/01/26.
//

import UIKit

class SideBridgeAssistantViewModel: AssistantViewModel {
    
    // MARK: - Assistant Settings
    
    private var assistantModel = SideBridgeAssistantModel.load()
    private var authKey: String = SideBridgeAssistantModel.loadAuthKey()
    
    // MARK: - Override Methods
    
    override func processInput() {
        guard !responseIsPreparing else { return }
        responseIsPreparing = true
        pauseRecognize()
        
        // Add user message to history
        let userInput = inputText
        let userMessage = AssistantMessage(from: .user, content: userInput)
        addMessage(userMessage)
        
        // Response
        let assistantResponse = "Hello World!"
        let assistantMessage = AssistantMessage(from: .system, content: assistantResponse)
        addMessage(assistantMessage)
        
        inputText = ""
        responseIsPreparing = false
        resumeRecognize()
    }
}
