// AppState.swift — Global state & atomic synchronization
// Thread-safe lock state, timer countdown, and settings management

import Foundation

// MARK: - Enums

enum LockMode: Int, CaseIterable {
    case keyboardOnly = 0
    case mouseOnly = 1
    case both = 2

    var locksKeyboard: Bool { self != .mouseOnly }
    var locksMouse: Bool { self != .keyboardOnly }

    var displayName: String {
        switch self {
        case .keyboardOnly: return "Keyboard Only"
        case .mouseOnly: return "Mouse Only"
        case .both: return "Keyboard & Mouse"
        }
    }
}

enum KeyBehaviorMode: Int, CaseIterable {
    case random = 0
    case letters = 1
    case scale = 2
    case drawing = 3

    var displayName: String {
        switch self {
        case .random: return "Random"
        case .letters: return "Phonics (A-Z)"
        case .scale: return "Musical Scale"
        case .drawing: return "Drawing"
        }
    }
}

enum ThemeType: Int, CaseIterable {
    case animals = 0
    case vehicles = 1
    case musical = 2
    case baby = 3
    case highContrast = 4

    var displayName: String {
        switch self {
        case .animals: return "Animals"
        case .vehicles: return "Vehicles"
        case .musical: return "Musical"
        case .baby: return "Baby"
        case .highContrast: return "High Contrast"
        }
    }
}

enum VoiceSource: Int, CaseIterable {
    case cuteLittleGirl = 0
    case cuteLittleBoy = 1

    var displayName: String {
        switch self {
        case .cuteLittleGirl: return "Cute Little Girl"
        case .cuteLittleBoy: return "Cute Little Boy"
        }
    }

    var pitchMultiplier: Float {
        switch self {
        case .cuteLittleGirl: return 1.35
        case .cuteLittleBoy: return 1.25
        }
    }

    var rate: Float {
        switch self {
        case .cuteLittleGirl: return 0.42
        case .cuteLittleBoy: return 0.46
        }
    }
}

enum InstrumentType: Int, CaseIterable {
    case xylophone = 0
    case piano = 1
    case chime = 2

    var displayName: String {
        switch self {
        case .xylophone: return "Xylophone"
        case .piano: return "Piano"
        case .chime: return "Chime"
        }
    }
}

enum VolumeLevel: Int, CaseIterable {
    case low = 0
    case medium = 1
    case high = 2

    var multiplier: Float {
        switch self {
        case .low: return 0.30
        case .medium: return 0.65
        case .high: return 1.0
        }
    }

    var displayName: String {
        switch self {
        case .low: return "Low (Safe - 30%)"
        case .medium: return "Medium (65%)"
        case .high: return "High (Capped - 100%)"
        }
    }
}

enum AutoUnlockDuration: Int, CaseIterable {
    case never = 0
    case fiveMinutes = 5
    case fifteenMinutes = 15
    case thirtyMinutes = 30
    case oneHour = 60

    var displayName: String {
        switch self {
        case .never: return "Never (Default)"
        case .fiveMinutes: return "5 Minutes"
        case .fifteenMinutes: return "15 Minutes"
        case .thirtyMinutes: return "30 Minutes"
        case .oneHour: return "1 Hour"
        }
    }
}

enum SpeechSpeed: Int, CaseIterable {
    case verySlow = 0
    case slow = 1
    case normal = 2
    case fast = 3
    case veryFast = 4

    var rate: Float {
        switch self {
        case .verySlow: return 0.28
        case .slow: return 0.38
        case .normal: return 0.48
        case .fast: return 0.58
        case .veryFast: return 0.68
        }
    }

    var displayName: String {
        switch self {
        case .verySlow: return "🐢 Very Slow (0.3x)"
        case .slow: return "🚶 Slow (0.4x)"
        case .normal: return "⚡ Normal (0.5x)"
        case .fast: return "🐇 Fast (0.6x)"
        case .veryFast: return "🚀 Very Fast (0.7x)"
        }
    }
}

enum CardDisplayDuration: Int, CaseIterable {
    case oneAndHalf = 15   // 1.5s
    case twoSeconds = 20   // 2.0s
    case twoAndHalf = 25   // 2.5s
    case threeSeconds = 30 // 3.0s
    case fourSeconds = 40  // 4.0s
    case fiveSeconds = 50  // 5.0s

    var seconds: Double {
        return Double(rawValue) / 10.0
    }

