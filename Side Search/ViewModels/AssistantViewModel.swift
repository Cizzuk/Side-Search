//
//  AssistantViewModel.swift
//  Side Search
//
//  Created by Cizzuk on 2026/06/07.
//

import Combine
import SwiftUI

class AssistantViewModel: ObservableObject {
    private let service: BaseAssistantService
    @Published var chat: ChatHistorySupport.Chat
    
    // Assistant State
    @Published var isEnded = false
    @Published var isRecording = false
    @Published var isRecognizing = false
    @Published var responseIsPreparing = false
    
    // Error Alert
    @Published var errorMessage: LocalizedStringResource = ""
    @Published var showError = false
    
    @Published var micLevel: Float = 0.0
    
    private var cancellables = Set<AnyCancellable>()
    
    init(chat: ChatHistorySupport.Chat? = nil) {
        let chat = chat ?? ChatHistorySupport.Chat(
            id: UUID(),
            date: Date(),
            assistantType: UserSettings.shared.currentAssistant,
            messages: []
        )
        
        self.service = chat.assistantType.AssistantServiceType.init(chat: chat)
        self.chat = chat
        
        setupBindings()
    }
    
    private func setupBindings() {
        service.onError = { [weak self] message in
            DispatchQueue.main.async {
                self?.errorMessage = message
                self?.showError = true
            }
        }
        
        service.$chat
            .sink { [weak self] chat in
                self?.chat = chat
            }
            .store(in: &cancellables)
        
        service.$isRecording
            .sink { [weak self] isRecording in
                self?.isRecording = isRecording
            }
            .store(in: &cancellables)
        
        service.$isRecognizing
            .sink { [weak self] isRecognizing in
                self?.isRecognizing = isRecognizing
            }
            .store(in: &cancellables)
        
        service.$responseIsPreparing
            .sink { [weak self] responseIsPreparing in
                self?.responseIsPreparing = responseIsPreparing
            }
            .store(in: &cancellables)
        
        service.$micLevel
            .sink { [weak self] micLevel in
                self?.micLevel = micLevel
            }
            .store(in: &cancellables)
    }
}
