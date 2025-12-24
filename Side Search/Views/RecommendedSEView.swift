//
//  RecommendedSEView.swift
//  Side Search
//
//  Created by Cizzuk on 2025/12/24.
//

import SwiftUI

struct RecommendedSEView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var SearchEngine: SearchEngineModel
    
    private let aiCSEList = RecommendSEs.aiAssistants()
    private let normalCSEList = RecommendSEs.normalSearchEngines()
    
    var body: some View {
        NavigationStack {
            List {
                // AI Assistant List
                if !aiCSEList.isEmpty {
                    Section {
                        ForEach(aiCSEList.indices, id: \.self, content: { index in
                            let cse = aiCSEList[index]
                            RecommendedSEButton(action: {
                                SearchEngine = cse
                                dismiss()
                            }, cse: cse)
                        })
                    } header: { Text("AI Assistants") }
                }
                
                // Normal Search Engine List
                Section {
                    ForEach(normalCSEList.indices, id: \.self, content: { index in
                        let cse = normalCSEList[index]
                        RecommendedSEButton(action: {
                            SearchEngine = cse
                            dismiss()
                        }, cse: cse)
                    })
                } header: { Text("Normal Search Engines") }
            }
            .navigationTitle("Recommended Assistants")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    struct RecommendedSEButton: View {
        let action: () -> Void
        let cse: SearchEngineModel
        
        var body: some View {
            Button {
                action()
            } label: {
                VStack(alignment: .leading) {
                    Text(cse.name)
                        .bold()
                    Text(cse.url)
                        .lineLimit(1)
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
            }
            .accessibilityLabel(cse.name)
            .foregroundColor(.primary)
        }
    }
}

