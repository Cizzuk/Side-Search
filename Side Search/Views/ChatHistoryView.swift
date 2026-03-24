//
//  ChatHistoryView.swift
//  Side Search
//
//  Created by Cizzuk on 2026/02/08.
//

import SwiftUI

struct ChatHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    
    @StateObject var viewModel = ChatHistoryViewModel()
    @StateObject private var userSettings = UserSettings.shared
    
    @State private var showClearAllHistoryAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                if viewModel.searchQuery.isEmpty {
                    // Full history
                    Section {
                        Toggle("Enable Chat History", isOn: $userSettings.chatHistoryEnabled)
                    }
                    ChatLinkList(viewModel: viewModel, chats: viewModel.chats)
                } else {
                    if viewModel.searchResults.isEmpty {
                        // No search results
                        Section {} footer: {
                            VStack {
                                Label("No Results", systemImage: "magnifyingglass")
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .font(.headline)
                                Spacer()
                                Text("for \"\(viewModel.searchQuery)\".")
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .font(.caption)
                            }
                        }
                    } else {
                        // Search results
                        ChatLinkList(viewModel: viewModel, chats: viewModel.searchResults)
                    }
                }
            }
            .searchable(text: $viewModel.searchQuery)
            .animation(.default, value: viewModel.chats.count)
            .navigationTitle("Chat History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Label("Close", systemImage: "xmark")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showClearAllHistoryAlert = true }) {
                        Label("Clear All", systemImage: "minus.circle")
                    }
                    .tint(.red)
                    .confirmationDialog(
                        "Clear All Chat History",
                        isPresented: $showClearAllHistoryAlert
                    ) {
                        Button("Cancel", role: .cancel) {}
                        Button("Clear", role: .destructive) {
                            viewModel.clearAll()
                        }
                    } message: {
                        Text("This will clear all chat history. This action cannot be undone.")
                    }
                }
            }
            // MARK: - Events
            .onAppear() {
                viewModel.loadChats()
            }
        }
    }
    
    // MARK: - Chat Link List
    
    struct ChatLinkList: View {
        @ObservedObject var viewModel: ChatHistoryViewModel
        var chats: [ChatHistory.Chat]
        
        var body: some View {
            ForEach(chats) { chat in
                NavigationLink(destination: AssistantView(chat: chat, autoActivate: false, useNavigationBackButton: true)) {
                    VStack(alignment: .leading) {
                        Text(chat.previewText)
                            .font(.headline)
                            .lineLimit(2)
                        Spacer()
                        HStack {
                            Text(chat.date, style: .date)
                            Spacer()
                            Text(chat.assistantType.DescriptionProviderType.assistantName)
                        }
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    }
                }
                .contextMenu {
                    Button(role: .destructive) {
                        viewModel.delete(chat.id)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let chat = chats[index]
                    viewModel.delete(chat.id)
                }
            }
        }
    }
}
