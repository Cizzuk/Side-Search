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
                //                // Search Query
                //                TextField(viewModel.isRecording ? "Listening..." : "Search with Assistant",
                //                          text: $viewModel.recognizedText, axis: .vertical)
                //                    .font(.title)
                //                    .multilineTextAlignment(.center)
                //                    .padding()
                //                    .focused($isInputFocused)
                //                    .onChange(of: isInputFocused) {
                //                        if isInputFocused {
                //                            viewModel.stopRecording()
                //                        }
                //                    }
                //                    .onSubmit {
                //                        viewModel.performSearch()
                //                    }
                
                //                // URL Preview
                //                Text(viewModel.SearchEngine.url)
                //                    .lineLimit(1)
                //                    .font(.caption)
                //                    .foregroundColor(.secondary)
                //                    .padding(.horizontal, 10)
                
                //                Spacer()
                //
                //                // Search Button
                //                Button(action: {
                //                    viewModel.performSearch()
                //                }) {
                //                    Label("Search", systemImage: "magnifyingglass")
                //                        .labelStyle(.iconOnly)
                //                        .font(.system(size: 30))
                //                        .frame(width: 80, height: 90)
                //                }
                //                .tint(.dropblue)
                //                .buttonStyle(.glassProminent)
                //                .foregroundColor(.white)
                //                .disabled(!isSearchable)
                //                .opacity(isSearchable ? 1.0 : 0.8)
                //
                
                TextField(viewModel.isRecording ? "Listening..." : "Ask to Assistant",
                          text: $viewModel.recognizedText, axis: .vertical)
                .font(.headline)
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
                    viewModel.performSearch()
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .animation(.default, value: isSearchable)
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
                        viewModel.performSearch()
                    }) {
                        Label("Search", systemImage: "magnifyingglass")
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
        .background(LinearGradient(
            colors: [Color.clear.opacity(0),
                     Color.dropblue.opacity(0.15 + viewModel.bgIllumination*0.25)],
            startPoint: UnitPoint(x: 0.5, y: (0.0 - viewModel.bgIllumination)),
            endPoint: .bottom
        ).ignoresSafeArea())
        .animation(.smooth, value: viewModel.bgIllumination)
        .presentationDetents([.fraction(0.3), .medium, .large])
    }
    
    private var isSearchable: Bool {
        // If no query is needed, always searchable
        if !AssistantSupport.needQueryInput() {
            return true
        }
        
        // Check if recognized text is empty
        if viewModel.recognizedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return false
        }
            
        return true
    }
}
