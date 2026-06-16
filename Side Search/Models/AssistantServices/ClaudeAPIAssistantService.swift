//
//  ClaudeAPIAssistantService.swift
//  Side Search
//
//  Created by Cizzuk on 2026/06/15.
//

import FoundationModels
import UIKit
import ClaudeForFoundationModels

class ClaudeAPIAssistantService: BaseAssistantService {
    
    // MARK: - Assistant Settings
    
    private var assistantModel = ClaudeAPIAssistantModel.load()
    private var apiKey: String = ClaudeAPIAssistantModel.loadAPIKey()
    
    lazy private var model: ClaudeLanguageModel = assistantModel.makeLM(apiKey: apiKey)
    
    lazy private var session: LanguageModelSession = {
        if assistantModel.customInstructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return LanguageModelSession(model: model)
        } else {
            return LanguageModelSession(
                model: model,
                instructions: assistantModel.customInstructions
            )
        }
    }()
    
    // MARK: - Helper Methods
    
    @MainActor
    func generate(prompt: String) async throws -> String {
        let response: LanguageModelSession.Response<String>
        
//        if let reasoningLevel = assistantModel.reasoningLevel.reasoningLevel,
//           model.capabilities.contains(.reasoning) {
            response = try await session.respond(
                to: prompt,
                contextOptions: ContextOptions(reasoningLevel: .light)
            )
//        } else {
//            response = try await session.respond(to: prompt)
//        }
        
        return response.content
    }
    
    // MARK: - Override Methods
    
    override func assistantInitialize() {
        guard !chat.messages.isEmpty else { return }
        
        // Restore chat history
        let entries: some Sequence<Transcript.Entry> = chat.messages.compactMap { message in
            let textSegment = Transcript.TextSegment(content: message.content)
            
            switch message.from {
            case .user:
                let prompt = Transcript.Prompt(segments: [.text(textSegment)])
                return Transcript.Entry.prompt(prompt)
            case .assistant:
                let response = Transcript.Response(assetIDs: [], segments: [.text(textSegment)])
                return Transcript.Entry.response(response)
            case .system:
                return nil
            case .unknown:
                return nil
            }
        }
        
        session = LanguageModelSession(
            model: model,
            transcript: Transcript(entries: entries)
        )
    }
    
    override func processInput() {
        // Prevent empty input
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return }
        
        guard !responseIsPreparing else { return }
        responseIsPreparing = true
        pauseRecognize()
        
        // Add user message to history
        let userInput = inputText
        inputText = ""
        let userMessage = AssistantMessage(from: .user, content: userInput)
        addMessage(userMessage)
        
        // Generate response
        Task { [weak self] in
            guard let self = self else { return }
            
            let message: AssistantMessage
            do {
                let response = try await generate(prompt: userInput)
                message = AssistantMessage(from: .assistant, content: response)
            } catch {
                message = AssistantMessage(from: .system, content: error.localizedDescription)
            }
            
            DispatchQueue.main.async {
                self.addMessage(message)
                self.responseIsPreparing = false
                self.resumeRecognize()
            }
        }
    }
}
