//
//  GeminiAPIAssistantViewModel.swift
//  Side Search
//
//  Created by Cizzuk on 2026/01/28.
//

import FoundationModels
import UIKit

class GeminiAPIAssistantViewModel: AssistantViewModel {
    
    // MARK: - Assistant Settings
    
    private var assistantModel = GeminiAPIAssistantModel.load()
    private var apiKey: String = GeminiAPIAssistantModel.loadAPIKey()
    
    // MARK: - Initialization
    
    override init() {
        super.init()
    }
    
    // MARK: - Helper Methods
    
    @MainActor
    func generate(prompt: String) async throws -> String {
        // TODO: Create Gemini API call
        return ""
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
        inputText = ""
        let userMessage = MessageData(from: .user, content: userInput)
        messageHistory.append(userMessage)
        
        // Generate response
        Task {
            let message: MessageData
            do {
                let response = try await generate(prompt: userInput)
                message = MessageData(from: .assistant, content: response)
            } catch {
                message = MessageData(from: .system, content: error.localizedDescription)
            }
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.messageHistory.append(message)
                self.responseIsPreparing = false
            }
        }
    }
}
