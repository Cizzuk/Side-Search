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
    
    @StateObject private var vm: AssistantViewModel
    
    private let autoActivate: Bool
    private let useNavigationBackButton: Bool
    
    init(
        chat: ChatHistorySupport.Chat? = nil,
        autoActivate: Bool = true,
        useNavigationBackButton: Bool = false
    ) {
        _vm = StateObject(wrappedValue: AssistantViewModel(chat: chat))
        self.autoActivate = autoActivate
        self.useNavigationBackButton = useNavigationBackButton
    }
    
    func dismissView() {
        guard !isAssistiveAccessEnabled else { return }
        vm.dismissAssistant()
        dismiss()
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
            .onChange(of: vm.inputText) {
                if vm.isRecording {
                    withAnimation {
                        proxy.scrollTo("scrollAnchor", anchor: .bottom)
                    }
                }
            }
            .onChange(of: vm.chat.messages.count) {
                withAnimation {
                    if let lastMessage = vm.chat.messages.last {
                        if lastMessage.from == .user {
                            proxy.scrollTo("scrollAnchor", anchor: .bottom)
                        } else {
                            proxy.scrollTo(lastMessage.id, anchor: .top)
                        }
                    }
                }
            }
        }
        .animation(.smooth, value: vm.inputText)
        .animation(.smooth, value: vm.chat.messages.count)
        // MARK: - Toolbar
        .toolbar { toolbarContent }
        .safeAreaInset(edge: .bottom) { keyboardToolbar }
        // MARK: - Sheets & Alerts
        .fullScreenCover(isPresented: $vm.showSafariView) {
            if let url = vm.safariViewURL {
                SafariView(url: url)
                    .ignoresSafeArea()
            }
        }
        .alert("Error", isPresented: $vm.showError) {
            Button("OK") { }
        } message: {
            Text(vm.errorMessage)
        }
        // MARK: - Events
        .onAppear {
            vm.scenePhaseUpdate(scenePhase)
            if autoActivate { vm.activateAssistant() }
        }
        .onDisappear() {
            vm.dismissAssistant()
        }
        .onReceive(NotificationCenter.default.publisher(for: .assistantDidActivate)) { _ in
            vm.activateAssistant()
        }
        .onReceive(vm.$shouldDismiss) { shouldDismiss in
            if shouldDismiss { dismiss() }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            withAnimation { isKeyboardVisible = true }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            isKeyboardVisible = false
        }
        .onChange(of: scenePhase) { vm.scenePhaseUpdate(scenePhase) }
        // MARK: - View Styles
        .background(
            AngularGradient(
                gradient: vm.chat.assistantType.DescriptionProviderType.assistantGradient,
                center: .center,
                angle: .degrees(180*Double(vm.micLevel) * (reduceMotion ? 0 : 1))
            )
            .ignoresSafeArea()
            .opacity((0.15 + Double(vm.micLevel)/4) * (colorSchemeContrast == .increased ? 0.5 : 1))
            .blur(radius: 30)
            .animation(.smooth, value: vm.micLevel)
        )
        .navigationBarBackButtonHidden(!useNavigationBackButton)
        .accessibilityAction(.escape) { dismissView() }
        .accessibilityAction(.magicTap) {
            NotificationCenter.default.post(name: .assistantDidActivate, object: nil)
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var assistantScrollContent: some View {
        VStack(alignment: .leading, spacing: 45) {
            ForEach(vm.chat.messages) { message in
                MessagesView(
                    message: message,
                    openURL: { url in vm.openURL(url) },
                )
            }
            
            if vm.responseIsPreparing {
                HStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    Text("Waiting for Assistant...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            inputSection
            
            Group {
                if vm.isEnded {
                    Text("The assistant has ended the conversation.")
                }
                
                if vm.chat.assistantType.DescriptionProviderType.assistantIsAI {
                    Text("This assistant is AI and can make mistakes.")
                }
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            .opacity(0.7)
            .frame(maxWidth: .infinity, alignment: .center)
            
            Spacer(minLength: 50)
        }
    }
    
    @ViewBuilder
    private var inputSection: some View {
        if vm.isAssistantAvailable {
            VStack(alignment: .leading) {
                Text(AssistantMessage.From.user.displayName)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Spacer(minLength: 15)
                
                let assistantState: LocalizedStringResource = {
                    if vm.isRecognizing {
                        "Listening..."
                    } else if vm.isRecording {
                        "Recognition Paused"
                    } else {
                        "Ask Assistant"
                    }
                }()
                TextField(assistantState, text: $vm.inputText, axis: .vertical)
                .bold()
                .submitLabel(.return)
                .focused($isInputFocused)
                .onSubmit { vm.confirmInput() }
                .onChange(of: isInputFocused) {
                    if isInputFocused { vm.stopRecording() }
                }
                .onChange(of: vm.shouldFocusInput) {
                    Task { isInputFocused = true }
                }
                .onChange(of: vm.shouldUnfocusInput) {
                    Task { isInputFocused = false }
                }
                
                // Assistive Access
                if isAssistiveAccessEnabled {
                    Spacer(minLength: 30)
                    Button(action: { vm.toggleRecording() }) {
                        Label(vm.isRecording ? "Stop" : "Speak",
                              systemImage: vm.isRecognizing ? "microphone.fill" : "microphone")
                    }
                    .disabled(vm.responseIsPreparing)
                    
                    Button(role: .confirm) {
                        vm.confirmInput()
                    } label: {
                        Label("OK", systemImage: "checkmark")
                    }
                    .buttonStyle(.glassProminent)
                    .disabled(vm.responseIsPreparing)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAction(named: "Confirm") {
                vm.confirmInput()
            }
        }
    }
    
    // MARK: - Toolbars
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if !isAssistiveAccessEnabled {
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
                if vm.isAssistantAvailable {
                    Button(action: { vm.toggleRecording() }) {
                        Label(vm.isRecording ? "Stop Microphone" : "Start Speech Recognition",
                              systemImage: vm.isRecognizing ? "microphone.fill" : "microphone")
                    }
                    .tint(vm.isRecording ? .orange : .primary)
                    
                    Button(role: .confirm) {
                        vm.confirmInput()
                    } label: {
                        Label { Text("Confirm") }
                        icon: { vm.chat.assistantType.DescriptionProviderType.assistantImage }
                            .foregroundStyle(.white)
                    }
                    .tint(.dropblue)
                    .buttonStyle(.glassProminent)
                    .disabled(vm.responseIsPreparing)
                }
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
                    vm.confirmInput()
                } label: {
                    Label("Submit", systemImage: "checkmark")
                        .labelStyle(.iconOnly)
                        .font(.title3)
                        .frame(minWidth: 30, minHeight: 30)
                }
                .tint(.dropblue)
                .buttonStyle(.glassProminent)
                .disabled(vm.responseIsPreparing)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
}

//#Preview(traits: .assistiveAccess) {
//    AssistantView()
//}
