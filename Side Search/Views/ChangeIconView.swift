//
//  ChangeIconView.swift
//  Side Search
//
//  Created by Cizzuk on 2026/01/25.
//

import SwiftUI

struct ChangeIconView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    iconItem(iconName: "Side Fish", iconID: "AppIcon")
                    iconItem(iconName: "OG", iconID: "OG")
                    iconItem(iconName: "OG Like", iconID: "OGLike")
                }
            }
            .navigationTitle("Change App Icon")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.fraction(0.9)])
    }
    
    private func iconItem(iconName: String, iconID: String) -> some View {
        HStack {
            Image(iconID + "-pre")
                .resizable()
                .frame(width: 64, height: 64)
                .accessibilityHidden(true)
                .cornerRadius(16)
                .padding(8)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            Text(iconName)
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // Change App Icon
            if iconID == "AppIcon" {
                UIApplication.shared.setAlternateIconName(nil)
            } else {
                UIApplication.shared.setAlternateIconName(iconID)
            }
        }
    }
}
