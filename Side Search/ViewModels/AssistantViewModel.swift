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
    
    init(chat: ChatHistorySupport.Chat? = nil) {
        let chat = chat ?? ChatHistorySupport.Chat(
            id: UUID(),
            date: Date(),
            assistantType: UserSettings.shared.currentAssistant,
            messages: []
        )
        
        self.service = chat.assistantType.AssistantServiceType.init(chat: chat)
        self.chat = chat
    }
}
