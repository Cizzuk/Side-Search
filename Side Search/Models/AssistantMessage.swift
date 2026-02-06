//
//  AssistantMessage.swift
//  Side Search
//
//  Created by Cizzuk on 2026/02/06.
//

import Foundation

struct AssistantMessage: Identifiable {
    enum From {
        case user
        case assistant
        case system
        
        var displayName: LocalizedStringResource {
            switch self {
            case .user:
                return "You"
            case .assistant:
                return "Assistant"
            case .system:
                return "System"
            }
        }
    }
    
    let id = UUID()
    let from: From
    let content: String
    var sources: [(title: String, url: URL)] = []
}
