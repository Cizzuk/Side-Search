//
//  SideBridgeAssistantViewModel.swift
//  Side Search
//
//  Created by Cizzuk on 2026/01/26.
//

import UIKit
import SideBridge

class SideBridgeAssistantViewModel: AssistantViewModel {
    
    private var currentOptions = SBOptions() {
        didSet {
            // Sync endSession State
            if currentOptions.endSession == true {
                isEnded = true
            }
        }
    }
    
    // MARK: - Assistant Settings
    
    private var assistantModel = SideBridgeAssistantModel.load()
    private var authKey: String = SideBridgeAssistantModel.loadAuthKey()
    
    // MARK: - Helper Methods

    private func sendRequest(request: SBRequest) async throws -> SBResponse {
        guard let url = URL(string: assistantModel.endpoint) else {
            throw URLError(.badURL)
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if !authKey.isEmpty {
            urlRequest.setValue(authKey, forHTTPHeaderField: "x-sidebridge-key")
        }
        
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        #if DEBUG
        print("\nSending request: \n\(String(data: urlRequest.httpBody ?? Data(), encoding: .utf8) ?? "")")
        #endif
        
        let (data, _) = try await URLSession.shared.data(for: urlRequest)
        
        #if DEBUG
        print("\nReceived response: \n\(String(data: data, encoding: .utf8) ?? "")")
        #endif
        
        let sbResponse = try JSONDecoder().decode(SBResponse.self, from: data)
        
        return sbResponse
    }
    
    @MainActor
    private func responseHandler(sbResponse: SBResponse) {
        for message in sbResponse.messages ?? [] {
            if message.content.isEmpty { continue }
            addMessage(AssistantMessage.fromSBMessage(message))
        }
        
        // Update options
        if let options = sbResponse.options {
            currentOptions.merge(with: options)
        }
    }
    
    private func createRequest(messages: [AssistantMessage]? = nil) -> SBRequest {
        var request = SBRequest(chatId: chat.id)
        
        if let messages = messages,
           !messages.isEmpty {
            request.messages = messages.map { message in
                message.toSBMessage()
            }
        }
        
        if !(currentOptions.disableSendHistory ?? false) {
            request.history = chat.messages.map { message in
                message.toSBMessage()
            }
        }
        
        return request
    }
    
    // MARK: - Override Methods
    
    override func assistantInitialize() {
        Task {
            let request = createRequest()
            // It is not required for the Bridge to return a response to the initial request.
            let response = try await sendRequest(request: request)
            responseHandler(sbResponse: response)
        }
    }
    
    override func processInput() {
        guard !responseIsPreparing else { return }
        responseIsPreparing = true
        pauseRecognize()
        
        let userInput = inputText
        let userMessage = AssistantMessage(from: .user, content: userInput)
        let messages: [AssistantMessage] = [userMessage]
        
        // Empty messages are sent but are not saved in the history.
        if !userInput.isEmpty {
            addMessage(userMessage)
            inputText = ""
        }
        
        Task {
            do {
                let request = createRequest(messages: messages)
                let response = try await sendRequest(request: request)
                responseHandler(sbResponse: response)
            } catch {
                let errorMessage = "Failed to communicate with Side Bridge: \(error.localizedDescription)"
                let assistantMessage = AssistantMessage(from: .system, content: errorMessage)
                addMessage(assistantMessage)
            }
            
            responseIsPreparing = false
            resumeRecognize()
        }
    }
}
