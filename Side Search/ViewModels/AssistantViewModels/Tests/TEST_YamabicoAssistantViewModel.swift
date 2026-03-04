//
//  TEST_YamabicoAssistantViewModel.swift
//  Side Search
//
//  Created by Cizzuk on 2026/01/26.
//

import UIKit

class TEST_YamabicoAssistantViewModel: AssistantViewModel {
    
    // MARK: - Assistant Settings
    
    private var assistantModel = TEST_YamabicoAssistantModel()
    
    // MARK: - Initialization
    
    override init(assistantType: AssistantType = .test_yamabico) {
        super.init(assistantType: assistantType)
    }
    
    // MARK: - Override Methods
    
    override func confirmInput() {
        // Prevent empty input
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return }
        
        guard !responseIsPreparing else { return }
        responseIsPreparing = true
        pauseRecognize()
        
        // Add user message to history
        let userInput = inputText
        inputText = ""
        let userMessage = AssistantMessage(from: .user, content: userInput)
        addMessage(userMessage)
        
        let response = "\(userInput)..."
        let assistantMessage = AssistantMessage(from: .assistant, content: response)
        
        // Simulate a response from Yamabico
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            addMessage(assistantMessage)
            responseIsPreparing = false
            resumeRecognize()
        }
    }
}
