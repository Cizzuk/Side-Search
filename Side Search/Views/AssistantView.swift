//
//  AssistantView.swift
//  Side Search
//
//  Created by Cizzuk on 2025/12/24.
//

import SwiftUI
import Speech

struct AssistantView: View {
    @Environment(\.dismiss) var dismiss
    @FocusState private var isInputFocused: Bool
    @StateObject private var viewModel = AssistantViewModel()
    
    var body: some View {
        NavigationStack {
            VStack {
                // Search Query
                TextField(viewModel.isRecording ? "Listening..." : "Search with Assistant",
                          text: $viewModel.recognizedText, axis: .vertical)
                    .font(.title)
                    .multilineTextAlignment(.center)
                    .padding()
                    .focused($isInputFocused)
                    .onChange(of: isInputFocused) {
                        if isInputFocused {
                            viewModel.stopRecording()
                        }
                    }
                    .onSubmit {
                        viewModel.performSearch()
                    }
                
                // URL Preview
                Text(viewModel.SearchEngine.url)
                    .lineLimit(1)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                
                Spacer()
                
                // Search Button
                Button(action: {
                    viewModel.performSearch()
                }) {
                    Label("Search", systemImage: "magnifyingglass")
                        .labelStyle(.iconOnly)
                        .font(.system(size: 30))
                        .padding(30)
                        .background(viewModel.recognizedText.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                        .glassEffect()
                }
                .buttonStyle(.plain)
                .disabled(viewModel.recognizedText.isEmpty)
                .opacity(viewModel.recognizedText.isEmpty ? 0.5 : 1.0)
                
                Spacer()
            }
            .accessibilityAction(.escape) { dismiss() }
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        if viewModel.isRecording {
                            viewModel.stopRecording()
                        } else {
                            viewModel.startRecording()
                        }
                    } label: {
                        Label(viewModel.isRecording ? "Stop Speech Recognition" : "Start Speech Recognition",
                              systemImage: viewModel.isRecording ? "mic" : "mic.slash")
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    } label: {
                        Label("Done", systemImage: "checkmark")
                    }
                }
            }
            .fullScreenCover(isPresented: $viewModel.shouldShowSafari, onDismiss: {
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
    }
}
