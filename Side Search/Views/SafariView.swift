//
//  SafariView.swift
//  Side Search
//
//  Created by Cizzuk on 2025/12/24.
//

import SwiftUI
import SafariServices
import TemporaryScreenCurtain

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    static func checkAvailability(at url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased(), (scheme == "http" || scheme == "https") else {
            return false
        }
        return true
    }

    func makeUIViewController(context: Context) -> UIViewController {
        // Check URL
        guard SafariView.checkAvailability(at: url) else {
            UIApplication.shared.open(url)
            return UIHostingController(rootView: TemporaryScreenCurtain())
        }
        
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        config.barCollapsingEnabled = true
        
        let safari = SFSafariViewController(url: url, configuration: config)
        safari.dismissButtonStyle = .close
        safari.modalPresentationStyle = .overFullScreen
        return safari
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) { }
}
