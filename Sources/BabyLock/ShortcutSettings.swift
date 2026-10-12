// ShortcutSettings.swift — Customizable Keyboard Shortcuts & Unlock Key Chords
// Thread-safe persistence and translation between Carbon, CGEvent, and Cocoa

import Foundation
import Carbon
import AppKit
import CoreGraphics

// MARK: - Shortcut Modifiers (OptionSet)

struct ShortcutModifiers: OptionSet, Codable, Equatable {
    let rawValue: UInt

    static let command = ShortcutModifiers(rawValue: 1 << 0)
    static let option  = ShortcutModifiers(rawValue: 1 << 1)
    static let control = ShortcutModifiers(rawValue: 1 << 2)
    static let shift   = ShortcutModifiers(rawValue: 1 << 3)

    init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    init(cocoaFlags: NSEvent.ModifierFlags) {
        var mods: ShortcutModifiers = []
        let clean = cocoaFlags.intersection(.deviceIndependentFlagsMask)
        if clean.contains(.command) { mods.insert(.command) }
        if clean.contains(.option)  { mods.insert(.option) }
        if clean.contains(.control) { mods.insert(.control) }
        if clean.contains(.shift)   { mods.insert(.shift) }
        self = mods
    }

    var cocoaFlags: NSEvent.ModifierFlags {
        var flags: NSEvent.ModifierFlags = []
        if contains(.command) { flags.insert(.command) }
        if contains(.option)  { flags.insert(.option) }
        if contains(.control) { flags.insert(.control) }
        if contains(.shift)   { flags.insert(.shift) }
        return flags
    }

    var carbonModifiers: UInt32 {
        var mods: UInt32 = 0
        if contains(.command) { mods |= UInt32(cmdKey) }
        if contains(.option)  { mods |= UInt32(optionKey) }
        if contains(.control) { mods |= UInt32(controlKey) }
        if contains(.shift)   { mods |= UInt32(shiftKey) }
        return mods
    }

    var displayString: String {
        var s = ""
        if contains(.control) { s += "⌃" }
        if contains(.option)  { s += "⌥" }
        if contains(.shift)   { s += "⇧" }
        if contains(.command) { s += "⌘" }
        return s
    }

    var displayTitle: String {
        var parts: [String] = []
        if contains(.control) { parts.append("Control") }
        if contains(.option)  { parts.append("Option") }
        if contains(.shift)   { parts.append("Shift") }
        if contains(.command) { parts.append("Command") }
        return parts.isEmpty ? "None" : parts.joined(separator: " + ")
    }

    func matches(cgFlags: CGEventFlags) -> Bool {
        let hasCmd = cgFlags.contains(.maskCommand)
        let hasOpt = cgFlags.contains(.maskAlternate)
        let hasCtrl = cgFlags.contains(.maskControl)
        let hasShift = cgFlags.contains(.maskShift)

        return hasCmd == contains(.command) &&
               hasOpt == contains(.option) &&
               hasCtrl == contains(.control) &&
               hasShift == contains(.shift)
    }

    func matches(nsFlags: NSEvent.ModifierFlags) -> Bool {
        let clean = nsFlags.intersection(.deviceIndependentFlagsMask)
        let hasCmd = clean.contains(.command)
        let hasOpt = clean.contains(.option)
        let hasCtrl = clean.contains(.control)
        let hasShift = clean.contains(.shift)

        return hasCmd == contains(.command) &&
               hasOpt == contains(.option) &&
               hasCtrl == contains(.control) &&
               hasShift == contains(.shift)
    }
}

// MARK: - Shortcut Settings Model

class ShortcutSettings {

    static let defaultsKey = "BabyLock_ShortcutSettings_v2"

    // --- 1. Global Lock/Unlock Shortcut ---
    var lockKeyCode: UInt16
    var lockModifiers: ShortcutModifiers

    // --- 2. Hold Chord Unlock Keys (e.g. U + K for 3s) ---
    var chordKey1: UInt16
    var chordKey2: UInt16
    var chordDuration: Double

    // --- 3. Passphrase Unlock (e.g. "baby") ---
    var passphrase: String

    // --- Callback when settings change ---
    var onChange: (() -> Void)?

    init(lockKeyCode: UInt16 = KeycodeMap.kVK_ANSI_L,
         lockModifiers: ShortcutModifiers = [.command, .control],
         chordKey1: UInt16 = KeycodeMap.kVK_ANSI_U,
         chordKey2: UInt16 = KeycodeMap.kVK_ANSI_K,
         chordDuration: Double = 3.0,
         passphrase: String = "baby") {
        self.lockKeyCode = lockKeyCode
        self.lockModifiers = lockModifiers
        self.chordKey1 = chordKey1
        self.chordKey2 = chordKey2
        self.chordDuration = chordDuration
        self.passphrase = passphrase.lowercased()
    }

    // MARK: - Computed Properties for UI

    var lockKeyName: String {
        return KeycodeMap.name(for: lockKeyCode)
    }

    var lockShortcutDisplay: String {
        return "\(lockModifiers.displayString)\(lockKeyName)"
    }

