//
//  AssistantView.swift
//  Side Search
//
//  Created by Cizzuk on 2025/12/24.
//

import SwiftUI

struct AssistantView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.accessibilityAssistiveAccessEnabled) private var isAssistiveAccessEnabled
    
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) var dismiss
    @FocusState private var isInputFocused: Bool
    @State private var isKeyboardVisible = false
    
    @StateObject private var viewModel: AssistantViewModel
    
    private let autoActivate: Bool
    private let useNavigationBackButton: Bool
    
    init(
        chat: ChatHistory.Chat? = nil,
        autoActivate: Bool = true,
        useNavigationBackButton: Bool = false
    ) {
        _viewModel = StateObject(wrappedValue: AssistantViewModel.make(chat: chat))
        self.autoActivate = autoActivate
        self.useNavigationBackButton = useNavigationBackButton
    }
    
    func dismissView() {
        viewModel.dismissAssistant(fromView: true)
        dismiss()
    }
    
    private var isAssistantAvailable: Bool {
        viewModel.checkAvailability(shouldShowError: false)
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                assistantScrollContent
                    .id("scrollAnchor")
                    .padding(.horizontal, 25)
                    .padding(.top, 10)
                    .padding(.bottom, 0)
            }
            .onChange(of: viewModel.inputText) {
                if viewModel.isRecording {
                    withAnimation {
                        proxy.scrollTo("scrollAnchor", anchor: .bottom)
                    }
                }
            }
            .onChange(of: viewModel.chat.messages.count) {
                withAnimation {
                    if let lastMessage = viewModel.chat.messages.last {
                        if lastMessage.from == .user {
                            proxy.scrollTo("scrollAnchor", anchor: .bottom)
                        } else {
                            proxy.scrollTo(lastMessage.id, anchor: .top)
                        }
                    }
                }
            }
        }
        .animation(.smooth, value: viewModel.inputText)
        .animation(.smooth, value: viewModel.chat.messages.count)
        .scrollDismissesKeyboard(.interactively)
        // MARK: - Toolbar
        .toolbar { toolbarContent }
        .safeAreaInset(edge: .bottom) { keyboardToolbar }
        // MARK: - Sheets & Alerts
        .fullScreenCover(isPresented: $viewModel.showSafariView) {
            if let url = viewModel.searchURL {
                SafariView(url: url)
                    .ignoresSafeArea()
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage)
        }
        // MARK: - Events
        .onAppear {
            viewModel.currentScenePhase = scenePhase
            if autoActivate { viewModel.activateAssistant() }
        }
        .onDisappear() {
            viewModel.dismissAssistant(fromView: true)
        }
        .onReceive(NotificationCenter.default.publisher(for: .assistantDidActivate)) { _ in
            viewModel.activateAssistant()
        }
        .onReceive(viewModel.$shouldDismiss) { shouldDismiss in
            if shouldDismiss { dismiss() }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            withAnimation { isKeyboardVisible = true }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            isKeyboardVisible = false
        }
        .onChange(of: scenePhase) { viewModel.onChange(scenePhase: scenePhase) }
        // MARK: - View Styles
        .background(
            AngularGradient(
                gradient: viewModel.chat.assistantType.DescriptionProviderType.assistantGradient,
                center: .center,
                angle: .degrees(180*Double(viewModel.micLevel) * (reduceMotion ? 0 : 1))
            )
            .ignoresSafeArea()
            .opacity((0.15 + Double(viewModel.micLevel)/4) * (colorSchemeContrast == .increased ? 0.5 : 1))
            .blur(radius: 30)
        )
        .navigationBarBackButtonHidden(!useNavigationBackButton)
        .animation(.smooth, value: viewModel.micLevel)
        .accessibilityAction(.escape) { dismissView() }
        .accessibilityAction(.magicTap) {
            NotificationCenter.default.post(name: .assistantDidActivate, object: nil)
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var assistantScrollContent: some View {
        VStack(alignment: .leading, spacing: 45) {
            ForEach(viewModel.chat.messages) { message in
                MessagesView(message: message, openSafariView: { url in
                    viewModel.openSafariView(at: url)
                })
            }
            
            if viewModel.responseIsPreparing {
                HStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    Text("Waiting for assistant...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            inputSection
            
            if viewModel.chat.assistantType.DescriptionProviderType.assistantIsAI {
                Text("This assistant is AI and can make mistakes.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .opacity(0.7)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            
            Spacer(minLength: 50)
        }
    }
    
    @ViewBuilder
    private var inputSection: some View {
        if isAssistantAvailable {
            VStack(alignment: .leading) {
                Text(AssistantMessage.From.user.displayName)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Spacer(minLength: 15)
                
                TextField(viewModel.isRecognizing ? "Listening..." : "Ask Assistant",
                          text: $viewModel.inputText, axis: .vertical)
                .bold()
                .submitLabel(.return)
                .focused($isInputFocused)
                .onSubmit {
                    viewModel.confirmInput()
                }
                .onChange(of: isInputFocused) {
                    if isInputFocused {
                        viewModel.stopRecording()
                    }
                }
                .onChange(of: viewModel.shouldFocusInput) {
                    Task {
                        isInputFocused = true
                    }
                }
                .onChange(of: viewModel.shouldUnfocusInput) {
                    Task {
                        isInputFocused = false
                    }
                }
                
                // Assistive Access
                if isAssistiveAccessEnabled {
                    Spacer(minLength: 30)
                    Button(action: { viewModel.toggleRecording() }) {
                        Label(viewModel.isRecognizing ? "Stop" : "Speak",
                              systemImage: viewModel.isRecognizing ? "microphone.fill" : "microphone")
                    }
                    .disabled(viewModel.responseIsPreparing)
                    
                    Button(role: .confirm) {
                        viewModel.confirmInput()
                    } label: {
                        Label("OK", systemImage: "checkmark")
                    }
                    .buttonStyle(.glassProminent)
                    .disabled(viewModel.responseIsPreparing)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAction(named: "Confirm") {
                viewModel.confirmInput()
            }
        }
    }
    
    // MARK: - Toolbars
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            if !useNavigationBackButton {
                Button(role: .close) {
                    dismissView()
                } label: {
                    Label("End Assistant", systemImage: "xmark")
                }
            }
        }
        
        ToolbarItemGroup(placement: .primaryAction) {
            if isAssistantAvailable {
                Button(action: { viewModel.toggleRecording() }) {
                    Label(viewModel.isRecording ? "Stop Speech Recognition" : "Start Speech Recognition",
                          systemImage: viewModel.isRecording ? "microphone.fill" : "microphone")
                }
                .tint(viewModel.isRecording ? .orange : .primary)
                
                Button(role: .confirm) {
                    viewModel.confirmInput()
                } label: {
                    Label("Confirm", systemImage: viewModel.chat.assistantType.DescriptionProviderType.assistantSystemImage)
                        .foregroundStyle(.white)
                }
                .tint(.dropblue)
                .buttonStyle(.glassProminent)
                .disabled(viewModel.responseIsPreparing)
            }
        }
    }
    
    @ViewBuilder
    private var keyboardToolbar: some View {
        if isKeyboardVisible && !isAssistiveAccessEnabled {
            HStack {
                Button(role: .close) {
                    isInputFocused = false
                } label: {
                    Label("Dismiss Keyboard", systemImage: "keyboard.chevron.compact.down")
                        .labelStyle(.iconOnly)
                        .font(.title3)
                        .frame(minWidth: 30, minHeight: 30)
                }
                .buttonStyle(.glass)
                
                Spacer()
                Button(role: .confirm) {
                    viewModel.confirmInput()
                } label: {
                    Label("Submit", systemImage: "checkmark")
                        .labelStyle(.iconOnly)
                        .font(.title3)
                        .frame(minWidth: 30, minHeight: 30)
                }
                .tint(.dropblue)
                .buttonStyle(.glassProminent)
                .disabled(viewModel.responseIsPreparing)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
}

#Preview(traits: .assistiveAccess) {
    AssistantView()
}
