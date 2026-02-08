//
//  AssistantMessage.swift
//  Side Search
//
//  Created by Cizzuk on 2026/02/06.
//

import Foundation

struct AssistantMessage: Identifiable, Decodable {
    enum From: Decodable {
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
    
    struct Source: Decodable {
        var title: String
        var url: URL
    }
    
    var id = UUID()
    var from: From
    var content: String
    var sources: [Source] = []
}
