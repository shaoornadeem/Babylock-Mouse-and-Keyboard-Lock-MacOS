# 🍼 BabyLock for macOS

**A zero-leak keyboard & mouse lock that transforms your Mac into an interactive sensory playground for toddlers.**

BabyLock intercepts all keyboard and mouse input at the OS level, preventing babies and toddlers from accidentally closing apps, sending emails, or wreaking havoc — while turning every keypress into a fun, educational, hearing-safe audio-visual experience.

---

## ✨ Features

### 🔒 Zero-Leak Input Lock
- Intercepts **all** keyboard and mouse events via CGEvent tap
- Blocks system shortcuts (⌘Tab, ⌘Q, ⌘Space, Mission Control, etc.)
- Three lock modes: Keyboard Only, Mouse Only, or Both
- Prevents accidental quit while locked

### 🔓 Multiple Failsafe Unlocks (Zero Lockouts!)
- **Hold U+K** for 3 seconds (anti-mash: any other key cancels)
- **Type "baby"** anywhere (5-second inactivity timeout resets)
- **Hold Left+Right mouse** for 5 seconds
- **Cursor in top-left corner** for 5 seconds
- **Auto-unlock timer** (5, 15, or 30 minutes)
- **Watchdog thread** auto-unlocks if app hangs for 30+ seconds

### 🎨 Four Interactive Play Modes
1. **Random Mode** — Random themed cards (Animals, Vehicles, Musical, Baby, High Contrast) with speech
2. **Phonics Mode (A-Z)** — Letter flashcards with "A is for Apple!" speech synthesis
3. **Musical Scale Mode** — 26-note pentatonic synthesizer (Xylophone, Piano, Chime) + percussion
4. **Drawing Mode** — Rainbow fluid trails, confetti particles, geometric shape stamps

### 🎵 Procedural Audio Synthesis
- **26 pentatonic notes** (C4–C9) — zero dissonance guaranteed
- **3 instruments**: Xylophone, Piano, Chime (mathematically synthesized)
- **Percussion**: Kick, Snare, Hi-Hat, Clap
- **16-voice polyphony** with voice stealing
- **-12 dBFS soft limiter** — protects tiny ears even with 10 keys pressed simultaneously
- **5ms anti-pop fades** — no clicks or pops

