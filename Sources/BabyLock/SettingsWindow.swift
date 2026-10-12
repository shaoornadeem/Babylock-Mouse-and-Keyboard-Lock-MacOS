// SettingsWindow.swift — Native macOS Preferences Window for BabyLock
// Full customization for shortcuts, failsafe hold chord keys, auto-unlock timer, and toddler play mode

import AppKit
import Carbon

class SettingsWindowController: NSWindowController, NSWindowDelegate {

    static let shared = SettingsWindowController()

    private var appState: AppState?
    private var isRecording = false
    private var recordingMonitor: Any?

    // UI Elements - Lock Shortcut
    private var currentShortcutBadge: NSTextField!
    private var recordButton: NSButton!
    private var cmdCheckbox: NSButton!
    private var ctrlCheckbox: NSButton!
    private var optCheckbox: NSButton!
    private var shiftCheckbox: NSButton!
    private var lockKeyPopup: NSPopUpButton!

    // UI Elements - Chord Keys
    private var chordKey1Popup: NSPopUpButton!
    private var chordKey2Popup: NSPopUpButton!
    private var chordDurationPopup: NSPopUpButton!
    private var chordPreviewLabel: NSTextField!

    // UI Elements - Passphrase
    private var passphraseField: NSTextField!

    // UI Elements - Auto-Unlock & Play Mode
    private var autoUnlockPopup: NSPopUpButton!
    private var playModePopup: NSPopUpButton!

