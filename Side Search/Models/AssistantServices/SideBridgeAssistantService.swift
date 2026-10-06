//
//  SideBridgeAssistantService.swift
//  Side Search
//
//  Created by Cizzuk on 2026/01/26.
//

import UIKit
import SideBridge

class SideBridgeAssistantService: BaseAssistantService {
    
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
        Task { @MainActor in
            do {
                let request = createRequest()
                let response = try await sendRequest(request: request)
                responseHandler(sbResponse: response)
            } catch { } // Ignore errors for initial request
        }
        
        #if targetEnvironment(simulator)
        // Demo message
        let isJapanese = Locale.current.language.languageCode?.identifier == "ja"
        let userContent = isJapanese ? "東京の今日の天気は？" : "What's the weather like in Tokyo today?"
        let userMessage = AssistantMessage(from: .user, content: userContent)
        addMessage(userMessage)
        let assistantContent = isJapanese ? "今日の東京の天気は、朝は快晴ですが夕方から夜にかけて雷を伴う激しい雨が予想されています。降水確率は80%です。\n\n予想最高気温は21°Cから24°C、最低気温は15°Cから18°Cです。\n\nお出かけの際は傘をお持ちになることをおすすめします。" : "Today's weather in Tokyo is clear in the morning, but heavy rain with thunderstorms is expected from evening into the night. The chance of precipitation is 80%.\n\nThe expected maximum temperature is 21°C to 24°C, and the minimum temperature is 15°C to 18°C.\n\nI recommend taking an umbrella with you if you go out."
        let assistantMessage = AssistantMessage(from: .assistant, content: assistantContent)
        addMessage(assistantMessage)
        #endif
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
        
        Task { @MainActor in
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
