//
//  ChatHistoryViewModel.swift
//  Side Search
//
//  Created by Cizzuk on 2026/02/09.
//

import Combine
import UIKit
import SwiftUI

class ChatHistoryViewModel: ObservableObject {
    @Published var chats: [ChatHistory.Chat] = []
    
    // Search Chat History
    @Published var searchResults: [ChatHistory.Chat] = []
    @Published var searchQuery = "" {
        didSet { updateSearch() }
    }
    
    // Web View
    @Published var searchURL: URL?
    @Published var showSafariView = false
    
    func openSafariView(at url: URL) {
        if SafariView.checkAvailability(at: url) {
            searchURL = url
            showSafariView = true
        } else {
            // Fallback
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    func loadChats() {
        chats = ChatHistory.loadChats()
    }
    
    func delete(_ chat: UUID) {
        ChatHistory.delete(chat)
        loadChats()
    }
    
    func clearAll() {
        ChatHistory.clearAll()
        loadChats()
    }
    
    func updateSearch() {
        let query = searchQuery
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        
        if query.isEmpty {
            return searchResults = []
        }
        
        // Search in messages, assistant type
        let filtered = chats.filter { chat in
            let assistantName = String(localized: chat.assistantType.DescriptionProviderType.assistantName).lowercased()
            
            let matchesAssistant = assistantName.contains(query)
            let matchesMessages = chat.messages.contains { $0.content.lowercased().contains(query) }
            
            return matchesAssistant || matchesMessages
        }
        
        searchResults = filtered.sorted { $0.date > $1.date }
    }
}
