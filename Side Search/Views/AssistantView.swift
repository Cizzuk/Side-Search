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
    
    private let assistantType = AssistantType.current
    @StateObject private var viewModel: AssistantViewModel
    
    init() {
        _viewModel = StateObject(wrappedValue: AssistantType.current.makeAssistantViewModel())
    }
    
    func dismissView() {
        viewModel.dismissAssistant(fromView: true)
        dismiss()
    }
    
    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 45) {
                        ForEach(viewModel.messageHistory) { message in
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
                                    viewModel.detent = .large
                                }
                            }
                            .onChange(of: viewModel.shouldInputFocused) {
                                if viewModel.shouldInputFocused {
                                    isInputFocused = true
                                }
                            }
                            
                            // Assistive Access Controls
                            if isAssistiveAccessEnabled {
                                Spacer(minLength: 30)
                                Button(action: { viewModel.toggleRecording() }) {
                                    Label(viewModel.isRecognizing ? "Stop" : "Speak",
                                          systemImage: viewModel.isRecognizing ? "microphone.fill" : "microphone")
                                }
                                .disabled(viewModel.responseIsPreparing)
                                
                                Button(action: { viewModel.confirmInput() }) {
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
                        
                        if assistantType.DescriptionProviderType.assistantIsAI {
                            Text("This assistant is AI and can make mistakes.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .opacity(0.7)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        
                        Spacer(minLength: 50)
                    }
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
                .onChange(of: viewModel.messageHistory.count) {
                    withAnimation {
                        if let lastMessage = viewModel.messageHistory.last {
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
            .animation(.smooth, value: viewModel.messageHistory.count)
            .scrollDismissesKeyboard(.interactively)
            .accessibilityAction(.escape) { dismissView() }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismissView() }) {
                        Label("End Assistant", systemImage: "xmark")
                    }
                }
                ToolbarItemGroup(placement: .primaryAction) {
                    Button(action: { viewModel.toggleRecording() }) {
                        Label(viewModel.isRecording ? "Stop Speech Recognition" : "Start Speech Recognition",
                              systemImage: viewModel.isRecording ? "microphone.fill" : "microphone")
                    }
                    .tint(viewModel.isRecording ? .orange : .primary)
                    
                    Button(action: { viewModel.confirmInput() }) {
                        Label("Confirm", systemImage: assistantType.DescriptionProviderType.assistantSystemImage)
                            .foregroundStyle(.white)
                    }
                    .tint(.dropblue)
                    .buttonStyle(.glassProminent)
                    .disabled(viewModel.responseIsPreparing)
                }
            }
            .fullScreenCover(isPresented: $viewModel.showSafariView) {
                if let url = viewModel.searchURL {
                    SafariView(url: url)
                        .ignoresSafeArea()
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") {
                    if viewModel.isCriticalError {
                        viewModel.dismissAssistant()
                    }
                }
            } message: {
                Text(viewModel.errorMessage)
            }
            // MARK: - Events
            .onAppear {
                viewModel.currentScenePhase = scenePhase
                viewModel.startAssistant()
            }
            .onDisappear() {
                viewModel.dismissAssistant(fromView: true)
            }
            .onReceive(NotificationCenter.default.publisher(for: .activateIntentDidActivate)) { _ in
                viewModel.handleActivateIntent()
            }
            .onReceive(viewModel.$shouldDismiss) { shouldDismiss in
                if shouldDismiss { dismiss() }
            }
            .onChange(of: scenePhase) { viewModel.onChange(scenePhase: scenePhase) }
            .background(
                AngularGradient(
                    gradient: assistantType.DescriptionProviderType.assistantGradient,
                    center: .center,
                    angle: .degrees(180*Double(viewModel.micLevel) * (reduceMotion ? 0 : 1))
                )
                .ignoresSafeArea()
                .opacity((0.15 + Double(viewModel.micLevel)/4) * (colorSchemeContrast == .increased ? 0.5 : 1))
                .blur(radius: 30)
            )
        }
        .animation(.smooth, value: viewModel.micLevel)
        .presentationDetents(AssistantViewModel.DetentOption.allOption, selection: $viewModel.detent)
        .presentationContentInteraction(.scrolls)
    }
}

#Preview(traits: .assistiveAccess) {
    AssistantView()
}
