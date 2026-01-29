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
    
    private var assistantModel = AppleFoundationAssistantModel.load()
    
    private var session: LanguageModelSession
    
    // MARK: - Initialization
    
    override init() {
        // Initialize Language Model Session with custom instructions if provided
        if assistantModel.customInstructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.session = LanguageModelSession()
        } else {
            self.session = LanguageModelSession(instructions: assistantModel.customInstructions)
        }
        
        super.init()
    }
    
    // MARK: - Helper Methods
    
    @MainActor
    func generate(prompt: String) async throws -> String {
        let response = try await session.respond(to: prompt)
        return response.content
    }
    
    // MARK: - Override Methods
    
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
