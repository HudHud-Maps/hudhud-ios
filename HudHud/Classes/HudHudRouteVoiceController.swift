//
//  HudHudRouteVoiceController.swift
//  HudHud
//
//  Created by patrick on 17.05.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import AVFAudio
import Foundation
import MapboxCoreNavigation
import MapboxDirections
import MapboxNavigation
import UIKit

// MARK: - HudHudRouteVoiceController

class HudHudRouteVoiceController: RouteVoiceController {

    // MARK: Nested Types

    struct LanguageString {
        let language: LanguageScript
        let string: String
    }

    enum LanguageScript {
        case arabic, other
    }

    // MARK: Properties

    lazy var speechSynth = AVSpeechSynthesizer()

    var lastSpokenInstruction: SpokenInstruction?
    var routeProgress: RouteProgress?

    var volumeToken: NSKeyValueObservation?
    var muteToken: NSKeyValueObservation?

    let arabicVoice = AVSpeechSynthesisVoice(language: "ar-SA")
    let allOtherLanguagesVoice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.Samantha-compact")

    // MARK: Lifecycle

    /**
     Default initializer for `RouteVoiceController`.
     */
    override public init() {
        super.init()
    }

    deinit {
        suspendNotifications()
        speechSynth.stopSpeaking(at: .immediate)
    }

    // MARK: Overridden Functions

    /**
     Reads aloud the given instruction.

     - parameter instruction: The instruction to read aloud.
     - parameter locale: The `Locale` used to create the voice read aloud the given instruction. If `nil` the `Locale.preferredLocalLanguageCountryCode` is used for creating the voice.
     - parameter ignoreProgress: A `Bool` that indicates if the routeProgress is added to the instruction.
     */
    override func speak(_ instruction: SpokenInstruction, with _: Locale?, ignoreProgress _: Bool = false) {
        let localLastSpokenInstruction = self.lastSpokenInstruction

        // Thread performance checker complains if you access the speechSynthesizer on the main thread,
        // so we do speech on a background thread instead.
        DispatchQueue.global(qos: .default).async {
            if self.speechSynth.isSpeaking, let localLastSpokenInstruction {
                self.voiceControllerDelegate?.voiceController?(self, didInterrupt: localLastSpokenInstruction, with: instruction)
            }

            do {
                try self.duckAudio()
            } catch {
                self.voiceControllerDelegate?.voiceController?(self, spokenInstructionsDidFailWith: error)
            }

            let modifiedInstruction = self.voiceControllerDelegate?.voiceController?(self, willSpeak: instruction, routeProgress: self.routeProgress) ?? instruction

            let thingsToSay = self.splitBasedOnScript(string: modifiedInstruction.text)

            for thingToSay in thingsToSay {
                let utterance = AVSpeechUtterance(string: thingToSay.string)
                switch thingToSay.language {
                case .arabic:
                    utterance.voice = self.arabicVoice

                case .other:
                    utterance.voice = self.allOtherLanguagesVoice
                }

                self.speechSynth.speak(utterance)
            }
        }
    }
}

private extension HudHudRouteVoiceController {

    func suspendNotifications() {
        NotificationCenter.default.removeObserver(self, name: .routeControllerDidPassSpokenInstructionPoint, object: nil)
        NotificationCenter.default.removeObserver(self, name: .routeControllerWillReroute, object: nil)
        NotificationCenter.default.removeObserver(self, name: .routeControllerDidReroute, object: nil)
    }

    func duckAudio() throws {
        let categoryOptions: AVAudioSession.CategoryOptions = [.duckOthers, .interruptSpokenAudioAndMixWithOthers]
        try AVAudioSession.sharedInstance().setMode(AVAudioSession.Mode.spokenAudio)
        try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, options: categoryOptions)
        try AVAudioSession.sharedInstance().setActive(true)
    }

    func mixAudio() throws {
        try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.ambient)
        try AVAudioSession.sharedInstance().setActive(true)
    }

    func unDuckAudio() throws {
        try AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }

    func scriptOf(character: Character) -> LanguageScript {
        guard let scalarValue = character.unicodeScalars.first?.value else {
            return .other
        }

        switch scalarValue {
        case 0x0600 ... 0x06FF: return .arabic
        // Add more cases as needed for other scripts
        default: return .other
        }
    }

    func splitBasedOnScript(string: String) -> [LanguageString] {
        guard let firstChar = string.first else {
            return []
        }
        var result: [LanguageString] = []
        var currentScript: LanguageScript = self.scriptOf(character: firstChar)
        var currentSubstring = ""

        for char in string {
            if char.isWhitespace || char.isPunctuation {
                currentSubstring.append(char)
                continue
            }

            let script = self.scriptOf(character: char)
            if script != currentScript {
                if !currentSubstring.isEmpty {
                    result.append(LanguageString(language: currentScript, string: currentSubstring))
                    currentSubstring = ""
                }
                currentScript = script
            }

            currentSubstring.append(char)
        }

        if !currentSubstring.isEmpty {
            result.append(LanguageString(language: currentScript, string: currentSubstring))
        }

        return result
    }

    func verifyBackgroundAudio() {
        guard UIApplication.shared.isKind(of: UIApplication.self) else {
            return
        }

        if !Bundle.main.backgroundModes.contains("audio") {
            assertionFailure("This application’s Info.plist file must include “audio” in UIBackgroundModes. This background mode is used for spoken instructions while the application is in the background.")
        }
    }
}

extension SpokenInstruction {

    @available(iOS 10.0, *)
    func attributedText(for legProgress: RouteLegProgress) -> NSAttributedString {
        let attributedText = NSMutableAttributedString(string: text)
        if let step = legProgress.upComingStep,
           let name = step.names?.first,
           let phoneticName = step.phoneticNames?.first {
            let nameRange = attributedText.mutableString.range(of: name)
            if nameRange.location != NSNotFound {
                attributedText.replaceCharacters(in: nameRange, with: NSAttributedString(string: name).pronounced(phoneticName))
            }
        }
        if let step = legProgress.followOnStep,
           let name = step.names?.first,
           let phoneticName = step.phoneticNames?.first {
            let nameRange = attributedText.mutableString.range(of: name)
            if nameRange.location != NSNotFound {
                attributedText.replaceCharacters(in: nameRange, with: NSAttributedString(string: name).pronounced(phoneticName))
            }
        }
        return attributedText
    }
}