### 🛡️ Safety & System Integration
- Display sleep prevention while locked (IOPMAssertion)
- Crash recovery (persists state to disk)
- Quiet-after timer (stops audio after 15 minutes while keeping lock active)
- Rate limiting (180ms minimum between triggers)
- Auto-repeat suppression (holding a key doesn't spam)

---

## 📋 Requirements

- **macOS 13.0** (Ventura) or later
- **Xcode Command Line Tools** (`xcode-select --install`)
- **Accessibility Permission** (prompted on first launch)

---

## 🚀 Build & Install

### Quick Start
```bash
cd babyLockKeyboardAppForMac
./build.sh
```

### Manual Build
```bash
swift build -c release
```

### Install
```bash
# After building:
cp -r BabyLock.app /Applications/

# Or run directly:
open BabyLock.app
```

### First Run
1. Launch BabyLock — you'll see a 🔓 icon in the menu bar
2. Grant **Accessibility permission** when prompted:
   - System Settings → Privacy & Security → Accessibility → Enable BabyLock
3. Click 🔓 → **Lock Now** (or press ⌘⌥L)

---

## 🎮 Usage

### ⌨️ Customizable Shortcuts & Unlock Keys (New!)
Customize your lock/unlock keys anytime from **Menu Bar → ⌨️ Keyboard Shortcuts...** (`⌘,`):
- **Global Lock/Unlock Shortcut**: Record any custom key combination (e.g. ⌘⌃L, ⌘⌥L, ⌘⇧K) or pick from quick presets and manual checkboxes.
- **Hold-to-Unlock Chord**: Choose any two letters to hold simultaneously (default: **U + K**) and customize the hold duration (1.5s to 5.0s).
- **Emergency Passphrase**: Set your own letter-by-letter unlock word (default: **baby**).
- **Live HUD Feedback**: The lock screen HUD dynamically displays your configured shortcut and keys with real-time hold progress!

### Locking & Unlocking
- **Global Shortcut**: Press your configured shortcut (default **⌘⌃L** / **⌘⌥L**) from ANY app to lock or unlock immediately.
- **Menu Bar**: Click 🔓 / 🔒 icon → Lock Now / Unlock Now.

### Unlocking Failsafes (any of these methods)
| Method | How | Customization |
|--------|-----|---------------|
| **Global Shortcut** | Press **⌘⌃L** / **⌘⌥L** (or your custom combo) | Fully customizable in Settings |
| **Hold Chord** | Hold **U** and **K** (or your chosen keys) for 3s | Choose any 2 keys & duration |
| **Passphrase** | Type **b-a-b-y** (within 5 seconds between keys) | Customizable in Settings |
| **Mouse Escape** | Hold **Left + Right mouse buttons** for 5 seconds | Built-in emergency failsafe |
| **Corner Escape** | Move cursor to **top-left corner** for 5 seconds | Built-in emergency failsafe |
| **Auto-Unlock** | Optional 5/15/30/60 min timer | Default: Never (indefinite play) |

### Menu Bar Settings
```
🔓 Lock Now (⌘⌃L)
───────────────────
🛡️ Lock Mode
   ├── Keyboard & Mouse ✓
   ├── Keyboard Only
   └── Mouse Only
🎨 Play Mode
   ├── Enabled ✓
   ├── Theme → Animals / Vehicles / Musical / Baby / High Contrast
   ├── Mode → Random / Phonics / Musical Scale / Drawing
   ├── Voice → Cute Little Girl / Cute Little Boy
   └── Instrument → Xylophone / Piano / Chime
🗣️ Speech Speed
   ├── 🐢 Very Slow (0.3x)
   ├── 🚶 Slow (0.4x) ✓ (Recommended for toddlers)
   ├── ⚡ Normal (0.5x)
   ├── 🐇 Fast (0.6x)
   └── 🚀 Very Fast (0.7x)
⏱️ Display Duration
   ├── 1.5 Seconds
   ├── 2.0 Seconds
   ├── 2.5 Seconds
   ├── 3.0 Seconds ✓ (Recommended)
   ├── 4.0 Seconds
   └── 5.0 Seconds
🔊 Volume → Low (30%) / Medium (65%) / High (100%)
⏱️ Auto-Unlock Timer → 5min / 15min / 30min / Never
───────────────────
⚙️ Launch at Login
⌨️ Keyboard Shortcuts... (⌘,)
ℹ️ About BabyLock
───────────────────
❌ Quit BabyLock (⌘Q)
```

---

## 🏗️ Architecture

| Module | Purpose |
|--------|---------|
| `AppState` | Thread-safe global state, timer, settings |
| `ShortcutSettings` | Persistent configuration for custom shortcuts, hold chord keys & duration |
| `SettingsWindow` | Native macOS preferences window with interactive shortcut recorder & presets |
| `GlobalHotKeyManager`| System-wide Carbon hotkey registration for instant lock/unlock |
| `InputTapManager` | CGEvent tap for input interception and dynamic hotkey swallowing |
| `UnlockStateMachine` | Failsafe unlock mechanisms (Hold Chord, Passphrase, Mouse, Corner) |
| `PlayEngine` | Mode dispatcher, rate limiting, anti-repeat |
| `AudioEngine` | AVAudioEngine, 16-voice polyphony |
| `PentatonicSynth` | Procedural instrument/percussion synthesis |
| `DrawingCanvas` | Rainbow trails, particles, shapes (60fps) |
| `OverlayWindow` | Fullscreen overlays, phonics cards, dynamic HUD |
| `PhonicsData` | A-Z/0-9 mappings, theme entries |
| `SystemGuard` | Display sleep prevention, crash recovery |
| `Watchdog` | Anti-hang thread (auto-unlock on hang) |
| `MenuBarController` | NSStatusItem menu, settings, lifecycle |

---

## 🔐 Privacy & Security

- **100% offline** — zero network calls, zero telemetry
- **Zero background CPU** when unlocked — audio engine only runs during lock
- **No data collection** — settings stored locally only
- **Accessibility permission** is used exclusively for input interception

---

## ⚠️ Important Notes

1. The app uses a **private macOS API** (`CGSSetGlobalHotKeyOperatingMode`) to block system shortcuts like ⌘Tab. This works but is not officially supported by Apple.
2. If the app crashes while locked, simply relaunch it — crash recovery will clean up automatically.
3. The pentatonic scale guarantees **every random key combination sounds pleasant** — no dissonant notes!

---

## 📝 License

This software is provided as-is for personal use.