    var menuKeyEquivalent: String {
        if let char = KeycodeMap.letter(for: lockKeyCode) {
            return String(char).lowercased()
        }
        if let dig = KeycodeMap.digit(for: lockKeyCode) {
            return String(dig)
        }
        return "l"
    }

    var cocoaModifierFlags: NSEvent.ModifierFlags {
        return lockModifiers.cocoaFlags
    }

    var lockCarbonModifiers: UInt32 {
        return lockModifiers.carbonModifiers
    }

    var chordKey1Name: String {
        return KeycodeMap.name(for: chordKey1)
    }

    var chordKey2Name: String {
        return KeycodeMap.name(for: chordKey2)
    }

    var chordDurationDisplay: String {
        if chordDuration.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0fs", chordDuration)
        } else {
            return String(format: "%.1fs", chordDuration)
        }
    }

    var chordDisplay: String {
        return "Hold \(chordKey1Name)+\(chordKey2Name) for \(chordDurationDisplay)"
    }

    var hudInstructionText: String {
        return "Hold \(chordKey1Name)+\(chordKey2Name) \(chordDurationDisplay) • \(lockShortcutDisplay)"
    }

    var passphraseKeycodes: [UInt16] {
        var codes: [UInt16] = []
        for char in passphrase.uppercased() {
            if let code = KeycodeMap.keyCode(forLetter: char) {
                codes.append(code)
            }
        }
        return codes.isEmpty ? [KeycodeMap.kVK_ANSI_B, KeycodeMap.kVK_ANSI_A, KeycodeMap.kVK_ANSI_B, KeycodeMap.kVK_ANSI_Y] : codes
    }

    // MARK: - Matching Logic

    func matchesLockShortcut(keyCode: UInt16, cgFlags: CGEventFlags) -> Bool {
        if keyCode == lockKeyCode && lockModifiers.matches(cgFlags: cgFlags) {
            return true
        }
        return false
    }

    func matchesLockShortcut(keyCode: UInt16, nsFlags: NSEvent.ModifierFlags) -> Bool {
        if keyCode == lockKeyCode && lockModifiers.matches(nsFlags: nsFlags) {
            return true
        }
        return false
    }

    /// Failsafe emergency shortcut (⌘⌥L or ⌃⌥L) in case user forgets custom shortcut
    func matchesFailsafeShortcut(keyCode: UInt16, cgFlags: CGEventFlags) -> Bool {
        guard keyCode == KeycodeMap.kVK_ANSI_L else { return false }
        let hasCmd = cgFlags.contains(.maskCommand)
        let hasOpt = cgFlags.contains(.maskAlternate)
        let hasCtrl = cgFlags.contains(.maskControl)
        return (hasCmd && hasOpt) || (hasCtrl && hasOpt)
    }

    func matchesFailsafeShortcut(keyCode: UInt16, nsFlags: NSEvent.ModifierFlags) -> Bool {
        guard keyCode == KeycodeMap.kVK_ANSI_L else { return false }
        let clean = nsFlags.intersection(.deviceIndependentFlagsMask)
        let hasCmd = clean.contains(.command)
        let hasOpt = clean.contains(.option)
        let hasCtrl = clean.contains(.control)
        return (hasCmd && hasOpt) || (hasCtrl && hasOpt)
    }

    // MARK: - Persistence

    func save() {
        let dict: [String: Any] = [
            "lockKeyCode": Int(lockKeyCode),
            "lockModifiers": Int(lockModifiers.rawValue),
            "chordKey1": Int(chordKey1),
            "chordKey2": Int(chordKey2),
            "chordDuration": chordDuration,
            "passphrase": passphrase
        ]
        UserDefaults.standard.set(dict, forKey: ShortcutSettings.defaultsKey)
        onChange?()
    }

    static func load() -> ShortcutSettings {
        guard let dict = UserDefaults.standard.dictionary(forKey: defaultsKey) else {
            return ShortcutSettings()
        }

        let key = UInt16(dict["lockKeyCode"] as? Int ?? Int(KeycodeMap.kVK_ANSI_L))
        let modsRaw = UInt(dict["lockModifiers"] as? Int ?? Int(ShortcutModifiers([.command, .control]).rawValue))
        let k1 = UInt16(dict["chordKey1"] as? Int ?? Int(KeycodeMap.kVK_ANSI_U))
        let k2 = UInt16(dict["chordKey2"] as? Int ?? Int(KeycodeMap.kVK_ANSI_K))
        let dur = dict["chordDuration"] as? Double ?? 3.0
        let pass = dict["passphrase"] as? String ?? "baby"

        return ShortcutSettings(
            lockKeyCode: key,
            lockModifiers: ShortcutModifiers(rawValue: modsRaw),
            chordKey1: k1,
            chordKey2: k2,
            chordDuration: dur,
            passphrase: pass
        )
    }

    func resetToDefaults() {
        lockKeyCode = KeycodeMap.kVK_ANSI_L
        lockModifiers = [.command, .control]
        chordKey1 = KeycodeMap.kVK_ANSI_U
        chordKey2 = KeycodeMap.kVK_ANSI_K
        chordDuration = 3.0
        passphrase = "baby"
        save()
    }
}