    var displayName: String {
        switch self {
        case .oneAndHalf: return "1.5 Seconds"
        case .twoSeconds: return "2.0 Seconds"
        case .twoAndHalf: return "2.5 Seconds"
        case .threeSeconds: return "3.0 Seconds (Recommended)"
        case .fourSeconds: return "4.0 Seconds"
        case .fiveSeconds: return "5.0 Seconds"
        }
    }
}

// MARK: - AppState

class AppState {
    private let lock = NSLock()

    // --- Lock State (Thread-Safe) ---
    private var _isLocked = false
    var isLocked: Bool {
        get { lock.withLock { _isLocked } }
        set { lock.withLock { _isLocked = newValue } }
    }

    private var _remainingSecs: Int = 0
    var remainingSecs: Int {
        get { lock.withLock { _remainingSecs } }
        set { lock.withLock { _remainingSecs = newValue } }
    }

    private var _heartbeat: UInt64 = 0
    var heartbeat: UInt64 {
        get { lock.withLock { _heartbeat } }
    }

    // Keys for UserDefaults persistence
    private static let keyLockMode = "BabyLock_LockMode"
    private static let keyPlayMode = "BabyLock_PlayMode"
    private static let keyPlayEnabled = "BabyLock_PlayEnabled"
    private static let keyTheme = "BabyLock_Theme"
    private static let keyVoiceSource = "BabyLock_VoiceSource"
    private static let keySpeechSpeed = "BabyLock_SpeechSpeed"
    private static let keyCardDuration = "BabyLock_CardDuration"
    private static let keyInstrument = "BabyLock_Instrument"
    private static let keyVolume = "BabyLock_Volume"
    private static let keyAutoUnlock = "BabyLock_AutoUnlock"
    private static let keyQuietAfter = "BabyLock_QuietAfter"

    // --- Settings (Main Thread) ---
    var mode: LockMode {
        didSet {
            UserDefaults.standard.set(mode.rawValue, forKey: AppState.keyLockMode)
            onSettingsChanged?()
        }
    }
    /// Play mode: Defaults to `.letters` (Phonics A-Z) on first launch!
    var playMode: KeyBehaviorMode {
        didSet {
            UserDefaults.standard.set(playMode.rawValue, forKey: AppState.keyPlayMode)
            onSettingsChanged?()
        }
    }
    var playEnabled: Bool {
        didSet {
            UserDefaults.standard.set(playEnabled, forKey: AppState.keyPlayEnabled)
            onSettingsChanged?()
        }
    }
    var theme: ThemeType {
        didSet {
            UserDefaults.standard.set(theme.rawValue, forKey: AppState.keyTheme)
            onSettingsChanged?()
        }
    }
    var voiceSource: VoiceSource {
        didSet {
            UserDefaults.standard.set(voiceSource.rawValue, forKey: AppState.keyVoiceSource)
            onSettingsChanged?()
        }
    }
    var speechSpeed: SpeechSpeed {
        didSet {
            UserDefaults.standard.set(speechSpeed.rawValue, forKey: AppState.keySpeechSpeed)
            onSettingsChanged?()
        }
    }
    var cardDuration: CardDisplayDuration {
        didSet {
            UserDefaults.standard.set(cardDuration.rawValue, forKey: AppState.keyCardDuration)
            onSettingsChanged?()
        }
    }
    var instrument: InstrumentType {
        didSet {
            UserDefaults.standard.set(instrument.rawValue, forKey: AppState.keyInstrument)
            onSettingsChanged?()
        }
    }
    var volume: VolumeLevel {
        didSet {
            UserDefaults.standard.set(volume.rawValue, forKey: AppState.keyVolume)
            onSettingsChanged?()
        }
    }
    var autoUnlockMinutes: Int {
        didSet {
            UserDefaults.standard.set(autoUnlockMinutes, forKey: AppState.keyAutoUnlock)
            onSettingsChanged?()
        }
    }
    var quietAfterMinutes: Int {
        didSet {
            UserDefaults.standard.set(quietAfterMinutes, forKey: AppState.keyQuietAfter)
            onSettingsChanged?()
        }
    }
    var shortcutSettings: ShortcutSettings

    // --- Internal State ---
    var lockedAt: Date?
    private var countdownTimer: Timer?

    // --- Callbacks ---
    var onLockStateChanged: ((Bool) -> Void)?
    var onTimerTick: ((Int) -> Void)?
    var onShortcutsChanged: (() -> Void)?
    var onSettingsChanged: (() -> Void)?

