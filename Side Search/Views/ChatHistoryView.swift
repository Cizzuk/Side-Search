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
    @State private var showClearAllHistoryAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle("Enable Chat History", isOn: $viewModel.chatHistoryEnabled)
                }
                
                ForEach(viewModel.chats) { chat in
                    NavigationLink(destination: ChatDetailView(viewModel: viewModel, chat: chat)) {
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
                        let chat = viewModel.chats[index]
                        viewModel.delete(chat.id)
                    }
                }
            }
            .animation(.default, value: viewModel.chats.count)
            .onAppear() {
                viewModel.loadChats()
            }
            // Clear All Chat History Alert
            .alert(isPresented: $showClearAllHistoryAlert) {
                Alert(
                    title: Text("Clear All Chat History"),
                    message: Text("Are you sure you want to clear all chat history?"),
                    primaryButton: .destructive(Text("Clear")) {
                        viewModel.clearAll()
                    },
                    secondaryButton: .cancel()
                )
            }
            .fullScreenCover(isPresented: $viewModel.showSafariView) {
                if let url = viewModel.searchURL {
                    SafariView(url: url)
                        .ignoresSafeArea()
                }
            }
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
                }
            }
        }
    }
    
    struct ChatDetailView: View {
        @Environment(\.dismiss) private var dismiss
        @StateObject var viewModel: ChatHistoryViewModel
        var chat: ChatHistory.Chat
        
        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 45) {
                    ForEach(chat.messages) { message in
                        MessagesView(message: message, openSafariView: { url in
                            viewModel.openSafariView(at: url)
                        })
                    }
                }
                .padding(.horizontal, 25)
                .padding(.vertical, 20)
            }
            .navigationTitle(Text(chat.date, style: .date))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) {
                        viewModel.delete(chat.id)
                        dismiss()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .tint(.red)
                }
            }
        }
    }
}
