//
//  SearchEnginePresetsView.swift
//  Side Search
//
//  Created by Cizzuk on 2025/12/24.
//

import SwiftUI

struct SearchEnginePresetsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var SearchEngine: URLBasedAssistantModel
    
    private let aiCSEList = SearchEnginePresets.aiAssistants
    private let normalCSEList = SearchEnginePresets.normalSearchEngines
    
    var body: some View {
        NavigationStack {
            List {
                // AI Assistant List
                if !aiCSEList.isEmpty {
                    Section {
                        ForEach(aiCSEList.indices, id: \.self, content: { index in
                            let cse = aiCSEList[index]
                            PresetSEButton(action: {
                                SearchEngine.url = cse.url
                                dismiss()
                            }, cse: cse)
                        })
                    } header: { Text("AI Assistants") }
                }
                
                // Normal Search Engine List
                Section {
                    ForEach(normalCSEList.indices, id: \.self, content: { index in
                        let cse = normalCSEList[index]
                        PresetSEButton(action: {
                            SearchEngine.url = cse.url
                            dismiss()
                        }, cse: cse)
                    })
                } header: { Text("Search Engines") }
            }
            .navigationTitle("Search URL Presets")
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
    
    struct PresetSEButton: View {
        let action: () -> Void
        let cse: SearchEnginePresets.Preset
        
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

