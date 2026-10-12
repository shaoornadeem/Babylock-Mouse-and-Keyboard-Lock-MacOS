// PentatonicSynth.swift — Procedural musical audio synthesis
// Generates pentatonic scale notes, percussion, and chime sounds mathematically

import Foundation
import AVFoundation

class PentatonicSynth {

    static let sampleRate: Double = 44100.0

    // MARK: - 26 Ascending Pentatonic Frequencies (C4 to ~C9)
    // Pentatonic: C, D, E, G, A — guarantees zero dissonance
    static let pentatonicFrequencies: [Double] = [
        261.63,  // C4   - Key A
        293.66,  // D4   - Key B
        329.63,  // E4   - Key C
        392.00,  // G4   - Key D
        440.00,  // A4   - Key E
        523.25,  // C5   - Key F
        587.33,  // D5   - Key G
        659.26,  // E5   - Key H
        783.99,  // G5   - Key I
        880.00,  // A5   - Key J
        1046.50, // C6   - Key K
        1174.66, // D6   - Key L
        1318.51, // E6   - Key M
        1567.98, // G6   - Key N
        1760.00, // A6   - Key O
        2093.00, // C7   - Key P
        2349.32, // D7   - Key Q
        2637.02, // E7   - Key R
        3135.96, // G7   - Key S
        3520.00, // A7   - Key T
        4186.01, // C8   - Key U
        4698.64, // D8   - Key V
        5274.04, // E8   - Key W
        6271.93, // G8   - Key X
        7040.00, // A8   - Key Y
        8372.02, // C9   - Key Z
    ]

    // MARK: - Instrument Synthesis

    /// Xylophone: Sharp attack with crisp wooden mallet overtone, rapid decay (0.45s)
    /// sample(t) = (sin(2πft) + 0.35·sin(4πft)) · e^(-14t)
    static func synthesizeXylophone(frequencyIndex: Int, volume: Float = 0.5) -> AVAudioPCMBuffer? {
        guard frequencyIndex >= 0, frequencyIndex < pentatonicFrequencies.count else { return nil }
        let freq = pentatonicFrequencies[frequencyIndex]
        let duration: Double = 0.45
        return generateBuffer(duration: duration) { t in
            let fundamental = sin(2.0 * .pi * freq * t)
            let overtone = 0.35 * sin(4.0 * .pi * freq * t)
            let envelope = exp(-14.0 * t)
            return Float((fundamental + overtone) * envelope) * volume
        }
    }

    /// Piano: Warm harmonic body with acoustic string warmth (0.65s)
    /// sample(t) = (0.7·sin(2πft) + 0.2·sin(4πft) + 0.1·sin(6πft)) · e^(-5t)
    static func synthesizePiano(frequencyIndex: Int, volume: Float = 0.5) -> AVAudioPCMBuffer? {
        guard frequencyIndex >= 0, frequencyIndex < pentatonicFrequencies.count else { return nil }
        let freq = pentatonicFrequencies[frequencyIndex]
        let duration: Double = 0.65
        return generateBuffer(duration: duration) { t in
            let h1 = 0.7 * sin(2.0 * .pi * freq * t)
            let h2 = 0.2 * sin(4.0 * .pi * freq * t)
            let h3 = 0.1 * sin(6.0 * .pi * freq * t)
            let envelope = exp(-5.0 * t)
            return Float((h1 + h2 + h3) * envelope) * volume
        }
    }

    /// Chime / Glockenspiel: Metallic inharmonic overtones with bell shimmer (0.85s)
    /// sample(t) = (0.6·sin(2πft) + 0.3·sin(5.52πft) + 0.1·sin(8.12πft)) · e^(-3.5t)
    static func synthesizeChime(frequencyIndex: Int, volume: Float = 0.5) -> AVAudioPCMBuffer? {
        guard frequencyIndex >= 0, frequencyIndex < pentatonicFrequencies.count else { return nil }
        let freq = pentatonicFrequencies[frequencyIndex]
        let duration: Double = 0.85
        return generateBuffer(duration: duration) { t in
            let h1 = 0.6 * sin(2.0 * .pi * freq * t)
            let h2 = 0.3 * sin(5.52 * .pi * freq * t)
            let h3 = 0.1 * sin(8.12 * .pi * freq * t)
            let envelope = exp(-3.5 * t)
            return Float((h1 + h2 + h3) * envelope) * volume
        }
    }

    /// Synthesize a note with the specified instrument
    static func synthesizeNote(instrument: InstrumentType, frequencyIndex: Int, volume: Float = 0.5) -> AVAudioPCMBuffer? {
        switch instrument {
        case .xylophone: return synthesizeXylophone(frequencyIndex: frequencyIndex, volume: volume)
        case .piano:     return synthesizePiano(frequencyIndex: frequencyIndex, volume: volume)
        case .chime:     return synthesizeChime(frequencyIndex: frequencyIndex, volume: volume)
        }
    }

