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
    }
}
