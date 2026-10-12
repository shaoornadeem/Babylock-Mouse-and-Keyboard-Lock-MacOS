// InputTapManager.swift — Low-level input interception
// CGEvent tap for swallowing keyboard/mouse events with system shortcut suppression

import Foundation
import CoreGraphics
import AppKit

// Private API declarations for disabling global hotkeys (Cmd+Tab, etc.)
@_silgen_name("CGSMainConnectionID")
func CGSMainConnectionID() -> Int32

@_silgen_name("CGSSetGlobalHotKeyOperatingMode")
func CGSSetGlobalHotKeyOperatingMode(_ connection: Int32, _ mode: Int32) -> CGError

class InputTapManager {

    private let appState: AppState
    private let playEngine: PlayEngine
    private let overlayManager: OverlayManager

    // Unlock state machines
    let chordTracker: HoldChordTracker
    let passphraseTracker: PassphraseTracker
    let mouseEscapeTracker: MouseEscapeTracker
    let cornerTracker: ScreenCornerTracker

    // Event tap
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var tapEnabled = false

    // System hotkey state
    private var hotkeysDisabled = false

    init(appState: AppState, playEngine: PlayEngine, overlayManager: OverlayManager) {
        self.appState = appState
        self.playEngine = playEngine
        self.overlayManager = overlayManager

        self.chordTracker = HoldChordTracker(
            key1: appState.shortcutSettings.chordKey1,
            key2: appState.shortcutSettings.chordKey2,
            holdDuration: appState.shortcutSettings.chordDuration
        )
        self.passphraseTracker = PassphraseTracker(
            phrase: appState.shortcutSettings.passphraseKeycodes
        )
        self.mouseEscapeTracker = MouseEscapeTracker()
        self.cornerTracker = ScreenCornerTracker()
    }

    func updateShortcutSettings() {
        chordTracker.configure(
            key1: appState.shortcutSettings.chordKey1,
            key2: appState.shortcutSettings.chordKey2,
            holdDuration: appState.shortcutSettings.chordDuration
        )
        passphraseTracker.configure(
            phrase: appState.shortcutSettings.passphraseKeycodes
        )
    }

    // MARK: - Accessibility Permission

    static func checkAccessibilityPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    static func isAccessibilityGranted() -> Bool {
        return AXIsProcessTrusted()
    }

    var onLockRequested: (() -> Void)?

    // MARK: - Enable / Disable

    func startTap() {
        guard eventTap == nil else { return }

        // Define which events to intercept
        let eventTypes: [CGEventType] = [
            .keyDown, .keyUp, .flagsChanged,
            .leftMouseDown, .leftMouseUp,
            .rightMouseDown, .rightMouseUp,
            .mouseMoved,
            .leftMouseDragged, .rightMouseDragged,
            .scrollWheel
        ]
        var eventMask: CGEventMask = 0
        for eventType in eventTypes {
            eventMask |= (1 << eventType.rawValue)
        }

        // Create the event tap with self as userInfo
        let refcon = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: inputTapCallback,
            userInfo: refcon
        ) else {
            print("⚠️ BabyLock: Failed to create event tap. Accessibility permission may not be granted.")
            return
        }

        eventTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        tapEnabled = true

