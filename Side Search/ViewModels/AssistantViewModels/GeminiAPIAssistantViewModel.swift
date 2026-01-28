//
//  GeminiAPIAssistantViewModel.swift
//  Side Search
//
//  Created by Cizzuk on 2026/01/28.
//

import UIKit

class GeminiAPIAssistantViewModel: AssistantViewModel {
    
    // MARK: - Assistant Settings
    
    private var assistantModel = GeminiAPIAssistantModel.load()
    private var apiKey: String = GeminiAPIAssistantModel.loadAPIKey()
    
    // MARK: - Gemini API Types for JSON
    // contents -> role, parts -> text
    
    private struct GeminiContent: Codable {
        let role: String
        let parts: [GeminiPart]
    }
    
    private struct GeminiPart: Codable {
        let text: String
    }
    
    private struct GeminiRequest: Codable {
        let contents: [GeminiContent]
    }
    
    // For response parsing
    private struct GeminiResponse: Codable {
        let candidates: [GeminiCandidate]?
    }
    
    private struct GeminiCandidate: Codable {
        let content: GeminiContent
    }
    
    // MARK: - Chat History
    
    private var chatHistory: [GeminiContent] = []
    
    // MARK: - Initialization
    
    override init() {
        super.init()
    }
    
    // MARK: - Helper Methods
    
    @MainActor
    func generate(prompt: String) async throws -> String {
        chatHistory.append(GeminiContent(role: "user", parts: [GeminiPart(text: prompt)]))
        
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(assistantModel.model):generateContent")
        else {
            throw NSError(domain: "GeminiAPIAssistant",
                          code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        // Prepare request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(GeminiRequest(contents: chatHistory))
        
        // Send request
        let data: Data
        do {
            (data, _) = try await URLSession.shared.data(for: request)
        } catch {
            throw NSError(domain: "GeminiAPIAssistant",
                          code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Connection error"])
        }
        
        let response = try JSONDecoder().decode(GeminiResponse.self, from: data)

        // Parse response
        guard let text = response.candidates?.first?.content.parts.first?.text else {
            throw NSError(domain: "GeminiAPIAssistant",
                          code: -1,
                          userInfo: [NSLocalizedDescriptionKey: String(data: data, encoding: .utf8) ?? "No response"])
        }
        
        chatHistory.append(GeminiContent(role: "model", parts: [GeminiPart(text: text)]))
        return text
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