    init() {
        let defaults = UserDefaults.standard

        // 1. Lock mode (default: .both)
        if let raw = defaults.object(forKey: AppState.keyLockMode) as? Int, let m = LockMode(rawValue: raw) {
            self.mode = m
        } else {
            self.mode = .both
        }

        // 2. Play mode: Default on first run is Phonics (A-Z) (.letters)
        if let raw = defaults.object(forKey: AppState.keyPlayMode) as? Int, let m = KeyBehaviorMode(rawValue: raw) {
            self.playMode = m
        } else {
            self.playMode = .letters // First-time default: Phonics (A-Z)
        }

        // 3. Play enabled (default: true)
        if let enabled = defaults.object(forKey: AppState.keyPlayEnabled) as? Bool {
            self.playEnabled = enabled
        } else {
            self.playEnabled = true
        }

        // 4. Theme (default: .animals)
        if let raw = defaults.object(forKey: AppState.keyTheme) as? Int, let t = ThemeType(rawValue: raw) {
            self.theme = t
        } else {
            self.theme = .animals
        }

        // 5. Voice source (default: .cuteLittleGirl)
        if let raw = defaults.object(forKey: AppState.keyVoiceSource) as? Int, let v = VoiceSource(rawValue: raw) {
            self.voiceSource = v
        } else {
            self.voiceSource = .cuteLittleGirl
        }

        // 6. Speech speed (default: .slow)
        if let raw = defaults.object(forKey: AppState.keySpeechSpeed) as? Int, let s = SpeechSpeed(rawValue: raw) {
            self.speechSpeed = s
        } else {
            self.speechSpeed = .slow
        }

        // 7. Card duration (default: .threeSeconds)
        if let raw = defaults.object(forKey: AppState.keyCardDuration) as? Int, let d = CardDisplayDuration(rawValue: raw) {
            self.cardDuration = d
        } else {
            self.cardDuration = .threeSeconds
        }

        // 8. Instrument (default: .xylophone)
        if let raw = defaults.object(forKey: AppState.keyInstrument) as? Int, let i = InstrumentType(rawValue: raw) {
            self.instrument = i
        } else {
            self.instrument = .xylophone
        }

        // 9. Volume (default: .medium)
        if let raw = defaults.object(forKey: AppState.keyVolume) as? Int, let vol = VolumeLevel(rawValue: raw) {
            self.volume = vol
        } else {
            self.volume = .medium
        }

        // 10. Auto unlock minutes (default: 0)
        self.autoUnlockMinutes = defaults.object(forKey: AppState.keyAutoUnlock) as? Int ?? 0

        // 11. Quiet after minutes (default: 0 - disabled, unlimited play)
        self.quietAfterMinutes = defaults.object(forKey: AppState.keyQuietAfter) as? Int ?? 0

        // 12. Shortcut settings
        self.shortcutSettings = ShortcutSettings.load()

        shortcutSettings.onChange = { [weak self] in
            self?.onShortcutsChanged?()
        }
    }

    func notifyShortcutsChanged() {
        onShortcutsChanged?()
    }

    // MARK: - Lock Lifecycle

    func engage() {
        isLocked = true
        lockedAt = Date()
        if autoUnlockMinutes > 0 {
            remainingSecs = autoUnlockMinutes * 60
            startCountdown()
        } else {
            remainingSecs = 0
        }
        onLockStateChanged?(true)
    }

    func disengage() {
        isLocked = false
        lockedAt = nil
        stopCountdown()
        remainingSecs = 0
        onLockStateChanged?(false)
    }

    func bumpHeartbeat() {
        lock.withLock { _heartbeat += 1 }
    }

    // MARK: - Timer

    private func startCountdown() {
        stopCountdown()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let remaining = self.remainingSecs
            if remaining > 0 {
                self.remainingSecs = remaining - 1
                self.onTimerTick?(remaining - 1)
                if remaining - 1 == 0 {
                    DispatchQueue.main.async {
                        self.disengage()
                    }
                }
            }
        }
    }

    private func stopCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }

    // MARK: - Helpers

    var formattedTimeRemaining: String {
        let secs = remainingSecs
        if secs <= 0 { return "" }
        let mins = secs / 60
        let s = secs % 60
        return String(format: "%d:%02d", mins, s)
    }

    /// Returns true if quiet-after period has elapsed
    var isQuietPeriod: Bool {
        guard let lockedAt = lockedAt, quietAfterMinutes > 0 else { return false }
        return Date().timeIntervalSince(lockedAt) > Double(quietAfterMinutes * 60)
    }
}

// MARK: - NSLock convenience

extension NSLock {
    func withLock<T>(_ body: () -> T) -> T {
        self.lock()
        defer { self.unlock() }
        return body()
    }
}
