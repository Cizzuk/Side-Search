//
//  AssistantMessage.swift
//  Side Search
//
//  Created by Cizzuk on 2026/02/06.
//

import Foundation

// MARK: - 'AssistantMessage' does NOT conform to 'MergeCodable'.
// Any changes to this struct should first make it conforms to 'MergeCodable'.
struct AssistantMessage: Identifiable, Codable {
    enum From: Codable {
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
    
    struct Source: Codable {
        var title: String
        var url: URL
    }
    
    var id = UUID()
    var from: From
    var content: String
    var sources: [Source] = []
}
