// AudioEngine.swift — Polyphonic mixer & hearing safety engine
// AVAudioEngine-based 16-voice polyphonic playback with soft limiting

import Foundation
import AVFoundation

class BabyLockAudioEngine {

    private var engine: AVAudioEngine?
    private var playerNodes: [AVAudioPlayerNode] = []
    private var voiceTimestamps: [Date] = []
    private let maxVoices = 16
    private var nextVoiceIndex = 0
    private var isRunning = false
    private let engineLock = NSLock()

    // Speech synthesis for phonics
    private let speechSynth = AVSpeechSynthesizer()

    // Format for all synthesized audio
    private let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!

    init() {}

    // MARK: - Lifecycle

    func start() {
        engineLock.lock()
        defer { engineLock.unlock() }

        guard !isRunning else { return }

        let eng = AVAudioEngine()
        engine = eng

        // Create 16 player nodes for polyphony
        playerNodes = []
        voiceTimestamps = []
        for _ in 0..<maxVoices {
            let player = AVAudioPlayerNode()
            eng.attach(player)
            eng.connect(player, to: eng.mainMixerNode, format: audioFormat)
            playerNodes.append(player)
            voiceTimestamps.append(Date.distantPast)
        }

        // Set initial mixer volume
        eng.mainMixerNode.outputVolume = 0.65

        do {
            try eng.start()
            for player in playerNodes {
                player.play()
            }
            isRunning = true
        } catch {
            print("⚠️ BabyLock AudioEngine start failed: \(error)")
        }
    }

    func stop() {
        engineLock.lock()
        defer { engineLock.unlock() }

        guard isRunning else { return }

        speechSynth.stopSpeaking(at: .immediate)

        for player in playerNodes {
            player.stop()
        }
        engine?.stop()

        // Detach player nodes
        if let eng = engine {
            for player in playerNodes {
                eng.detach(player)
            }
        }

        playerNodes = []
        voiceTimestamps = []
        engine = nil
        isRunning = false
        nextVoiceIndex = 0
    }

    // MARK: - Volume

    func setVolume(_ level: VolumeLevel) {
        engine?.mainMixerNode.outputVolume = level.multiplier
    }

    // MARK: - Polyphonic Playback

    /// Play a synthesized buffer. Uses voice stealing (oldest voice) if all 16 voices are active.
    func playBuffer(_ buffer: AVAudioPCMBuffer?) {
        guard let buffer = buffer, isRunning else { return }

        engineLock.lock()
        defer { engineLock.unlock() }

        guard !playerNodes.isEmpty else { return }

        // Find the oldest voice to steal
        var oldestIndex = 0
        var oldestTime = Date()
        for i in 0..<maxVoices {
            if voiceTimestamps[i] < oldestTime {
                oldestTime = voiceTimestamps[i]
                oldestIndex = i
            }
        }

        // Use round-robin if no old voices
        let voiceIndex = oldestIndex
        let player = playerNodes[voiceIndex]

        // Stop any current playback on this voice
        player.stop()
        player.play()

        // Schedule the buffer
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        voiceTimestamps[voiceIndex] = Date()
    }

    // MARK: - Convenience: Play synthesized note

    func playNote(instrument: InstrumentType, letterIndex: Int, volume: Float) {
        let buffer = PentatonicSynth.synthesizeNote(
            instrument: instrument,
            frequencyIndex: letterIndex,
            volume: volume
        )
        playBuffer(buffer)
    }

    func playPercussion(index: Int, volume: Float) {
        let buffer = PentatonicSynth.synthesizePercussion(index: index, volume: volume)
        playBuffer(buffer)
    }

    func playGentleChime(volume: Float) {
        let buffer = PentatonicSynth.synthesizeGentleChime(volume: volume)
        playBuffer(buffer)
    }

    func playPop(volume: Float) {
        let buffer = PentatonicSynth.synthesizePop(volume: volume)
        playBuffer(buffer)
    }

    // MARK: - Speech Synthesis (Phonics)

    func speak(_ text: String, voiceSource: VoiceSource, speechSpeed: SpeechSpeed = .slow) {
        speechSynth.stopSpeaking(at: .immediate)

        let utterance = AVSpeechUtterance(string: text)
        utterance.pitchMultiplier = voiceSource.pitchMultiplier
        utterance.rate = speechSpeed.rate
        utterance.volume = 0.85

        // Try to find a good English voice
        if let voice = AVSpeechSynthesisVoice(language: "en-US") {
            utterance.voice = voice
        }

        speechSynth.speak(utterance)
    }
}
