// UnlockStateMachine.swift — Failsafe unlock mechanisms
// Zero-allocation state machines for Hold Chord, Passphrase, Mouse Escape, and Screen Corner

import Foundation

// MARK: - Hold Chord Tracker (U+K for 3 seconds)

enum ChordEvent {
    case none
    case startHoldTimer
    case cancelHoldTimer
    case unlockTriggered
}

class HoldChordTracker {
    var key1: UInt16  // Default U = 0x20
    var key2: UInt16  // Default K = 0x28
    var holdDurationSecs: Double

    private var key1Down = false
    private var key2Down = false
    private var holdStartTime: Date?
    private var progressTimer: DispatchSourceTimer?

    var onUnlock: (() -> Void)?
    var onProgress: ((Double) -> Void)?

    init(key1: UInt16 = KeycodeMap.kVK_ANSI_U,
         key2: UInt16 = KeycodeMap.kVK_ANSI_K,
         holdDuration: Double = 3.0) {
        self.key1 = key1
        self.key2 = key2
        self.holdDurationSecs = holdDuration
    }

    func configure(key1: UInt16, key2: UInt16, holdDuration: Double) {
        self.key1 = key1
        self.key2 = key2
        self.holdDurationSecs = holdDuration
        reset()
    }

    func onKeyDown(_ keycode: UInt16) -> ChordEvent {
        if keycode == key1 {
            key1Down = true
        } else if keycode == key2 {
            key2Down = true
        } else {
            // Anti-mash: any other character key cancels the chord
            if key1Down || key2Down {
                return cancelAll()
            }
            return .none
        }

        // Both keys are down!
        if key1Down && key2Down {
            if progressTimer == nil {
                return startTimer()
            }
            // Already counting down! Do not reset on auto-repeat!
            return .none
        }

        return .none
    }

    func onKeyUp(_ keycode: UInt16) -> ChordEvent {
        if keycode == key1 {
            key1Down = false
            return cancelTimer()
        } else if keycode == key2 {
            key2Down = false
            return cancelTimer()
        }
        return .none
    }

    func reset() {
        key1Down = false
        key2Down = false
        cancelTimerInternal()
    }

    // MARK: - Timer Management

    private func startTimer() -> ChordEvent {
        cancelTimerInternal()
        let start = Date()
        holdStartTime = start
        print("🔒 BabyLock: Started U+K hold countdown (3.0s)...")

        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        timer.schedule(deadline: .now(), repeating: 0.05) // tick every 50ms
        timer.setEventHandler { [weak self] in
            guard let self = self else { return }

            // Verify both keys are still held
            guard self.key1Down && self.key2Down else {
                self.cancelTimerInternal()
                return
            }

            let elapsed = Date().timeIntervalSince(start)
            let progress = min(1.0, elapsed / self.holdDurationSecs)
            self.onProgress?(progress)

            if elapsed >= self.holdDurationSecs {
                print("🔓 BabyLock: U+K held for 3.0 seconds! Triggering unlock!")
                self.reset()
                self.onProgress?(1.0)
                self.onUnlock?()
            }
        }
        timer.resume()
        progressTimer = timer
        return .startHoldTimer
    }

    private func cancelTimer() -> ChordEvent {
        if progressTimer != nil {
            cancelTimerInternal()
            onProgress?(0.0)
            return .cancelHoldTimer
        }
        return .none
    }

    private func cancelAll() -> ChordEvent {
        key1Down = false
        key2Down = false
        if progressTimer != nil {
            cancelTimerInternal()
            onProgress?(0.0)
            return .cancelHoldTimer
        }
        return .none
    }

    private func cancelTimerInternal() {
        if let timer = progressTimer {
            timer.cancel()
            progressTimer = nil
        }
        holdStartTime = nil
    }

    /// Returns progress 0.0-1.0 if chord is being held
    var holdProgress: Double {
        guard let start = holdStartTime, key1Down, key2Down else { return 0 }
        return min(1.0, Date().timeIntervalSince(start) / holdDurationSecs)
    }
}

// MARK: - Passphrase Tracker ("baby")

