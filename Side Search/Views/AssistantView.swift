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
    @StateObject private var viewModel: AssistantViewModel
    
    init() {
        _viewModel = StateObject(wrappedValue: AssistantType.current.makeAssistantViewModel())
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                TextField(viewModel.isRecording ? "Listening..." : "Ask to Assistant",
                          text: $viewModel.inputText, axis: .vertical)
                .font(.headline)
                .padding(.horizontal)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .submitLabel(.return)
                .focused($isInputFocused)
                .onChange(of: isInputFocused) {
                    if isInputFocused {
                        viewModel.stopRecording()
                    }
                }
                .onChange(of: viewModel.shouldInputFocused) {
                    if viewModel.shouldInputFocused {
                        isInputFocused = true
                    }
                }
                .onSubmit {
                    viewModel.confirmInput()
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .accessibilityAction(.escape) { dismiss() }
            .padding()
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
                }
            }
            .fullScreenCover(isPresented: $viewModel.showSafariView, onDismiss: {
                dismiss()
            }) {
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
        .presentationDetents([.fraction(0.3), .large])
    }
}
