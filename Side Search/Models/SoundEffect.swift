//
//  SoundEffect.swift
//  Side Search
//
//  Created by Cizzuk on 2026/03/24.
//

import AVFoundation
import CoreHaptics
import UIKit

final class SoundEffect {
    static let shared = SoundEffect()
    
    var engine: CHHapticEngine?
    
    enum Mode: String, CaseIterable, Identifiable {
        case always
        case backgroundOnly
        case off
        
        var id: String { self.rawValue }
        
        static var `default`: Mode {
            return .always
        }
        
        var displayName: LocalizedStringResource {
            switch self {
            case .always:
                return "Always On"
            case .backgroundOnly:
                return "Background Only"
            case .off:
                return "Off"
            }
        }
    }
    
    enum Sounds {
        case startRecognition
        case completeRecognition
        
        var filename: String {
            switch self {
            case .startRecognition:
                return "startRecognition"
            case .completeRecognition:
                return "completeRecognition"
            }
        }
    }
    
    private init() {
        do {
            let session = AVAudioSession.sharedInstance()
            engine = try CHHapticEngine(audioSession: session)
        } catch let error {
            print("CHHapticEngine Creation Error: \(error)")
        }
        
        guard let engine = engine else {
            print("Failed to create engine!")
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            try? engine.start()
        }
    }
    
    func play(_ sound: SoundEffect.Sounds) {
        guard let engine = engine else { return }
        
        switch UserSettings.shared.soundEffectsMode {
        case .always:
            break
        case .backgroundOnly:
            guard UIApplication.shared.applicationState != .active else { return }
        case .off:
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            guard let path = Bundle.main.path(forResource: sound.filename, ofType: "ahap") else {
                print("AHAP file not found for sound: \(sound).")
                return
            }
            
            do {
                
                try engine.playPattern(from: URL(fileURLWithPath: path))
            } catch {
                print("Failed to play AHAP (\(sound)): \(error).")
            }
        }
    }
}
