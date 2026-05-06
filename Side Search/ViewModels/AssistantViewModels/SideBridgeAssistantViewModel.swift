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
        
        print("\n==========\nSending request: \(String(data: urlRequest.httpBody ?? Data(), encoding: .utf8) ?? "")")
        
        let (data, _) = try await URLSession.shared.data(for: urlRequest)
        
        print("\n++++++++++\nReceived response: \(String(data: data, encoding: .utf8) ?? "")")
        
        let sbResponse = try JSONDecoder().decode(SBResponse.self, from: data)
        
        return sbResponse
    }
    
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
                let errorMessage = "Failed to communicate with SideBridge: \(error.localizedDescription)"
                let assistantMessage = AssistantMessage(from: .system, content: errorMessage)
                addMessage(assistantMessage)
            }
            
            responseIsPreparing = false
            resumeRecognize()
        }
    }
}
