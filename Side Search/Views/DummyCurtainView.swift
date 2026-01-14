//
//  DummyCurtainView.swift
//  Side Search
//
//  Created by Cizzuk on 2026/01/14.
//

import SwiftUI

struct DummyCurtainView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
                .accessibilityLabel("Close Curtain")
                .accessibility(addTraits: [.isModal, .isButton])
                .accessibilityAction(.escape) { dismiss() }
                .onTapGesture { dismiss() }
        }
    }
}
