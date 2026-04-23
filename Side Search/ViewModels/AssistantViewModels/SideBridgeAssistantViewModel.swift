//
//  SideBridgeAssistantViewModel.swift
//  Side Search
//
//  Created by Cizzuk on 2026/01/26.
//

import UIKit
import SideBridge

class SideBridgeAssistantViewModel: AssistantViewModel {
    
    private var currentOptions = SBOptions()
    
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
            urlRequest.setValue(authKey, forHTTPHeaderField: "Authorization")
        }
        
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        print("\n==========\nSending request: \(String(data: urlRequest.httpBody ?? Data(), encoding: .utf8) ?? "")")
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        print("\n++++++++++\nReceived response: \(String(data: data, encoding: .utf8) ?? "")")
        
        let sbResponse = try JSONDecoder().decode(SBResponse.self, from: data)
        
        // Update options
        if let options = sbResponse.options {
            if let disableSendHistory = options.disableSendHistory {
                currentOptions.disableSendHistory = disableSendHistory
            }
            if let endSession = options.endSession {
                currentOptions.endSession = endSession
            }
        }
        
        return sbResponse
    }
    
    private func createRequest(
        type: SBRequest.RequestType,
        messages: [AssistantMessage]? = nil
    ) -> SBRequest {
        
        var request = SBRequest(
            chatId: chat.id,
            type: type
        )
        
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
    
    override func processInput() {
        guard !responseIsPreparing else { return }
        responseIsPreparing = true
        pauseRecognize()
        
        let userInput = inputText
        var messages: [AssistantMessage] = []
        
        if !userInput.isEmpty {
            let userMessage = AssistantMessage(from: .user, content: userInput)
            messages.append(userMessage)
            addMessage(userMessage)
            inputText = ""
        }
        
        Task {
            do {
                let request = createRequest(type: .sendMessage, messages: messages)
                let response = try await sendRequest(request: request)
                for message in response.messages ?? [] {
                    addMessage(AssistantMessage.fromSBMessage(message))
                }
            } catch {
                let errorMessage = "Failed to communicate with SideBridge: \(error.localizedDescription)"
                let assistantMessage = AssistantMessage(from: .system, content: errorMessage)
                addMessage(assistantMessage)
                print("\n!!!!!!!!!!\n\(error)")
            }
            
            responseIsPreparing = false
            resumeRecognize()
        }
    }
}
