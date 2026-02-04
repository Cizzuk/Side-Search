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
    @State private var detent: PresentationDetent = .medium
    @FocusState private var isInputFocused: Bool
    @StateObject private var viewModel: AssistantViewModel
    
    init() {
        _viewModel = StateObject(wrappedValue: AssistantType.current.makeAssistantViewModel())
    }
    
    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 25) {
                        ForEach(viewModel.messageHistory) { message in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(message.from.displayName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(message.content)
                                    .font(.title3)
                                    .textSelection(.enabled)
                                Spacer()
                                ForEach(message.sources, id: \.url) { source in
                                    Button(action: { viewModel.openSafariView(at: source.url) }) {
                                        Label(source.title, systemImage: "link")
                                            .font(.caption)
                                    }
                                }
                            }
                            .id(message.id)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        if viewModel.responseIsPreparing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(AssistantViewModel.MessageFrom.user.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField(viewModel.isRecording ? "Listening..." : "Ask Assistant",
                                      text: $viewModel.inputText, axis: .vertical)
                            .font(.title3)
                            .bold()
                            .submitLabel(.return)
                            .focused($isInputFocused)
                            .onSubmit {
                                viewModel.confirmInput()
                            }
                            .onChange(of: isInputFocused) {
                                if isInputFocused {
                                    viewModel.stopRecording()
                                    detent = .large
                                }
                            }
                            .onChange(of: viewModel.shouldInputFocused) {
                                if viewModel.shouldInputFocused {
                                    isInputFocused = true
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 50)
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
                        Label("Confirm", systemImage: AssistantType.current.DescriptionProviderType.assistantSystemImage)
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
                gradient: AssistantType.current.DescriptionProviderType.assistantGradient,
                center: .center,
                angle: .degrees(180*Double(viewModel.micLevel) * (reduceMotion ? 0 : 1))
            )
            .ignoresSafeArea()
            .opacity((0.15 + Double(viewModel.micLevel)/4) * (colorSchemeContrast == .increased ? 0.5 : 1))
            .blur(radius: 30)
        )
        .animation(.smooth, value: viewModel.micLevel)
        .presentationDetents([.medium, .fraction(0.3), .large], selection: $detent)
        .presentationContentInteraction(.scrolls)
    }
}
