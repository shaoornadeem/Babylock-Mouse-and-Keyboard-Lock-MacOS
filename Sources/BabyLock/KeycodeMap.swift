// KeycodeMap.swift — macOS keycode to character mapping
// Translates CGEvent keycodes to letters/numbers for play mode and unlock logic

import Foundation

struct KeycodeMap {

    // MARK: - macOS Keycodes (ANSI/US keyboard layout)

    static let kVK_ANSI_A: UInt16       = 0x00
    static let kVK_ANSI_S: UInt16       = 0x01
    static let kVK_ANSI_D: UInt16       = 0x02
    static let kVK_ANSI_F: UInt16       = 0x03
    static let kVK_ANSI_H: UInt16       = 0x04
    static let kVK_ANSI_G: UInt16       = 0x05
    static let kVK_ANSI_Z: UInt16       = 0x06
    static let kVK_ANSI_X: UInt16       = 0x07
    static let kVK_ANSI_C: UInt16       = 0x08
    static let kVK_ANSI_V: UInt16       = 0x09
    static let kVK_ANSI_B: UInt16       = 0x0B
    static let kVK_ANSI_Q: UInt16       = 0x0C
    static let kVK_ANSI_W: UInt16       = 0x0D
    static let kVK_ANSI_E: UInt16       = 0x0E
    static let kVK_ANSI_R: UInt16       = 0x0F
    static let kVK_ANSI_Y: UInt16       = 0x10
    static let kVK_ANSI_T: UInt16       = 0x11
    static let kVK_ANSI_1: UInt16       = 0x12
    static let kVK_ANSI_2: UInt16       = 0x13
    static let kVK_ANSI_3: UInt16       = 0x14
    static let kVK_ANSI_4: UInt16       = 0x15
    static let kVK_ANSI_6: UInt16       = 0x16
    static let kVK_ANSI_5: UInt16       = 0x17
    static let kVK_ANSI_Equal: UInt16   = 0x18
    static let kVK_ANSI_9: UInt16       = 0x19
    static let kVK_ANSI_7: UInt16       = 0x1A
    static let kVK_ANSI_Minus: UInt16   = 0x1B
    static let kVK_ANSI_8: UInt16       = 0x1C
    static let kVK_ANSI_0: UInt16       = 0x1D
    static let kVK_ANSI_O: UInt16       = 0x1F
    static let kVK_ANSI_U: UInt16       = 0x20
    static let kVK_ANSI_I: UInt16       = 0x22
    static let kVK_ANSI_P: UInt16       = 0x23
    static let kVK_Return: UInt16       = 0x24
    static let kVK_ANSI_L: UInt16       = 0x25
    static let kVK_ANSI_J: UInt16       = 0x26
    static let kVK_ANSI_K: UInt16       = 0x28
    static let kVK_ANSI_N: UInt16       = 0x2D
    static let kVK_ANSI_M: UInt16       = 0x2E
    static let kVK_Tab: UInt16          = 0x30
    static let kVK_Space: UInt16        = 0x31
    static let kVK_Delete: UInt16       = 0x33
    static let kVK_Escape: UInt16       = 0x35
    static let kVK_Command: UInt16      = 0x37
    static let kVK_Shift: UInt16        = 0x38
    static let kVK_CapsLock: UInt16     = 0x39
    static let kVK_Option: UInt16       = 0x3A
    static let kVK_Control: UInt16      = 0x3B
    static let kVK_RightShift: UInt16   = 0x3C
    static let kVK_RightOption: UInt16  = 0x3D
    static let kVK_RightControl: UInt16 = 0x3E
    static let kVK_F1: UInt16           = 0x7A
    static let kVK_F2: UInt16           = 0x78
    static let kVK_F3: UInt16           = 0x63
    static let kVK_F4: UInt16           = 0x76
    static let kVK_F5: UInt16           = 0x60
    static let kVK_F12: UInt16          = 0x6F

    // MARK: - Keycode → Letter (A-Z)

    /// Maps macOS keycode to alphabetical index 0-25 (A=0, Z=25). Returns nil for non-letter keys.
    static func letterIndex(for keycode: UInt16) -> Int? {
        return keycodeToLetterIndex[keycode]
    }

    /// Maps macOS keycode to Character ('A'-'Z'). Returns nil for non-letter keys.
    static func letter(for keycode: UInt16) -> Character? {
        guard let idx = letterIndex(for: keycode) else { return nil }
        return Character(UnicodeScalar(65 + idx)!) // 'A' = 65
    }

    // MARK: - Keycode → Digit (0-9)

    /// Maps macOS keycode to digit 0-9. Returns nil for non-digit keys.
    static func digit(for keycode: UInt16) -> Int? {
        return keycodeToDigit[keycode]
    }

    // MARK: - Lookups