class PassphraseTracker {
    private var phrase: [UInt16]
    private var matchedCount = 0
    private var lastKeyTime: Date?
    private let inactivityTimeout: TimeInterval = 5.0

    var onUnlock: (() -> Void)?

    /// Default passphrase: b-a-b-y
    init(phrase: [UInt16] = [
        KeycodeMap.kVK_ANSI_B,
        KeycodeMap.kVK_ANSI_A,
        KeycodeMap.kVK_ANSI_B,
        KeycodeMap.kVK_ANSI_Y
    ]) {
        self.phrase = phrase
    }

    func configure(phrase: [UInt16]) {
        self.phrase = phrase
        reset()
    }

    func onKeyDown(_ keycode: UInt16) -> Bool {
        let now = Date()

        // Inactivity timeout resets progress
        if let last = lastKeyTime, now.timeIntervalSince(last) > inactivityTimeout {
            matchedCount = 0
        }
        lastKeyTime = now

        guard matchedCount < phrase.count else { return false }

        if keycode == phrase[matchedCount] {
            matchedCount += 1
            if matchedCount == phrase.count {
                matchedCount = 0
                DispatchQueue.main.async { [weak self] in
                    self?.onUnlock?()
                }
                return true
            }
        } else {
            // Check if this key starts a fresh sequence
            matchedCount = (keycode == phrase[0]) ? 1 : 0
        }

        return false
    }

    func reset() {
        matchedCount = 0
        lastKeyTime = nil
    }

    var progress: Int { matchedCount }
    var total: Int { phrase.count }
}

// MARK: - Mouse Escape Tracker (L+R held for 5 seconds)

class MouseEscapeTracker {
    let holdDurationSecs: Double

    private var leftDown = false
    private var rightDown = false
    private var holdTimer: DispatchWorkItem?
    private var holdStartTime: Date?

    var onUnlock: (() -> Void)?

    init(holdDuration: Double = 5.0) {
        self.holdDurationSecs = holdDuration
    }

    func onMouseDown(isRight: Bool) {
        if isRight {
            rightDown = true
        } else {
            leftDown = true
        }

        if leftDown && rightDown {
            startTimer()
        }
    }

    func onMouseUp(isRight: Bool) {
        if isRight {
            rightDown = false
        } else {
            leftDown = false
        }
        cancelTimer()
    }

    func reset() {
        leftDown = false
        rightDown = false
        cancelTimer()
    }

    private func startTimer() {
        cancelTimer()
        holdStartTime = Date()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            if self.leftDown && self.rightDown {
                DispatchQueue.main.async {
                    self.onUnlock?()
                }
            }
        }
        holdTimer = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + holdDurationSecs, execute: workItem)
    }

    private func cancelTimer() {
        holdTimer?.cancel()
        holdTimer = nil
        holdStartTime = nil
    }

    var holdProgress: Double {
        guard let start = holdStartTime, leftDown, rightDown else { return 0 }
        return min(1.0, Date().timeIntervalSince(start) / holdDurationSecs)
    }
}

// MARK: - Screen Corner Escape (top-left corner for 5 seconds)

class ScreenCornerTracker {
    let cornerSize: CGFloat = 10.0
    let holdDurationSecs: Double

    private var inCorner = false
    private var holdTimer: DispatchWorkItem?

    var onUnlock: (() -> Void)?

    init(holdDuration: Double = 5.0) {
        self.holdDurationSecs = holdDuration
    }

    func onMouseMoved(position: CGPoint) {
        let isInCorner = position.x <= cornerSize && position.y <= cornerSize

        if isInCorner && !inCorner {
            // Entered corner, start timer
            inCorner = true
            startTimer()
        } else if !isInCorner && inCorner {
            // Left corner, cancel
            inCorner = false
            cancelTimer()
        }
    }

    func reset() {
        inCorner = false
        cancelTimer()
    }

    private func startTimer() {
        cancelTimer()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            if self.inCorner {
                DispatchQueue.main.async {
                    self.onUnlock?()
                }
            }
        }
        holdTimer = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + holdDurationSecs, execute: workItem)
    }

    private func cancelTimer() {
        holdTimer?.cancel()
        holdTimer = nil
    }
}
