// PlayEngine.swift — Play Mode Engine & Dispatcher
// Central controller for audio, visuals, rate limiting, and interaction modes

import Foundation

class PlayEngine {

    private let appState: AppState
    private let audioEngine: BabyLockAudioEngine
    private let overlayManager: OverlayManager

    // Auto-repeat suppression: track which keys are currently held
    private var heldKeys: Set<UInt16> = []

    // Rate limiting
    private let minTriggerIntervalMs: UInt64 = 180
    private var lastTriggerTime: UInt64 = 0

    // Random mode: no-repeat tracker
    private var lastRandomIndex: Int = -1

    init(appState: AppState, audioEngine: BabyLockAudioEngine, overlayManager: OverlayManager) {
        self.appState = appState
        self.audioEngine = audioEngine
        self.overlayManager = overlayManager
    }

    // MARK: - Key Events

    func onKeyDown(_ keycode: UInt16) {
        guard appState.playEnabled else { return }

        // Auto-repeat suppression: ignore if already held
        if heldKeys.contains(keycode) { return }
        heldKeys.insert(keycode)

        // Rate limiting
        let now = DispatchTime.now().uptimeNanoseconds / 1_000_000
        guard now - lastTriggerTime >= minTriggerIntervalMs else { return }
        lastTriggerTime = now

        // Check quiet-after period (no audio after threshold)
        let shouldPlayAudio = !appState.isQuietPeriod
        let volume = appState.volume.multiplier * 0.5 // Scale for safety

        switch appState.playMode {
        case .random:
            handleRandomMode(keycode: keycode, volume: volume, playAudio: shouldPlayAudio)
        case .letters:
            handleLettersMode(keycode: keycode, volume: volume, playAudio: shouldPlayAudio)
        case .scale:
            handleScaleMode(keycode: keycode, volume: volume, playAudio: shouldPlayAudio)
        case .drawing:
            handleDrawingKeyPress(keycode: keycode, volume: volume, playAudio: shouldPlayAudio)
        }
    }

    func onKeyUp(_ keycode: UInt16) {
        heldKeys.remove(keycode)
    }

    func onMouseMoved(position: NSPoint) {
        if appState.playMode == .drawing {
            overlayManager.feedMousePosition(position)
        }
    }

    func onMouseClick(position: NSPoint) {
        if appState.playMode == .drawing {
            overlayManager.feedClickBurst(at: position)
            if !appState.isQuietPeriod {
                audioEngine.playPop(volume: appState.volume.multiplier * 0.4)
            }
        }
    }

    // MARK: - Mode: Random

    private func handleRandomMode(keycode: UInt16, volume: Float, playAudio: Bool) {
        let entries = PhonicsData.themeEntries(for: appState.theme)
        guard !entries.isEmpty else { return }

        let index = pickRandomNoRepeat(count: entries.count)
        let entry = entries[index]

        // Show visual card
        DispatchQueue.main.async { [weak self] in
            self?.overlayManager.showThemeCard(name: entry.name, emoji: entry.emoji)
        }

        // Play audio: chime + speak the word
        if playAudio {
            audioEngine.playGentleChime(volume: volume)
            audioEngine.speak(entry.sound, voiceSource: appState.voiceSource, speechSpeed: appState.speechSpeed)
        }
    }

    // MARK: - Mode: Letters (Phonics)

    private func handleLettersMode(keycode: UInt16, volume: Float, playAudio: Bool) {
        if let letterIdx = KeycodeMap.letterIndex(for: keycode) {
            // Letter A-Z
            let entry = PhonicsData.letters[letterIdx]

            DispatchQueue.main.async { [weak self] in
                self?.overlayManager.showPhonicsCard(
                    letter: String(entry.letter),
                    word: entry.word,
                    emoji: entry.emoji
                )
            }

            if playAudio {
                // Play instrument note for the letter
                audioEngine.playNote(instrument: appState.instrument, letterIndex: letterIdx, volume: volume)
                // Speak the phonics phrase
                audioEngine.speak(entry.phrase, voiceSource: appState.voiceSource, speechSpeed: appState.speechSpeed)
            }

        } else if let digit = KeycodeMap.digit(for: keycode) {
            // Number 0-9
            let entry = PhonicsData.numbers[digit]

            DispatchQueue.main.async { [weak self] in
                self?.overlayManager.showNumberCard(
                    digit: String(entry.digit),
                    word: entry.word,
                    emoji: entry.emoji
                )
            }

            if playAudio {
                audioEngine.playPercussion(index: digit, volume: volume)
                audioEngine.speak(entry.phrase, voiceSource: appState.voiceSource, speechSpeed: appState.speechSpeed)
            }

        } else {
            // Neutral key
            if playAudio {
                audioEngine.playGentleChime(volume: volume * 0.6)
            }
        }
    }

    // MARK: - Mode: Musical Scale

    private func handleScaleMode(keycode: UInt16, volume: Float, playAudio: Bool) {
        if let letterIdx = KeycodeMap.letterIndex(for: keycode) {
            // Letters A-Z = 26 pentatonic notes
            if playAudio {
                audioEngine.playNote(instrument: appState.instrument, letterIndex: letterIdx, volume: volume)
            }
            DispatchQueue.main.async { [weak self] in
                self?.overlayManager.showNoteVisualization(noteIndex: letterIdx)
            }

        } else if let digit = KeycodeMap.digit(for: keycode) {
            // Numbers 0-9 = percussion
            if playAudio {
                audioEngine.playPercussion(index: digit, volume: volume)
            }

        } else if keycode == KeycodeMap.kVK_Space {
            // Space = kick
            if playAudio {
                audioEngine.playPercussion(index: 0, volume: volume)
            }
        }
    }

    // MARK: - Mode: Drawing

    private func handleDrawingKeyPress(keycode: UInt16, volume: Float, playAudio: Bool) {
        // Key presses stamp geometric shapes
        DispatchQueue.main.async { [weak self] in
            self?.overlayManager.feedKeyStamp()
        }

        if playAudio {
            audioEngine.playGentleChime(volume: volume * 0.5)
        }
    }

    // MARK: - Helpers

    /// Random pick that never repeats the same item twice
    private func pickRandomNoRepeat(count: Int) -> Int {
        guard count > 1 else { return 0 }
        var index: Int
        repeat {
            index = Int.random(in: 0..<count)
        } while index == lastRandomIndex
        lastRandomIndex = index
        return index
    }

    /// Reset state when locking/unlocking
    func reset() {
        heldKeys.removeAll()
        lastTriggerTime = 0
        lastRandomIndex = -1
    }

    /// Activate/deactivate drawing mode overlay
    func updateDrawingMode() {
        if appState.playMode == .drawing && appState.isLocked {
            overlayManager.activateDrawingMode()
        } else {
            overlayManager.deactivateDrawingMode()
        }
    }
}