    // UI Elements - Status & Feedback
    private var statusLabel: NSTextField!

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 720),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "BabyLock Settings"
        window.center()
        window.isReleasedWhenClosed = false
        self.init(window: window)
        window.delegate = self
    }

    func show(with appState: AppState) {
        self.appState = appState
        if window?.contentView?.subviews.isEmpty ?? true {
            setupUI()
        }
        updateUIFromSettings()

        guard let win = window else { return }
        NSApp.activate(ignoringOtherApps: true)
        win.makeKeyAndOrderFront(nil)
    }

    // MARK: - UI Construction

    private func setupUI() {
        guard let win = window else { return }

        let container = NSView(frame: win.contentView!.bounds)
        container.autoresizingMask = [.width, .height]
        win.contentView = container

        var y: CGFloat = 665

        // 1. Header
        let iconLabel = NSTextField(labelWithString: "🍼")
        iconLabel.font = NSFont.systemFont(ofSize: 34)
        iconLabel.frame = NSRect(x: 24, y: y - 8, width: 44, height: 44)
        container.addSubview(iconLabel)

        let titleLabel = NSTextField(labelWithString: "BabyLock Preferences")
        titleLabel.font = NSFont.systemFont(ofSize: 18, weight: .bold)
        titleLabel.frame = NSRect(x: 74, y: y + 10, width: 420, height: 24)
        container.addSubview(titleLabel)

        let subtitleLabel = NSTextField(labelWithString: "Configure lock shortcuts, timeout, and toddler play mode")
        subtitleLabel.font = NSFont.systemFont(ofSize: 12, weight: .regular)
        subtitleLabel.textColor = .secondaryLabelColor
        subtitleLabel.frame = NSRect(x: 74, y: y - 8, width: 420, height: 18)
        container.addSubview(subtitleLabel)

        y -= 45
        addDivider(to: container, y: y)

        // 2. Section: Global Lock / Unlock Shortcut
        y -= 28
        let lockSectionTitle = NSTextField(labelWithString: "🔒 Global Lock / Unlock Shortcut")
        lockSectionTitle.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        lockSectionTitle.frame = NSRect(x: 24, y: y, width: 470, height: 20)
        container.addSubview(lockSectionTitle)

        y -= 18
        let lockDesc = NSTextField(labelWithString: "Press this shortcut from ANY app to instantly lock or unlock:")
        lockDesc.font = NSFont.systemFont(ofSize: 11)
        lockDesc.textColor = .secondaryLabelColor
        lockDesc.frame = NSRect(x: 24, y: y, width: 470, height: 18)
        container.addSubview(lockDesc)

        // Shortcut Badge + Record Button Row
        y -= 44
        let badgeBox = NSBox(frame: NSRect(x: 24, y: y, width: 220, height: 38))
        badgeBox.boxType = .custom
        badgeBox.cornerRadius = 8
        badgeBox.borderWidth = 1
        badgeBox.borderColor = NSColor.separatorColor
        badgeBox.fillColor = NSColor.controlBackgroundColor

        currentShortcutBadge = NSTextField(labelWithString: "⌘ ⌃ L")
        currentShortcutBadge.font = NSFont.monospacedSystemFont(ofSize: 17, weight: .bold)
        currentShortcutBadge.alignment = .center
        currentShortcutBadge.frame = NSRect(x: 0, y: 7, width: 220, height: 24)
        badgeBox.addSubview(currentShortcutBadge)
        container.addSubview(badgeBox)

        recordButton = NSButton(title: "⏺ Record Shortcut", target: self, action: #selector(toggleRecording))
        recordButton.bezelStyle = .rounded
        recordButton.frame = NSRect(x: 254, y: y + 3, width: 170, height: 32)
        container.addSubview(recordButton)

        // Quick Presets Row
        y -= 32
        let presetsLabel = NSTextField(labelWithString: "Quick Presets:")
        presetsLabel.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        presetsLabel.textColor = .secondaryLabelColor
        presetsLabel.frame = NSRect(x: 24, y: y + 3, width: 85, height: 18)
        container.addSubview(presetsLabel)

        let presets: [(String, UInt16, ShortcutModifiers)] = [
            ("⌘⌃L", KeycodeMap.kVK_ANSI_L, [.command, .control]),
            ("⌘⌥L", KeycodeMap.kVK_ANSI_L, [.command, .option]),
            ("⌃⌥L", KeycodeMap.kVK_ANSI_L, [.control, .option]),
            ("⌘⇧L", KeycodeMap.kVK_ANSI_L, [.command, .shift]),
        ]

        var presetX: CGFloat = 115
        for (label, key, mods) in presets {
            let btn = NSButton(title: label, target: self, action: #selector(selectPreset(_:)))
            btn.bezelStyle = .roundRect
            btn.frame = NSRect(x: presetX, y: y, width: 60, height: 24)
            btn.tag = Int(key)
            btn.identifier = NSUserInterfaceItemIdentifier("\(mods.rawValue)")
            container.addSubview(btn)
            presetX += 66
        }

        // Manual Modifiers Checkboxes + Key PopUp
        y -= 34
        let manualLabel = NSTextField(labelWithString: "Or choose:")
        manualLabel.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        manualLabel.textColor = .secondaryLabelColor
        manualLabel.frame = NSRect(x: 24, y: y + 2, width: 70, height: 18)
        container.addSubview(manualLabel)

        cmdCheckbox = NSButton(checkboxWithTitle: "⌘ Cmd", target: self, action: #selector(modifierCheckboxChanged))
        cmdCheckbox.frame = NSRect(x: 95, y: y, width: 68, height: 20)
        container.addSubview(cmdCheckbox)

        ctrlCheckbox = NSButton(checkboxWithTitle: "⌃ Ctrl", target: self, action: #selector(modifierCheckboxChanged))
        ctrlCheckbox.frame = NSRect(x: 165, y: y, width: 64, height: 20)
        container.addSubview(ctrlCheckbox)

        optCheckbox = NSButton(checkboxWithTitle: "⌥ Opt", target: self, action: #selector(modifierCheckboxChanged))
        optCheckbox.frame = NSRect(x: 232, y: y, width: 64, height: 20)
        container.addSubview(optCheckbox)

        shiftCheckbox = NSButton(checkboxWithTitle: "⇧ Shift", target: self, action: #selector(modifierCheckboxChanged))
        shiftCheckbox.frame = NSRect(x: 298, y: y, width: 68, height: 20)
        container.addSubview(shiftCheckbox)

        lockKeyPopup = NSPopUpButton(frame: NSRect(x: 372, y: y - 2, width: 65, height: 24), pullsDown: false)
        for (code, name) in KeycodeMap.allConfigurableLetters {
            lockKeyPopup.addItem(withTitle: name)
            lockKeyPopup.lastItem?.tag = Int(code)
        }
        lockKeyPopup.target = self
        lockKeyPopup.action = #selector(lockKeyPopupChanged)
        container.addSubview(lockKeyPopup)

        y -= 22
        addDivider(to: container, y: y)

        // 3. Section: Hold-to-Unlock Failsafe Keys
        y -= 26
        let chordSectionTitle = NSTextField(labelWithString: "🔓 Hold-to-Unlock Failsafe Keys")
        chordSectionTitle.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        chordSectionTitle.frame = NSRect(x: 24, y: y, width: 470, height: 20)
        container.addSubview(chordSectionTitle)

        y -= 18
        let chordDesc = NSTextField(labelWithString: "Hold these two keys simultaneously on the keyboard to unlock anywhere:")
        chordDesc.font = NSFont.systemFont(ofSize: 11)
        chordDesc.textColor = .secondaryLabelColor
        chordDesc.frame = NSRect(x: 24, y: y, width: 470, height: 18)
        container.addSubview(chordDesc)

        // Key 1 + Key 2 Pickers
        y -= 32
        let key1Label = NSTextField(labelWithString: "First Key:")
        key1Label.font = NSFont.systemFont(ofSize: 12)
        key1Label.frame = NSRect(x: 24, y: y + 2, width: 65, height: 18)
        container.addSubview(key1Label)

        chordKey1Popup = NSPopUpButton(frame: NSRect(x: 92, y: y, width: 70, height: 24), pullsDown: false)
        for (code, name) in KeycodeMap.allConfigurableLetters {
            chordKey1Popup.addItem(withTitle: name)
            chordKey1Popup.lastItem?.tag = Int(code)
        }
        chordKey1Popup.target = self
        chordKey1Popup.action = #selector(chordKeysChanged)
        container.addSubview(chordKey1Popup)

        let plusLabel = NSTextField(labelWithString: "+")
        plusLabel.font = NSFont.systemFont(ofSize: 15, weight: .bold)
        plusLabel.frame = NSRect(x: 172, y: y + 2, width: 16, height: 18)
        container.addSubview(plusLabel)

        let key2Label = NSTextField(labelWithString: "Second Key:")
        key2Label.font = NSFont.systemFont(ofSize: 12)
        key2Label.frame = NSRect(x: 196, y: y + 2, width: 80, height: 18)
        container.addSubview(key2Label)

        chordKey2Popup = NSPopUpButton(frame: NSRect(x: 280, y: y, width: 70, height: 24), pullsDown: false)
        for (code, name) in KeycodeMap.allConfigurableLetters {
            chordKey2Popup.addItem(withTitle: name)
            chordKey2Popup.lastItem?.tag = Int(code)
        }
        chordKey2Popup.target = self
        chordKey2Popup.action = #selector(chordKeysChanged)
        container.addSubview(chordKey2Popup)

        // Duration Picker
        y -= 30
        let durationLabel = NSTextField(labelWithString: "Hold Duration:")
        durationLabel.font = NSFont.systemFont(ofSize: 12)
        durationLabel.frame = NSRect(x: 24, y: y + 2, width: 95, height: 18)
        container.addSubview(durationLabel)

        chordDurationPopup = NSPopUpButton(frame: NSRect(x: 125, y: y, width: 180, height: 24), pullsDown: false)
        let durations: [(String, Double)] = [
            ("1.5 seconds", 1.5),
            ("2.0 seconds", 2.0),
            ("3.0 seconds (Default)", 3.0),
            ("4.0 seconds", 4.0),
            ("5.0 seconds", 5.0),
        ]
        for (title, dur) in durations {
            chordDurationPopup.addItem(withTitle: title)
            chordDurationPopup.lastItem?.representedObject = dur
        }
        chordDurationPopup.target = self
        chordDurationPopup.action = #selector(chordDurationChanged)
        container.addSubview(chordDurationPopup)

        // Live Preview Box
        y -= 34
        let previewBox = NSBox(frame: NSRect(x: 24, y: y, width: 470, height: 30))
        previewBox.boxType = .custom
        previewBox.cornerRadius = 6
        previewBox.fillColor = NSColor.systemTeal.withAlphaComponent(0.12)
        previewBox.borderColor = NSColor.systemTeal.withAlphaComponent(0.3)
        previewBox.borderWidth = 1

        chordPreviewLabel = NSTextField(labelWithString: "💡 Press and hold U and K simultaneously for 3.0s to unlock")
        chordPreviewLabel.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        chordPreviewLabel.textColor = .labelColor
        chordPreviewLabel.frame = NSRect(x: 10, y: 5, width: 450, height: 18)
        previewBox.addSubview(chordPreviewLabel)
        container.addSubview(previewBox)

        y -= 20
        addDivider(to: container, y: y)

        // 4. Section: Emergency Passphrase
        y -= 26
        let passSectionTitle = NSTextField(labelWithString: "🔤 Emergency Word Passphrase")
        passSectionTitle.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        passSectionTitle.frame = NSRect(x: 24, y: y, width: 470, height: 20)
        container.addSubview(passSectionTitle)

        y -= 28
        let passLabel = NSTextField(labelWithString: "Passphrase:")
        passLabel.font = NSFont.systemFont(ofSize: 12)
        passLabel.frame = NSRect(x: 24, y: y + 2, width: 80, height: 18)
        container.addSubview(passLabel)

        passphraseField = NSTextField(frame: NSRect(x: 105, y: y, width: 120, height: 24))
        passphraseField.placeholderString = "baby"
        passphraseField.target = self
        passphraseField.action = #selector(passphraseChanged)
        container.addSubview(passphraseField)

        let passTip = NSTextField(labelWithString: "(Type letter-by-letter while locked to unlock. Default: baby)")
        passTip.font = NSFont.systemFont(ofSize: 11)
        passTip.textColor = .secondaryLabelColor
        passTip.frame = NSRect(x: 235, y: y + 2, width: 265, height: 18)
        container.addSubview(passTip)

        y -= 20
        addDivider(to: container, y: y)

        // 5. Section: Auto-Unlock Timeout & Toddler Play Mode (NEW!)
        y -= 26
        let timeoutSectionTitle = NSTextField(labelWithString: "⏱️ Auto-Unlock Timeout & Toddler Play Mode")
        timeoutSectionTitle.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        timeoutSectionTitle.frame = NSRect(x: 24, y: y, width: 470, height: 20)
        container.addSubview(timeoutSectionTitle)

        // Auto-Unlock Timeout Row
        y -= 30
        let timeoutLabel = NSTextField(labelWithString: "Auto-Unlock:")
        timeoutLabel.font = NSFont.systemFont(ofSize: 12)
        timeoutLabel.frame = NSRect(x: 24, y: y + 2, width: 95, height: 18)
        container.addSubview(timeoutLabel)

        autoUnlockPopup = NSPopUpButton(frame: NSRect(x: 120, y: y, width: 210, height: 24), pullsDown: false)
        for duration in AutoUnlockDuration.allCases {
            autoUnlockPopup.addItem(withTitle: duration.displayName)
            autoUnlockPopup.lastItem?.tag = duration.rawValue
        }
        autoUnlockPopup.target = self
        autoUnlockPopup.action = #selector(autoUnlockPopupChanged)
        container.addSubview(autoUnlockPopup)

        let timeoutTip = NSTextField(labelWithString: "(Default: Never — stays locked indefinitely)")
        timeoutTip.font = NSFont.systemFont(ofSize: 11)
        timeoutTip.textColor = .secondaryLabelColor
        timeoutTip.frame = NSRect(x: 338, y: y + 2, width: 165, height: 18)
        container.addSubview(timeoutTip)

        // Play Mode Row
        y -= 30
        let modeLabel = NSTextField(labelWithString: "Play Mode:")
        modeLabel.font = NSFont.systemFont(ofSize: 12)
        modeLabel.frame = NSRect(x: 24, y: y + 2, width: 95, height: 18)
        container.addSubview(modeLabel)

        playModePopup = NSPopUpButton(frame: NSRect(x: 120, y: y, width: 210, height: 24), pullsDown: false)
        for mode in KeyBehaviorMode.allCases {
            let title = (mode == .letters) ? "Phonics (A-Z) (Default)" : mode.displayName
            playModePopup.addItem(withTitle: title)
            playModePopup.lastItem?.tag = mode.rawValue
        }
        playModePopup.target = self
        playModePopup.action = #selector(playModePopupChanged)
        container.addSubview(playModePopup)

        let modeTip = NSTextField(labelWithString: "(A for Apple, E for Elephant, etc.)")
        modeTip.font = NSFont.systemFont(ofSize: 11)
        modeTip.textColor = .secondaryLabelColor
        modeTip.frame = NSRect(x: 338, y: y + 2, width: 165, height: 18)
        container.addSubview(modeTip)

        y -= 22
        addDivider(to: container, y: y)

        // 6. Footer Buttons & Status
        y -= 38
        let resetBtn = NSButton(title: "↺ Reset Defaults", target: self, action: #selector(resetDefaults))
        resetBtn.bezelStyle = .rounded
        resetBtn.frame = NSRect(x: 20, y: y, width: 140, height: 32)
        container.addSubview(resetBtn)

        statusLabel = NSTextField(labelWithString: "✓ Settings active across all apps")
        statusLabel.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        statusLabel.textColor = NSColor.systemGreen
        statusLabel.frame = NSRect(x: 170, y: y + 6, width: 220, height: 18)
        container.addSubview(statusLabel)

        let doneBtn = NSButton(title: "Done", target: self, action: #selector(closeWindow))
        doneBtn.bezelStyle = .rounded
        doneBtn.keyEquivalent = "\r"
        doneBtn.frame = NSRect(x: 400, y: y, width: 95, height: 32)
        container.addSubview(doneBtn)
    }

    private func addDivider(to container: NSView, y: CGFloat) {
        let divider = NSBox(frame: NSRect(x: 24, y: y, width: 470, height: 1))
        divider.boxType = .separator
        container.addSubview(divider)
    }

    // MARK: - Synchronize UI with Settings

    private func updateUIFromSettings() {
        guard let state = appState else { return }
        let settings = state.shortcutSettings

        // Update badge
        currentShortcutBadge.stringValue = settings.lockShortcutDisplay

        // Update checkboxes
        cmdCheckbox.state = settings.lockModifiers.contains(.command) ? .on : .off
        ctrlCheckbox.state = settings.lockModifiers.contains(.control) ? .on : .off
        optCheckbox.state = settings.lockModifiers.contains(.option) ? .on : .off
        shiftCheckbox.state = settings.lockModifiers.contains(.shift) ? .on : .off

        // Update lock key popup
        lockKeyPopup.selectItem(withTitle: settings.lockKeyName)

        // Update chord popups
        chordKey1Popup.selectItem(withTitle: settings.chordKey1Name)
        chordKey2Popup.selectItem(withTitle: settings.chordKey2Name)

        // Update chord duration popup
        for item in chordDurationPopup.itemArray {
            if let dur = item.representedObject as? Double, abs(dur - settings.chordDuration) < 0.05 {
                chordDurationPopup.select(item)
                break
            }
        }

        // Update preview label
        updateChordPreview()

        // Update passphrase field
        passphraseField.stringValue = settings.passphrase

        // Update auto-unlock popup
        autoUnlockPopup.selectItem(withTag: state.autoUnlockMinutes)

        // Update play mode popup
        playModePopup.selectItem(withTag: state.playMode.rawValue)
    }

    private func updateChordPreview() {
        guard let settings = appState?.shortcutSettings else { return }
        chordPreviewLabel.stringValue = "💡 Press and hold \(settings.chordKey1Name) and \(settings.chordKey2Name) simultaneously for \(settings.chordDurationDisplay) to unlock"
    }

    private func showSavedStatus(_ message: String = "✓ Saved & active immediately") {
        statusLabel.stringValue = message
        statusLabel.textColor = NSColor.systemGreen
    }

    // MARK: - Actions

    @objc private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        isRecording = true
        recordButton.title = "⌨️ Press Keys... (Esc)"
        recordButton.highlight(true)
        currentShortcutBadge.stringValue = "Press keys now..."
        statusLabel.stringValue = "Listening for key combination..."
        statusLabel.textColor = NSColor.systemOrange

        // Capture keystrokes locally
        recordingMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            guard let self = self, self.isRecording else { return event }

            if event.keyCode == KeycodeMap.kVK_Escape {
                self.stopRecording()
                self.updateUIFromSettings()
                return nil // Swallow escape
            }

            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let hasModifier = flags.contains(.command) || flags.contains(.option) || flags.contains(.control) || flags.contains(.shift)

            if KeycodeMap.isModifier(event.keyCode) {
                // Modifier only, keep waiting for the character key
                return nil
            }

            if !hasModifier {
                self.statusLabel.stringValue = "⚠️ Shortcut needs a modifier (⌘, ⌃, or ⌥)"
                self.statusLabel.textColor = NSColor.systemRed
                return nil
            }

            // Valid combination recorded!
            self.applyRecordedShortcut(keyCode: event.keyCode, cocoaFlags: flags)
            self.stopRecording()
            return nil
        }
    }

    private func stopRecording() {
        isRecording = false
        recordButton.title = "⏺ Record Shortcut"
        recordButton.highlight(false)
        if let mon = recordingMonitor {
            NSEvent.removeMonitor(mon)
            recordingMonitor = nil
        }
    }

    private func applyRecordedShortcut(keyCode: UInt16, cocoaFlags: NSEvent.ModifierFlags) {
        guard let settings = appState?.shortcutSettings else { return }

        settings.lockKeyCode = keyCode
        settings.lockModifiers = ShortcutModifiers(cocoaFlags: cocoaFlags)
        settings.save()

        updateUIFromSettings()
        showSavedStatus()
        notifyAppState()
    }

    @objc private func selectPreset(_ sender: NSButton) {
        guard let settings = appState?.shortcutSettings else { return }
        let key = UInt16(sender.tag)
        guard let rawStr = sender.identifier?.rawValue, let raw = UInt(rawStr) else { return }

        settings.lockKeyCode = key
        settings.lockModifiers = ShortcutModifiers(rawValue: raw)
        settings.save()

        updateUIFromSettings()
        showSavedStatus()
        notifyAppState()
    }

    @objc private func modifierCheckboxChanged() {
        guard let settings = appState?.shortcutSettings else { return }

        var mods: ShortcutModifiers = []
        if cmdCheckbox.state == .on { mods.insert(.command) }
        if ctrlCheckbox.state == .on { mods.insert(.control) }
        if optCheckbox.state == .on { mods.insert(.option) }
        if shiftCheckbox.state == .on { mods.insert(.shift) }

        if mods.isEmpty {
            // Require at least one modifier
            mods = [.command]
            cmdCheckbox.state = .on
        }

        settings.lockModifiers = mods
        settings.save()

        currentShortcutBadge.stringValue = settings.lockShortcutDisplay
        showSavedStatus()
        notifyAppState()
    }

    @objc private func lockKeyPopupChanged() {
        guard let settings = appState?.shortcutSettings else { return }
        guard let selected = lockKeyPopup.selectedItem else { return }

        settings.lockKeyCode = UInt16(selected.tag)
        settings.save()

        currentShortcutBadge.stringValue = settings.lockShortcutDisplay
        showSavedStatus()
        notifyAppState()
    }

    @objc private func chordKeysChanged() {
        guard let settings = appState?.shortcutSettings else { return }
        guard let item1 = chordKey1Popup.selectedItem, let item2 = chordKey2Popup.selectedItem else { return }

        let k1 = UInt16(item1.tag)
        var k2 = UInt16(item2.tag)

        // Safety check: both keys must be different
        if k1 == k2 {
            if k1 == KeycodeMap.kVK_ANSI_U {
                k2 = KeycodeMap.kVK_ANSI_K
                chordKey2Popup.selectItem(withTitle: "K")
            } else {
                k2 = KeycodeMap.kVK_ANSI_U
                chordKey2Popup.selectItem(withTitle: "U")
            }
        }

        settings.chordKey1 = k1
        settings.chordKey2 = k2
        settings.save()

        updateChordPreview()
        showSavedStatus()
        notifyAppState()
    }

    @objc private func chordDurationChanged() {
        guard let settings = appState?.shortcutSettings else { return }
        guard let dur = chordDurationPopup.selectedItem?.representedObject as? Double else { return }

        settings.chordDuration = dur
        settings.save()

        updateChordPreview()
        showSavedStatus()
        notifyAppState()
    }

    @objc private func passphraseChanged() {
        guard let settings = appState?.shortcutSettings else { return }
        let text = passphraseField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if text.count >= 2 {
            settings.passphrase = text
            settings.save()
            showSavedStatus()
            notifyAppState()
        }
    }

    @objc private func autoUnlockPopupChanged() {
        guard let state = appState, let selected = autoUnlockPopup.selectedItem else { return }
        state.autoUnlockMinutes = selected.tag
        let name = selected.title
        showSavedStatus("✓ Auto-unlock: \(name)")
    }

    @objc private func playModePopupChanged() {
        guard let state = appState, let selected = playModePopup.selectedItem,
              let mode = KeyBehaviorMode(rawValue: selected.tag) else { return }
        state.playMode = mode
        showSavedStatus("✓ Play Mode: \(mode.displayName)")
    }

    @objc private func resetDefaults() {
        guard let state = appState else { return }
        state.shortcutSettings.resetToDefaults()
        state.autoUnlockMinutes = 0  // Never by default
        state.playMode = .letters    // Phonics A-Z by default
        state.quietAfterMinutes = 0  // Disabled by default
        updateUIFromSettings()
        showSavedStatus("✓ Reset to defaults (Never timeout, Phonics A-Z, ⌘⌃L)")
        notifyAppState()
    }

    @objc private func closeWindow() {
        stopRecording()
        passphraseChanged()
        window?.orderOut(nil)
    }

    private func notifyAppState() {
        appState?.notifyShortcutsChanged()
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        stopRecording()
        passphraseChanged()
    }
}