    // MARK: - Percussion (0-9 & Space)

    /// Kick drum: descending frequency chirp 120Hz→40Hz with fast decay
    static func synthesizeKick(volume: Float = 0.5) -> AVAudioPCMBuffer? {
        return generateBuffer(duration: 0.3) { t in
            let freq = 120.0 - 80.0 * min(t / 0.15, 1.0)
            let envelope = exp(-12.0 * t)
            return Float(sin(2.0 * .pi * freq * t) * envelope) * volume
        }
    }

    /// Snare: noise burst with frequency component
    static func synthesizeSnare(volume: Float = 0.5) -> AVAudioPCMBuffer? {
        return generateBuffer(duration: 0.2) { t in
            let noise = Float.random(in: -1.0...1.0)
            let tone = Float(sin(2.0 * .pi * 180.0 * t))
            let envelope = Float(exp(-18.0 * t))
            return (noise * 0.7 + tone * 0.3) * envelope * volume
        }
    }

    /// Hi-hat: high-frequency noise with very fast decay
    static func synthesizeHiHat(volume: Float = 0.4) -> AVAudioPCMBuffer? {
        return generateBuffer(duration: 0.1) { t in
            let noise = Float.random(in: -1.0...1.0)
            let envelope = Float(exp(-30.0 * t))
            return noise * envelope * volume
        }
    }

    /// Clap: double-hit noise burst
    static func synthesizeClap(volume: Float = 0.4) -> AVAudioPCMBuffer? {
        return generateBuffer(duration: 0.15) { t in
            let noise = Float.random(in: -1.0...1.0)
            // Double hit envelope
            let env1 = Float(exp(-40.0 * t))
            let env2 = Float(exp(-20.0 * max(0, t - 0.02)))
            let envelope = max(env1, env2 * 0.8)
            return noise * envelope * volume
        }
    }

    /// Select percussion by digit index
    static func synthesizePercussion(index: Int, volume: Float = 0.5) -> AVAudioPCMBuffer? {
        switch index % 4 {
        case 0: return synthesizeKick(volume: volume)
        case 1: return synthesizeSnare(volume: volume)
        case 2: return synthesizeHiHat(volume: volume)
        case 3: return synthesizeClap(volume: volume)
        default: return synthesizeKick(volume: volume)
        }
    }

    // MARK: - Gentle Chime (for neutral keys)

    static func synthesizeGentleChime(volume: Float = 0.3) -> AVAudioPCMBuffer? {
        let freq = 880.0 // A5
        return generateBuffer(duration: 0.4) { t in
            let h1 = 0.6 * sin(2.0 * .pi * freq * t)
            let h2 = 0.2 * sin(3.0 * .pi * freq * t)
            let envelope = exp(-8.0 * t)
            return Float((h1 + h2) * envelope) * volume
        }
    }

    // MARK: - Click/Pop sound for drawing mode

    static func synthesizePop(volume: Float = 0.4) -> AVAudioPCMBuffer? {
        return generateBuffer(duration: 0.08) { t in
            let freq = 600.0 + 200.0 * exp(-20.0 * t)
            let envelope = exp(-25.0 * t)
            return Float(sin(2.0 * .pi * freq * t) * envelope) * volume
        }
    }

    // MARK: - Buffer Generation

    private static func generateBuffer(duration: Double, generator: (Double) -> Float) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return nil
        }

        buffer.frameLength = frameCount
        guard let channelData = buffer.floatChannelData?[0] else { return nil }

        // 5ms anti-pop fade in/out (220 samples at 44100Hz)
        let fadeSamples = 220
        let totalSamples = Int(frameCount)

        for i in 0..<totalSamples {
            let t = Double(i) / sampleRate
            var sample = generator(t)

            // Apply -12 dBFS soft limiter (max amplitude ~0.25)
            sample = softLimit(sample)

            // Anti-pop fade envelope
            if i < fadeSamples {
                sample *= Float(i) / Float(fadeSamples)
            } else if i > totalSamples - fadeSamples {
                sample *= Float(totalSamples - i) / Float(fadeSamples)
            }

            channelData[i] = sample
        }

        return buffer
    }

    // MARK: - Soft Limiter (-12 dBFS)

    /// f(x) = x                                             if |x| < 0.20
    /// f(x) = sign(x) * (0.20 + 0.05 * tanh((|x|-0.20)/0.05))  if |x| >= 0.20
    private static func softLimit(_ x: Float) -> Float {
        let threshold: Float = 0.20
        let range: Float = 0.05
        let absX = abs(x)
        if absX < threshold {
            return x
        } else {
            let sign: Float = x > 0 ? 1.0 : -1.0
            return sign * (threshold + range * tanh((absX - threshold) / range))
        }
    }
}
