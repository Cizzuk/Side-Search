//
//  AssistantViewModel.swift
//  Side Search
//
//  Created by Cizzuk on 2026/06/07.
//

import Combine
import SwiftUI

class AssistantViewModel: ObservableObject {
    private let service: BaseAssistantService
    @Published var chat: ChatHistorySupport.Chat
    
    // Assistant State
    @Published var isEnded = false
    @Published var isRecording = false
    @Published var isRecognizing = false
    @Published var responseIsPreparing = false
    
    // Web View
    @Published var safariViewURL: URL?
    @Published var showSafariView = false
    
    // Error Alert
    @Published var errorMessage: LocalizedStringResource = ""
    @Published var showError = false
    
    @Published var micLevel: Float = 0.0
    
    private var cancellables = Set<AnyCancellable>()
    
    init(chat: ChatHistorySupport.Chat? = nil) {
        let chat = chat ?? ChatHistorySupport.Chat(
            id: UUID(),
            date: Date(),
            assistantType: UserSettings.shared.currentAssistant,
            messages: []
        )
        
        self.service = chat.assistantType.AssistantServiceType.init(chat: chat)
        self.chat = chat
        
        setupBindings()
    }
    
    private func setupBindings() {
        service.openURL = { [weak self] url in
            DispatchQueue.main.async {
                self?.openURL(url)
            }
        }
        
        service.onError = { [weak self] message in
            DispatchQueue.main.async {
                self?.errorMessage = message
                self?.showError = true
            }
        }
        
        service.$chat
            .sink { [weak self] chat in
                self?.chat = chat
            }
            .store(in: &cancellables)
        
        service.$isRecording
            .sink { [weak self] isRecording in
                self?.isRecording = isRecording
            }
            .store(in: &cancellables)
        
        service.$isRecognizing
            .sink { [weak self] isRecognizing in
                self?.isRecognizing = isRecognizing
            }
            .store(in: &cancellables)
        
        service.$responseIsPreparing
            .sink { [weak self] responseIsPreparing in
                self?.responseIsPreparing = responseIsPreparing
            }
            .store(in: &cancellables)
        
        service.$micLevel
            .sink { [weak self] micLevel in
                self?.micLevel = micLevel
            }
            .store(in: &cancellables)
    }
    
    func openURL(_ url: URL, option: UserSettings.URLOpeningOption? = nil) {
        if handleMagicLink(url) { return }
        
        let openingOption = option ?? userSettings.openURLsIn
        
        switch openingOption {
        case .inAppBrowser:
            if SafariView.checkAvailability(at: url) {
                safariViewURL = url
                showSafariView = true
            } else {
                UIApplication.shared.open(url)
            }
        case .defaultApp:
            UIApplication.shared.open(url)
        }
    }
    
    final func handleMagicLink(_ url: URL) -> Bool {
        // Scheme & Host check
        guard url.scheme == "sidesearch",
              url.host == "magiclink"
        else { return false }
        
        // Example: sidesearch://magiclink/?overrideInput=Hello%20World
        
        // Get query items
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems
        
        // overrideInput
        if let overrideInput = queryItems?.first(where: { $0.name == "overrideInput" })?.value {
            service.stopRecording()
            inputText = overrideInput
        }
        
        return true
    }
}
