//
//  AppleFoundationAssistantService.swift
//  Side Search
//
//  Created by Cizzuk on 2026/01/28.
//

import FoundationModels
import UIKit

class AppleFoundationAssistantService: BaseAssistantService {
    
    // MARK: - Assistant Settings
    
    private var assistantModel = AppleFoundationAssistantModel.load()
    
    lazy private var session: LanguageModelSession = {
        if assistantModel.customInstructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            if #available(anyAppleOS 27.0, *) {
                return LanguageModelSession(model: assistantModel.modelType.model)
            } else {
                return LanguageModelSession()
            }
        } else {
            if #available(anyAppleOS 27.0, *) {
                return LanguageModelSession(
                    model: assistantModel.modelType.model,
                    instructions: assistantModel.customInstructions
                )
            } else {
                return LanguageModelSession(instructions: assistantModel.customInstructions)
            }
        }
    }()
    
    // MARK: - Helper Methods
    
    @MainActor
    func generate(prompt: String) async throws -> String {
        let response: LanguageModelSession.Response<String>
        
        if #available(anyAppleOS 27.0, *),
           let reasoningLevel = assistantModel.reasoningLevel.reasoningLevel,
           assistantModel.modelType.model.capabilities.contains(.reasoning) {
            response = try await session.respond(
                to: prompt,
                contextOptions: ContextOptions(reasoningLevel: reasoningLevel)
            )
        } else {
            response = try await session.respond(to: prompt)
        }
        
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
        
        if #available(anyAppleOS 27.0, *) {
            session = LanguageModelSession(
                model: assistantModel.modelType.model,
                transcript: Transcript(entries: entries)
            )
        } else {
            session = LanguageModelSession(transcript: Transcript(entries: entries))
        }
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
