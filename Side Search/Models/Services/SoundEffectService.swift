//
//  SoundEffectService.swift
//  Side Search
//
//  Created by Cizzuk on 2026/03/24.
//

import AppIntents
import AVFoundation
import CoreHaptics
import UIKit

final class SoundEffectService {
    static let shared = SoundEffectService()
    
    var engine: CHHapticEngine?
    
    enum Mode: String, CaseIterable, Identifiable, AppEnum {
        case always
        case backgroundOnly
        case off
        
        var id: String { self.rawValue }
        
        static var `default`: Mode {
            return .always
        }
        
        static var typeDisplayRepresentation: TypeDisplayRepresentation {
            TypeDisplayRepresentation(name: "Sound Effects Mode")
        }
        
        static let caseDisplayRepresentations: [Self : DisplayRepresentation] = [
            .always: "Always On",
            .backgroundOnly: "Background Only",
            .off: "Off"
        ]
        
        var displayName: LocalizedStringResource {
            return Self.caseDisplayRepresentations[self]?.title ?? ""
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
        
        var filename_nosound: String {
            switch self {
            case .startRecognition:
                return "startRecognition_nosound"
            case .completeRecognition:
                return "completeRecognition_nosound"
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
    }
    
    func play(_ sound: SoundEffectService.Sounds) {
        guard let engine = engine else { return }
        
        let mode = UserSettings.shared.soundEffectsMode
        
        DispatchQueue.global(qos: .userInitiated).async {
            let filepath: String?
            
            switch mode {
            case .always:
                filepath = Bundle.main.path(forResource: sound.filename, ofType: "ahap")
            case .backgroundOnly:
                if UIApplication.shared.applicationState == .background {
                    filepath = Bundle.main.path(forResource: sound.filename, ofType: "ahap")
                } else {
                    filepath = Bundle.main.path(forResource: sound.filename_nosound, ofType: "ahap")
                }
            case .off:
                filepath = Bundle.main.path(forResource: sound.filename_nosound, ofType: "ahap")
            }
            
            guard let filepath else {
                print("AHAP file not found for sound: \(sound).")
                return
            }
            
            do {
                try engine.start()
                try engine.playPattern(from: URL(fileURLWithPath: filepath))
            } catch {
                print("Failed to play AHAP (\(sound)): \(error).")
            }
        }
    }
}
