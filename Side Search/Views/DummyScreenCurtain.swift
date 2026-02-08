//
//  DummyScreenCurtain.swift
//  Side Search
//
//  Created by Cizzuk on 2026/01/14.
//

import SwiftUI

public extension View {
    func dummyScreenCurtain(isPresented: Binding<Bool>) -> some View {
        self
            .opacity(isPresented.wrappedValue ? 0.0 : 1.0)
            .fullScreenCover(isPresented: isPresented, content: {
                DummyScreenCurtainView()
            })
    }
}

public struct DummyScreenCurtainView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss
    
    public var body: some View {
        NavigationStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
                .accessibilityLabel("Close Curtain")
                .accessibility(addTraits: [.isModal, .isButton])
                .accessibilityAction(.escape) { dismiss() }
                .onTapGesture { dismiss() }
                .onChange(of: scenePhase) {
                    if scenePhase == .inactive { dismiss() }
                }
        }
    }
}
