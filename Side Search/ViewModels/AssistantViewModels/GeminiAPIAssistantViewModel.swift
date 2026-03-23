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
    // tools -> google_search
    
    private struct GeminiContent: Codable {
        let role: String
        let parts: [GeminiPart]
    }
    
    private struct GeminiPart: Codable {
        let text: String
    }
    
    // For config
    private struct GeminiTool: Codable {
        let google_search: GeminiGoogleSearch
    }
    
    private struct GeminiGoogleSearch: Codable {
    }
    
    private struct GeminiRequest: Codable {
        let contents: [GeminiContent]
        var tools: [GeminiTool] = [GeminiTool(google_search: GeminiGoogleSearch())]
    }
    
    // For response parsing
    private struct GeminiResponse: Codable {
        let candidates: [GeminiCandidate]?
    }
    
    private struct GeminiCandidate: Codable {
        let content: GeminiContent
        let groundingMetadata: GeminiGroundingMetadata?
    }
    
    // For sources
    private struct GeminiGroundingMetadata: Codable {
        let groundingChunks: [GeminiGroundingChunk]?
    }
    
    private struct GeminiGroundingChunk: Codable {
        let web: GeminiWebSource?
    }
    
    private struct GeminiWebSource: Codable {
        let uri: String
        let title: String
    }
    
    // MARK: - Chat History
    
    private var chatHistory: [GeminiContent] = []
    
    // MARK: - Helper Methods
    
    @MainActor
    func generate(prompt: String) async {
        // Add user message to history
        addMessage(AssistantMessage(from: .user, content: prompt))
        chatHistory.append(GeminiContent(role: "user", parts: [GeminiPart(text: prompt)]))
        
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(assistantModel.model):generateContent")
        else {
            addMessage(AssistantMessage(from: .system, content: "Invalid URL"))
            return
        }
        
        // Prepare request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create request body
        do {
            request.httpBody = try JSONEncoder().encode(GeminiRequest(contents: chatHistory))
        } catch {
            addMessage(AssistantMessage(from: .system, content: error.localizedDescription))
            return
        }
        
        // Send request
        let data: Data
        do {
            (data, _) = try await URLSession.shared.data(for: request)
        } catch {
            addMessage(AssistantMessage(from: .system, content: error.localizedDescription))
            return
        }
        
        // Parse response
        let response: GeminiResponse
        do {
            response = try JSONDecoder().decode(GeminiResponse.self, from: data)
        } catch {
            addMessage(AssistantMessage(from: .system, content: error.localizedDescription))
            return
        }
        
        // Extract response text
        guard let candidate = response.candidates?.first,
              let text = candidate.content.parts.first?.text else {
            // Error
            if let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let error = dict["error"] as? [String: Any],
               let message = error["message"] as? String {
                // Try to extract error message
                addMessage(AssistantMessage(from: .system, content: message))
            } else if let errorString = String(data: data, encoding: .utf8) {
                // Raw error string
                addMessage(AssistantMessage(from: .system, content: errorString))
            } else {
                // Unknown error
                addMessage(AssistantMessage(from: .system, content: "Unknown error occurred"))
            }
            return
        }
        
        // Extract sources
        var sources: [AssistantMessage.Source] = []
        if let groundingChunks = candidate.groundingMetadata?.groundingChunks {
            for chunk in groundingChunks {
                if let web = chunk.web, let sourceURL = URL(string: web.uri) {
                    sources.append(
                        AssistantMessage.Source(title: web.title, url: sourceURL)
                    )
                }
            }
        }
        
        // Add assistant message to history
        chatHistory.append(GeminiContent(role: "model", parts: [GeminiPart(text: text)]))
        let message = AssistantMessage(from: .assistant, content: text, sources: sources)
        addMessage(message)
    }
    
    // MARK: - Override Methods

    override func assistantInitialize() {
        guard !chat.messages.isEmpty else { return }

        // Restore chat history
        chatHistory = chat.messages.compactMap { message in
            guard message.from != .system else { return nil }
            return GeminiContent(
                role: message.from == .user ? "user" : "model",
                parts: [GeminiPart(text: message.content)]
            )
        }
    }
    
    override func processInput() {
        // Prevent empty input
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return }
        
        guard !responseIsPreparing else { return }
        responseIsPreparing = true
        pauseRecognize()
        
        let userInput = inputText
        inputText = ""
        
        Task {
            await generate(prompt: userInput)
            responseIsPreparing = false
            resumeRecognize()
        }
    }
}
