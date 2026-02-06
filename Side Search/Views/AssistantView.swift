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
    
    @Environment(\.dismiss) var dismiss
    @FocusState private var isInputFocused: Bool
    
    private let assistantType = AssistantType.current
    @StateObject private var viewModel: AssistantViewModel
    
    init() {
        _viewModel = StateObject(wrappedValue: AssistantType.current.makeAssistantViewModel())
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
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        }
                        
                        VStack(alignment: .leading) {
                            Text(AssistantMessage.From.user.displayName)
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            Spacer(minLength: 15)
                            
                            TextField(viewModel.isRecording ? "Listening..." : "Ask Assistant",
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
            .accessibilityAction(.escape) { dismiss() }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark") {
                        dismiss()
                    }
                }
                ToolbarItemGroup(placement: .primaryAction) {
                    Button {
                        if viewModel.isRecording {
                            viewModel.stopRecording()
                        } else {
                            viewModel.startRecording()
                        }
                    } label: {
                        Label(viewModel.isRecording ? "Stop Speech Recognition" : "Start Speech Recognition",
                              systemImage: viewModel.isRecording ? "microphone.fill" : "microphone")
                    }
                    .tint(viewModel.isRecording ? .orange : .primary)
                    
                    Button(action: {
                        viewModel.confirmInput()
                    }) {
                        Label("Confirm", systemImage: assistantType.DescriptionProviderType.assistantSystemImage)
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
                        dismiss()
                    }
                }
            } message: {
                Text(viewModel.errorMessage)
            }
            .onAppear {
                viewModel.onDismiss = { dismiss() }
                viewModel.startAssistant()
            }
            .onDisappear() {
                viewModel.stopRecording()
            }
            .onReceive(NotificationCenter.default.publisher(for: .activateIntentDidActivate)) { _ in
                viewModel.activateAssistant()
            }
        }
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
        .animation(.smooth, value: viewModel.micLevel)
        .presentationDetents(AssistantViewModel.DetentOption.allOption, selection: $viewModel.detent)
        .presentationContentInteraction(.scrolls)
    }
}
