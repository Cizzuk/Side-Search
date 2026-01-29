//
//  SwitchAssistantView.swift
//  Side Search
//
//  Created by Cizzuk on 2026/01/25.
//

import SwiftUI

struct SwitchAssistantView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var currentAssistant: AssistantType
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(AssistantType.allCases.filter { !$0.DescriptionProviderType.isBlocked() },
                            id: \.self) { type in
                        Button() {
                            currentAssistant = type
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text(type.DescriptionProviderType.assistantName)
                                        .font(.title3)
                                    Spacer()
                                    Image(systemName: type.DescriptionProviderType.assistantSystemImage)
                                        .font(.title3)
                                        .foregroundStyle(
                                            AngularGradient(
                                                gradient: type.DescriptionProviderType.assistantGradient,
                                                center: .center
                                            )
                                        )
                                }
                                Text(type.DescriptionProviderType.assistantDescription)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .accessibilityHidden(true)
                            }
                        }
                        .foregroundColor(.primary)
                        .accessibility(addTraits: currentAssistant == type ? [.isSelected] : [])
                        .accessibilityHint(type.DescriptionProviderType.assistantDescription)
                        .disabled(!type.DescriptionProviderType.isAvailable())
                    }
                }
            }
            .navigationTitle("Switch Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Label("Cancel", systemImage: "xmark")
                    }
                }
            }
        }
        .presentationDetents([.fraction(0.9)])
    }
}
