//
//  HapticManager.swift
//  Side Search
//
//  Created by Cizzuk on 2026/03/24.
//

import AVFoundation
import CoreHaptics

final class HapticManager {
    static let shared = HapticManager()
    
    var engine: CHHapticEngine?
    
    enum Sounds {
        case recognitionStart
        case recognitionStop
        case recognitionComplete
        
        var filename: String {
            switch self {
            case .recognitionStart:
                return "recognitionStart"
            case .recognitionStop:
                return "recognitionStop"
            case .recognitionComplete:
                return "recognitionComplete"
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
    
    func play(_ sound: HapticManager.Sounds) {
        guard let engine = engine else { return }
        
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