        setupUnlockCallbacks()
        print("✅ BabyLock: CGEventTap active (monitoring hotkeys across all apps)")
    }

    func setLockedState(_ locked: Bool) {
        startTap() // Ensure tap is running
        if locked {
            disableGlobalHotkeys()
            print("🔒 BabyLock: Input tap entered LOCKED mode")
        } else {
            enableGlobalHotkeys()
            chordTracker.reset()
            passphraseTracker.reset()
            mouseEscapeTracker.reset()
            cornerTracker.reset()
            print("🔓 BabyLock: Input tap entered UNLOCKED mode (pass-through active)")
        }
    }

    func enable() {
        setLockedState(true)
    }

    func disable() {
        setLockedState(false)
    }

    // MARK: - System Hotkeys

    private func disableGlobalHotkeys() {
        let conn = CGSMainConnectionID()
        let result = CGSSetGlobalHotKeyOperatingMode(conn, 1) // 1 = disable
        if result == .success {
            hotkeysDisabled = true
            print("🔒 BabyLock: System hotkeys disabled")
        } else {
            print("⚠️ BabyLock: Could not disable system hotkeys (code: \(result))")
        }
    }

    private func enableGlobalHotkeys() {
        guard hotkeysDisabled else { return }
        let conn = CGSMainConnectionID()
        let _ = CGSSetGlobalHotKeyOperatingMode(conn, 0) // 0 = enable
        hotkeysDisabled = false
        print("🔓 BabyLock: System hotkeys restored")
    }

    // MARK: - Unlock Callbacks

    private func setupUnlockCallbacks() {
        let unlockAction: () -> Void = { [weak self] in
            guard let self = self else { return }
            self.triggerUnlock()
        }

        chordTracker.onUnlock = unlockAction
        chordTracker.onProgress = { [weak self] progress in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.overlayManager.updateHoldProgress(progress)
            }
        }
        passphraseTracker.onUnlock = unlockAction
        mouseEscapeTracker.onUnlock = unlockAction
        cornerTracker.onUnlock = unlockAction
    }

    func triggerUnlock() {
        DispatchQueue.main.async { [weak self] in
            self?.appState.disengage()
        }
    }

    func triggerLock() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, !self.appState.isLocked else { return }
            self.onLockRequested?()
        }
    }

    // MARK: - Event Processing (called from C callback)

    func handleEvent(type: CGEventType, event: CGEvent) -> CGEvent? {
        // Bump heartbeat for watchdog
        appState.bumpHeartbeat()

        // Handle tap re-enable after timeout
        if type == .tapDisabledByTimeout {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return event
        }

        // --- When UNLOCKED: Intercept configured lock shortcut or failsafes from ANY app to LOCK ---
        guard appState.isLocked else {
            if type == .keyDown {
                let keycode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
                let flags = event.flags
                let isMatch = appState.shortcutSettings.matchesLockShortcut(keyCode: keycode, cgFlags: flags) ||
                              appState.shortcutSettings.matchesFailsafeShortcut(keyCode: keycode, cgFlags: flags)

                if isMatch {
                    print("🔒 BabyLock: CGEventTap detected lock shortcut (\(appState.shortcutSettings.lockShortcutDisplay)) in active app -> Engaging lock!")
                    triggerLock()
                    return nil // Swallow event so key is NOT typed in the active app
                }
            }
            return event // Not locked: pass through all other input to active app
        }

        switch type {
        case .keyDown:
            return handleKeyDown(event: event)
        case .keyUp:
            return handleKeyUp(event: event)
        case .flagsChanged:
            return handleFlagsChanged(event: event)
        case .leftMouseDown:
            return handleMouseDown(event: event, isRight: false)
        case .leftMouseUp:
            return handleMouseUp(event: event, isRight: false)
        case .rightMouseDown:
            return handleMouseDown(event: event, isRight: true)
        case .rightMouseUp:
            return handleMouseUp(event: event, isRight: true)
        case .mouseMoved, .leftMouseDragged, .rightMouseDragged:
            return handleMouseMoved(event: event)
        case .scrollWheel:
            return handleScrollWheel(event: event)
        default:
            return event
        }
    }

    // MARK: - Keyboard Events

    private func handleKeyDown(event: CGEvent) -> CGEvent? {
        let keycode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
        let flags = event.flags

        // 1. Check user-configured unlock shortcut or emergency failsafe shortcuts
        let isUnlockMatch = appState.shortcutSettings.matchesLockShortcut(keyCode: keycode, cgFlags: flags) ||
                            appState.shortcutSettings.matchesFailsafeShortcut(keyCode: keycode, cgFlags: flags)

        if isUnlockMatch {
            print("🔓 BabyLock: Unlock shortcut triggered via event tap")
            triggerUnlock()
            return nil // Swallow event
        }

        // Skip modifier-only keys
        if KeycodeMap.isModifier(keycode) { return nil }

        // Feed unlock state machines
        let _ = chordTracker.onKeyDown(keycode)
        let _ = passphraseTracker.onKeyDown(keycode)

        // Feed play engine (if keyboard is locked)
        if appState.mode.locksKeyboard {
            playEngine.onKeyDown(keycode)
            return nil // Swallow the key event
        }

        return event // Mouse-only mode: pass keyboard through
    }

    private func handleKeyUp(event: CGEvent) -> CGEvent? {
        let keycode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
        let flags = event.flags

        let isUnlockMatch = appState.shortcutSettings.matchesLockShortcut(keyCode: keycode, cgFlags: flags) ||
                            appState.shortcutSettings.matchesFailsafeShortcut(keyCode: keycode, cgFlags: flags)
        if isUnlockMatch {
            return nil // Swallow shortcut release
        }

        if KeycodeMap.isModifier(keycode) { return nil }

        // Feed unlock trackers
        let _ = chordTracker.onKeyUp(keycode)
        playEngine.onKeyUp(keycode)

        if appState.mode.locksKeyboard {
            return nil // Swallow
        }
        return event
    }

    private func handleFlagsChanged(event: CGEvent) -> CGEvent? {
        // Swallow modifier key events when keyboard is locked
        if appState.mode.locksKeyboard {
            return nil
        }
        return event
    }

    // MARK: - Mouse Events

    private func handleMouseDown(event: CGEvent, isRight: Bool) -> CGEvent? {
        let position = event.location

        // Feed mouse escape tracker
        mouseEscapeTracker.onMouseDown(isRight: isRight)

        if appState.mode.locksMouse {
            // Feed play engine for drawing mode
            playEngine.onMouseClick(position: position)
            return nil // Swallow
        }
        return event
    }

    private func handleMouseUp(event: CGEvent, isRight: Bool) -> CGEvent? {
        mouseEscapeTracker.onMouseUp(isRight: isRight)

        if appState.mode.locksMouse {
            return nil // Swallow
        }
        return event
    }

    private func handleMouseMoved(event: CGEvent) -> CGEvent? {
        let position = event.location

        // Feed corner escape tracker
        cornerTracker.onMouseMoved(position: position)

        // Feed drawing mode
        playEngine.onMouseMoved(position: position)

        if appState.mode.locksMouse {
            return nil // Swallow mouse movement
        }
        return event
    }

    private func handleScrollWheel(event: CGEvent) -> CGEvent? {
        if appState.mode.locksMouse {
            return nil // Swallow scroll
        }
        return event
    }
}

// MARK: - C Callback Function

/// Global C function pointer for CGEvent tap callback
private func inputTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {

    guard let userInfo = userInfo else {
        return Unmanaged.passUnretained(event)
    }

    let manager = Unmanaged<InputTapManager>.fromOpaque(userInfo).takeUnretainedValue()

    if let processedEvent = manager.handleEvent(type: type, event: event) {
        return Unmanaged.passUnretained(processedEvent)
    }

    return nil // Swallow the event
}
