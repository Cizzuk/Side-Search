//
//  TEST_YamabicoAssistantViewModel.swift
//  Side Search
//
//  Created by Cizzuk on 2026/01/26.
//

import UIKit

class TEST_YamabicoAssistantViewModel: AssistantViewModel {
    
    // MARK: - Assistant Settings
    
    private var assistantModel: TEST_YamabicoAssistantModel = {
        return TEST_YamabicoAssistantModel()
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
        // Stop recording before searching
        stopRecording()
        
        // Simulate a response from Yamabico
        let userInput = inputText
        let response = "\(userInput)..."
        
        messageHistory.append((from: .user, type: .text, content: userInput))
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            messageHistory.append((from: .assistant, type: .text, content: response))
        }
    }
}