    static let keycodeToLetterIndex: [UInt16: Int] = [
        kVK_ANSI_A: 0,  kVK_ANSI_B: 1,  kVK_ANSI_C: 2,  kVK_ANSI_D: 3,
        kVK_ANSI_E: 4,  kVK_ANSI_F: 5,  kVK_ANSI_G: 6,  kVK_ANSI_H: 7,
        kVK_ANSI_I: 8,  kVK_ANSI_J: 9,  kVK_ANSI_K: 10, kVK_ANSI_L: 11,
        kVK_ANSI_M: 12, kVK_ANSI_N: 13, kVK_ANSI_O: 14, kVK_ANSI_P: 15,
        kVK_ANSI_Q: 16, kVK_ANSI_R: 17, kVK_ANSI_S: 18, kVK_ANSI_T: 19,
        kVK_ANSI_U: 20, kVK_ANSI_V: 21, kVK_ANSI_W: 22, kVK_ANSI_X: 23,
        kVK_ANSI_Y: 24, kVK_ANSI_Z: 25,
    ]

    static let keycodeToDigit: [UInt16: Int] = [
        kVK_ANSI_0: 0, kVK_ANSI_1: 1, kVK_ANSI_2: 2, kVK_ANSI_3: 3,
        kVK_ANSI_4: 4, kVK_ANSI_5: 5, kVK_ANSI_6: 6, kVK_ANSI_7: 7,
        kVK_ANSI_8: 8, kVK_ANSI_9: 9,
    ]

    /// All letter keycodes for quick membership test
    static let allLetterKeycodes: Set<UInt16> = Set(keycodeToLetterIndex.keys)

    /// All digit keycodes
    static let allDigitKeycodes: Set<UInt16> = Set(keycodeToDigit.keys)

    /// Check if keycode is a modifier key
    static func isModifier(_ keycode: UInt16) -> Bool {
        return keycode == kVK_Command || keycode == kVK_Shift ||
               keycode == kVK_Option || keycode == kVK_Control ||
               keycode == kVK_CapsLock || keycode == kVK_RightShift ||
               keycode == kVK_RightOption || keycode == kVK_RightControl
    }

    /// Reverse lookup: Character ('A'-'Z') to keycode
    static func keyCode(forLetter letter: Character) -> UInt16? {
        let upper = Character(letter.uppercased())
        for (code, idx) in keycodeToLetterIndex {
            if Character(UnicodeScalar(65 + idx)!) == upper {
                return code
            }
        }
        return nil
    }

    /// User-friendly display name for keycode (e.g. "L", "U", "K", "Space", "Return", etc.)
    static func name(for keycode: UInt16) -> String {
        if let char = letter(for: keycode) {
            return String(char)
        }
        if let digit = digit(for: keycode) {
            return String(digit)
        }
        switch keycode {
        case kVK_Return: return "Return"
        case kVK_Tab: return "Tab"
        case kVK_Space: return "Space"
        case kVK_Delete: return "Delete"
        case kVK_Escape: return "Esc"
        case kVK_Command, kVK_RightControl: return "Cmd"
        case kVK_Shift, kVK_RightShift: return "Shift"
        case kVK_Option, kVK_RightOption: return "Option"
        case kVK_Control: return "Ctrl"
        case kVK_ANSI_Equal: return "="
        case kVK_ANSI_Minus: return "-"
        case kVK_F1: return "F1"
        case kVK_F2: return "F2"
        case kVK_F3: return "F3"
        case kVK_F4: return "F4"
        case kVK_F5: return "F5"
        case kVK_F12: return "F12"
        default: return "Key 0x\(String(keycode, radix: 16).uppercased())"
        }
    }

    /// Alphabetically sorted list of all 26 letters (A-Z) with their keycodes for settings dropdowns
    static let allConfigurableLetters: [(keyCode: UInt16, name: String)] = {
        let letters: [(UInt16, String)] = [
            (kVK_ANSI_A, "A"), (kVK_ANSI_B, "B"), (kVK_ANSI_C, "C"), (kVK_ANSI_D, "D"),
            (kVK_ANSI_E, "E"), (kVK_ANSI_F, "F"), (kVK_ANSI_G, "G"), (kVK_ANSI_H, "H"),
            (kVK_ANSI_I, "I"), (kVK_ANSI_J, "J"), (kVK_ANSI_K, "K"), (kVK_ANSI_L, "L"),
            (kVK_ANSI_M, "M"), (kVK_ANSI_N, "N"), (kVK_ANSI_O, "O"), (kVK_ANSI_P, "P"),
            (kVK_ANSI_Q, "Q"), (kVK_ANSI_R, "R"), (kVK_ANSI_S, "S"), (kVK_ANSI_T, "T"),
            (kVK_ANSI_U, "U"), (kVK_ANSI_V, "V"), (kVK_ANSI_W, "W"), (kVK_ANSI_X, "X"),
            (kVK_ANSI_Y, "Y"), (kVK_ANSI_Z, "Z")
        ]
        return letters.sorted { $0.1 < $1.1 }
    }()
}
