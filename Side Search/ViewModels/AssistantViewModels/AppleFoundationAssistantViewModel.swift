//
//  AppleFoundationAssistantViewModel.swift
//  Side Search
//
//  Created by Cizzuk on 2026/01/28.
//

import FoundationModels
import UIKit

class AppleFoundationAssistantViewModel: AssistantViewModel {
    
    // MARK: - Assistant Settings
    
    private var assistantModel: AppleFoundationAssistantModel = {
        return AppleFoundationAssistantModel()
    }()
    
    // MARK: - Initialization
    
    override init() {
        super.init()
    }
    
    // MARK: - Override Methods
    
    override func startAssistant() {
        if !startWithMicMuted {
            startRecording()
        }
    }
    
    override func confirmInput() {
        // Prevent empty input
        if inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return
        }
        
        responseIsPreparing = true
        stopRecording()
        
        // Add user message to history
        let userInput = inputText
        let userMessage = MessageData(from: .user, content: userInput)
        messageHistory.append(userMessage)
        
//        let response = "\(userInput)..."
//        let assistantMessage = MessageData(from: .assistant, content: response)
//        
//        // Simulate a response from Yamabico
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
//            guard let self = self else { return }
//            messageHistory.append(assistantMessage)
//            responseIsPreparing = false
//        }
        
        inputText = ""
    }
}
