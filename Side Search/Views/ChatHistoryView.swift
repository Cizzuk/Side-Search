//
//  ChatHistoryView.swift
//  Side Search
//
//  Created by Cizzuk on 2026/02/08.
//

import SwiftUI

struct ChatHistoryView: View {
    @StateObject var vm = ChatHistoryViewModel()
    @StateObject private var userSettings = UserSettings.shared
    
    @State private var showClearAllHistoryAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                if vm.searchQuery.isEmpty {
                    // Full history
                    Section {
                        Toggle("Enable Chat History", isOn: $userSettings.chatHistoryEnabled)
                            .tint(.accent)
                    }
                    ChatLinkList(vm: vm, chats: vm.chats)
                } else {
                    if vm.searchResults.isEmpty {
                        // No search results
                        Section {} footer: {
                            VStack {
                                Label("No Results", systemImage: "magnifyingglass")
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .font(.headline)
                                Spacer()
                                Text("for \"\(vm.searchQuery)\".")
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .font(.caption)
                            }
                        }
                    } else {
                        // Search results
                        ChatLinkList(vm: vm, chats: vm.searchResults)
                    }
                }
            }
            .searchable(text: $vm.searchQuery)
            .animation(.default, value: vm.chats.count)
            .navigationTitle("Chat History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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
                            vm.clearAll()
                        }
                    } message: {
                        Text("This will clear all chat history. This action cannot be undone.")
                    }
                }
            }
            // MARK: - Events
            .onAppear() {
                vm.loadChats()
            }
        }
    }
    
    // MARK: - Chat Link List
    
    struct ChatLinkList: View {
        @ObservedObject var vm: ChatHistoryViewModel
        var chats: [ChatHistorySupport.Chat]
        
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
                            Text(chat.assistantType.displayName)
                        }
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                }
                .contextMenu {
                    Button(role: .destructive) {
                        vm.delete(chat.id)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let chat = chats[index]
                    vm.delete(chat.id)
                }
            }
        }
    }
}
