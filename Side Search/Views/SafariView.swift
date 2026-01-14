//
//  SafariView.swift
//  Side Search
//
//  Created by Cizzuk on 2025/12/24.
//

import SwiftUI
import SafariServices

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIViewController {
        // Check URL
        if let scheme = url.scheme?.lowercased(), scheme != "http" && scheme != "https" {
            UIApplication.shared.open(url)
            // TODO: Replace Curtain
            return UIViewController()
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
