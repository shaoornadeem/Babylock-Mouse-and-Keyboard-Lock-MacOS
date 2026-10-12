// MenuBarController.swift — macOS Menu Bar Status Item
// Primary user interface for controlling settings, modes, and locking

import AppKit

class MenuBarController: NSObject {

    private var statusItem: NSStatusItem!
    private let appState: AppState
    private let inputTapManager: InputTapManager
    private let audioEngine: BabyLockAudioEngine
    private let overlayManager: OverlayManager
    private let playEngine: PlayEngine
    private let systemGuard: SystemGuard
    private let watchdog: Watchdog

    // Menu items that need dynamic updates
    private var lockMenuItem: NSMenuItem!
    private var timerMenuItem: NSMenuItem?

    // Global hotkey monitors
    private var globalHotKeyMonitor: Any?
    private var localHotKeyMonitor: Any?

    init(appState: AppState,
         inputTapManager: InputTapManager,
         audioEngine: BabyLockAudioEngine,
         overlayManager: OverlayManager,
         playEngine: PlayEngine,
         systemGuard: SystemGuard,
         watchdog: Watchdog) {

        self.appState = appState
        self.inputTapManager = inputTapManager
        self.audioEngine = audioEngine
        self.overlayManager = overlayManager
        self.playEngine = playEngine
        self.systemGuard = systemGuard
        self.watchdog = watchdog

        super.init()

        setupStatusItem()
        setupTimerCallback()
        setupHotKeys()
        setupShortcutCallback()
    }

    // MARK: - Status Item Setup

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.title = "🔓"
            button.toolTip = "BabyLock — Keyboard & Mouse Lock (\(appState.shortcutSettings.lockShortcutDisplay))"
        }

        rebuildMenu()
    }

    private func rebuildMenu() {
        let menu = NSMenu()
        menu.autoenablesItems = false

        // --- Lock / Unlock ---
        lockMenuItem = NSMenuItem(
            title: appState.isLocked ? "🔓 Unlock Now" : "🔒 Lock Now",
            action: #selector(toggleLock),
            keyEquivalent: appState.shortcutSettings.menuKeyEquivalent
        )
        lockMenuItem.keyEquivalentModifierMask = appState.shortcutSettings.cocoaModifierFlags
        lockMenuItem.toolTip = "Shortcut: \(appState.shortcutSettings.lockShortcutDisplay)"
        lockMenuItem.target = self
        menu.addItem(lockMenuItem)

        menu.addItem(.separator())

        // --- Lock Mode ---
        let modeMenu = NSMenu()
        for mode in LockMode.allCases {
            let item = NSMenuItem(title: mode.displayName, action: #selector(setLockMode(_:)), keyEquivalent: "")
            item.target = self
            item.tag = mode.rawValue
            item.state = (appState.mode == mode) ? .on : .off
            modeMenu.addItem(item)
        }
        let modeItem = NSMenuItem(title: "🛡️ Lock Mode", action: nil, keyEquivalent: "")
        modeItem.submenu = modeMenu
        menu.addItem(modeItem)

        // --- Play Mode ---
        let playMenu = NSMenu()

        // Enable/Disable
        let enableItem = NSMenuItem(title: "Enabled", action: #selector(togglePlayEnabled), keyEquivalent: "")
        enableItem.target = self
        enableItem.state = appState.playEnabled ? .on : .off
        playMenu.addItem(enableItem)

        playMenu.addItem(.separator())

        // Theme
        let themeSubmenu = NSMenu()
        for theme in ThemeType.allCases {
            let item = NSMenuItem(title: theme.displayName, action: #selector(setTheme(_:)), keyEquivalent: "")
            item.target = self
            item.tag = theme.rawValue
            item.state = (appState.theme == theme) ? .on : .off
            themeSubmenu.addItem(item)
        }
        let themeItem = NSMenuItem(title: "Theme", action: nil, keyEquivalent: "")
        themeItem.submenu = themeSubmenu
        playMenu.addItem(themeItem)

        // Mode
        let behaviorSubmenu = NSMenu()
        for mode in KeyBehaviorMode.allCases {
            let item = NSMenuItem(title: mode.displayName, action: #selector(setPlayMode(_:)), keyEquivalent: "")
            item.target = self
            item.tag = mode.rawValue
            item.state = (appState.playMode == mode) ? .on : .off
            behaviorSubmenu.addItem(item)
        }
        let behaviorItem = NSMenuItem(title: "Mode", action: nil, keyEquivalent: "")
        behaviorItem.submenu = behaviorSubmenu
        playMenu.addItem(behaviorItem)

        // Voice
        let voiceSubmenu = NSMenu()
        for voice in VoiceSource.allCases {
            let item = NSMenuItem(title: voice.displayName, action: #selector(setVoice(_:)), keyEquivalent: "")
            item.target = self
            item.tag = voice.rawValue
            item.state = (appState.voiceSource == voice) ? .on : .off
            voiceSubmenu.addItem(item)
        }
        let voiceItem = NSMenuItem(title: "Voice", action: nil, keyEquivalent: "")
        voiceItem.submenu = voiceSubmenu
        playMenu.addItem(voiceItem)

        // Instrument
        let instrumentSubmenu = NSMenu()
        for inst in InstrumentType.allCases {
            let item = NSMenuItem(title: inst.displayName, action: #selector(setInstrument(_:)), keyEquivalent: "")
            item.target = self
            item.tag = inst.rawValue
            item.state = (appState.instrument == inst) ? .on : .off
            instrumentSubmenu.addItem(item)
        }
        let instrumentItem = NSMenuItem(title: "Instrument", action: nil, keyEquivalent: "")
        instrumentItem.submenu = instrumentSubmenu
        playMenu.addItem(instrumentItem)

        let playItem = NSMenuItem(title: "🎨 Play Mode", action: nil, keyEquivalent: "")
        playItem.submenu = playMenu
        menu.addItem(playItem)

        // --- Speech Speed ---
        let speedMenu = NSMenu()
        for speed in SpeechSpeed.allCases {
            let item = NSMenuItem(title: speed.displayName, action: #selector(setSpeechSpeed(_:)), keyEquivalent: "")
            item.target = self
            item.tag = speed.rawValue
            item.state = (appState.speechSpeed == speed) ? .on : .off
            speedMenu.addItem(item)
        }
        let speedItem = NSMenuItem(title: "🗣️ Speech Speed", action: nil, keyEquivalent: "")
        speedItem.submenu = speedMenu
        menu.addItem(speedItem)

        // --- Card Display Duration ---
        let durationMenu = NSMenu()
        for duration in CardDisplayDuration.allCases {
            let item = NSMenuItem(title: duration.displayName, action: #selector(setCardDuration(_:)), keyEquivalent: "")
            item.target = self
            item.tag = duration.rawValue
            item.state = (appState.cardDuration == duration) ? .on : .off
            durationMenu.addItem(item)
        }
        let durationItem = NSMenuItem(title: "⏱️ Display Duration", action: nil, keyEquivalent: "")
        durationItem.submenu = durationMenu
        menu.addItem(durationItem)

        // --- Volume ---
        let volumeMenu = NSMenu()
        for vol in VolumeLevel.allCases {
            let item = NSMenuItem(title: vol.displayName, action: #selector(setVolume(_:)), keyEquivalent: "")
            item.target = self
            item.tag = vol.rawValue
            item.state = (appState.volume == vol) ? .on : .off
            volumeMenu.addItem(item)
        }
        let volumeItem = NSMenuItem(title: "🔊 Volume", action: nil, keyEquivalent: "")
        volumeItem.submenu = volumeMenu
        menu.addItem(volumeItem)

        // --- Auto-Unlock Timer ---
        let timerMenu = NSMenu()
        for duration in AutoUnlockDuration.allCases {
            let item = NSMenuItem(title: duration.displayName, action: #selector(setAutoUnlock(_:)), keyEquivalent: "")
            item.target = self
            item.tag = duration.rawValue
            item.state = (appState.autoUnlockMinutes == duration.rawValue) ? .on : .off
            timerMenu.addItem(item)
        }
        let timerItem = NSMenuItem(title: "⏱️ Auto-Unlock Timer", action: nil, keyEquivalent: "")
        timerItem.submenu = timerMenu
        menu.addItem(timerItem)

        menu.addItem(.separator())

        // --- Launch at Login ---
        let loginItem = NSMenuItem(title: "⚙️ Launch at Login", action: #selector(toggleLaunchAtLogin(_:)), keyEquivalent: "")
        loginItem.target = self
        loginItem.state = isLaunchAtLoginEnabled() ? .on : .off
        menu.addItem(loginItem)

        // --- Keyboard Shortcuts / Settings ---
        let shortcutItem = NSMenuItem(title: "⌨️ Keyboard Shortcuts...", action: #selector(openShortcutSettings), keyEquivalent: ",")
        shortcutItem.keyEquivalentModifierMask = [.command]
        shortcutItem.target = self
        menu.addItem(shortcutItem)

        // --- About ---
        let aboutItem = NSMenuItem(title: "ℹ️ About BabyLock", action: #selector(showAboutDialog), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)

        menu.addItem(.separator())

        // --- Quit ---
        let quitItem = NSMenuItem(title: "❌ Quit BabyLock", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    // MARK: - Timer Callback

    private func setupTimerCallback() {
        appState.onTimerTick = { [weak self] remaining in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.overlayManager.updateHUD(
                    timeRemaining: self.appState.formattedTimeRemaining,
                    mode: self.appState.mode.displayName
                )
            }
        }

        appState.onLockStateChanged = { [weak self] isLocked in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.handleLockStateChange(isLocked: isLocked)
            }
        }
    }

    // MARK: - Lock State Management

    private func handleLockStateChange(isLocked: Bool) {
        if isLocked {
            // Engage lock
            statusItem.button?.title = "🔒"

            // Start audio engine
            audioEngine.start()
            audioEngine.setVolume(appState.volume)

            // Switch event tap to locked mode
            inputTapManager.setLockedState(true)

            // Show overlay
            overlayManager.show()
            overlayManager.updateHUD(
                timeRemaining: appState.formattedTimeRemaining,
                mode: appState.mode.displayName
            )

            // Activate drawing mode if selected
            playEngine.updateDrawingMode()

            // Prevent display sleep
            systemGuard.preventDisplaySleep()
            systemGuard.saveRecoveryState()

            // Start watchdog
            watchdog.start()

            // Reset play engine
            playEngine.reset()

        } else {
            // Disengage lock
            statusItem.button?.title = "🔓"

            // Switch event tap to unlocked mode (keeps pass-through listening for hotkey)
            inputTapManager.setLockedState(false)

            // Hide overlay
            overlayManager.hide()

            // Stop audio
            audioEngine.stop()

            // Allow display sleep
            systemGuard.allowDisplaySleep()
            systemGuard.clearRecoveryState()

            // Stop watchdog
            watchdog.stop()

            // Reset play engine
            playEngine.reset()
        }

        // Rebuild menu to update lock/unlock label
        rebuildMenu()
    }

    // MARK: - Actions

    private var lastToggleTime: Date = Date.distantPast

    @objc func toggleLock() {
        let now = Date()
        guard now.timeIntervalSince(lastToggleTime) > 0.4 else {
            return // Debounce rapid double-triggers
        }
        lastToggleTime = now

        if appState.isLocked {
            appState.disengage()
        } else {
            // Check accessibility before locking
            guard InputTapManager.isAccessibilityGranted() else {
                let _ = InputTapManager.checkAccessibilityPermission()
                showAccessibilityAlert()
                return
            }
            appState.engage()
        }
    }

    @objc private func setLockMode(_ sender: NSMenuItem) {
        guard let mode = LockMode(rawValue: sender.tag) else { return }
        appState.mode = mode
        rebuildMenu()
    }

    @objc private func togglePlayEnabled() {
        appState.playEnabled.toggle()
        rebuildMenu()
    }

    @objc private func setTheme(_ sender: NSMenuItem) {
        guard let theme = ThemeType(rawValue: sender.tag) else { return }
        appState.theme = theme
        rebuildMenu()
    }

    @objc private func setPlayMode(_ sender: NSMenuItem) {
        guard let mode = KeyBehaviorMode(rawValue: sender.tag) else { return }
        appState.playMode = mode
        playEngine.updateDrawingMode()
        rebuildMenu()
    }

    @objc private func setVoice(_ sender: NSMenuItem) {
        guard let voice = VoiceSource(rawValue: sender.tag) else { return }
        appState.voiceSource = voice
        rebuildMenu()
    }

    @objc private func setSpeechSpeed(_ sender: NSMenuItem) {
        guard let speed = SpeechSpeed(rawValue: sender.tag) else { return }
        appState.speechSpeed = speed
        rebuildMenu()
    }

    @objc private func setCardDuration(_ sender: NSMenuItem) {
        guard let duration = CardDisplayDuration(rawValue: sender.tag) else { return }
        appState.cardDuration = duration
        rebuildMenu()
    }

    @objc private func setInstrument(_ sender: NSMenuItem) {
        guard let inst = InstrumentType(rawValue: sender.tag) else { return }
        appState.instrument = inst
        rebuildMenu()
    }

    @objc private func setVolume(_ sender: NSMenuItem) {
        guard let vol = VolumeLevel(rawValue: sender.tag) else { return }
        appState.volume = vol
        audioEngine.setVolume(vol)
        rebuildMenu()
    }

    @objc private func setAutoUnlock(_ sender: NSMenuItem) {
        appState.autoUnlockMinutes = sender.tag
        rebuildMenu()
    }

    @objc private func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        // Basic launch-at-login toggle using SMAppService on macOS 13+
        if #available(macOS 13.0, *) {
            import_SMAppService_and_toggle()
        }
        rebuildMenu()
    }

    @objc private func quitApp() {
        if appState.isLocked {
            // Don't quit while locked
            return
        }
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Helpers

    @objc private func showAboutDialog() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "BabyLock for macOS 🍼"
            alert.informativeText = """
            Version 1.0.0 (Build 1)

            A zero-leak keyboard & mouse lock that transforms your Mac into a safe, educational sensory playground for toddlers.

            ✨ Features:
            • Zero-leak OS-level input lock (CGEvent tap & Carbon)
            • Failsafe unlocks (⌘⌥L, Hold U+K 3s, type "baby")
            • Phonics speech narration with speed control
            • 26-note pentatonic synthesizer (hearing-safe -12 dBFS)
            • Fullscreen rainbow trail drawing canvas

            👨‍💻 Developed by Shaoor
            Free & Open Source Software
            """
            alert.alertStyle = .informational
            if let iconPath = Bundle.main.path(forResource: "AppIcon", ofType: "icns"),
               let icon = NSImage(contentsOfFile: iconPath) {
                alert.icon = icon
            }
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }

    private func showAccessibilityAlert() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Accessibility Permission Required"
            alert.informativeText = """
            BabyLock needs Accessibility permission to intercept keyboard and mouse input.

            Please grant access in:
            System Settings → Privacy & Security → Accessibility

            Then try locking again.
            """
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Open System Settings")
            alert.addButton(withTitle: "Cancel")

            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                // Open System Settings → Privacy → Accessibility
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }

    private func isLaunchAtLoginEnabled() -> Bool {
        // Simplified check — in production, use SMAppService
        return false
    }

    private func import_SMAppService_and_toggle() {
        // SMAppService requires the app to be properly signed and have a login item helper
        // For now, provide instructions
        let alert = NSAlert()
        alert.messageText = "Launch at Login"
        alert.informativeText = """
        To enable launch at login:
        1. Open System Settings → General → Login Items
        2. Add BabyLock to the list

        (Automatic toggle requires the app to be code-signed.)
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    // MARK: - Shortcut Settings

    @objc func openShortcutSettings() {
        if appState.isLocked { return }
        SettingsWindowController.shared.show(with: appState)
    }

    private func setupShortcutCallback() {
        appState.onShortcutsChanged = { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                GlobalHotKeyManager.shared.register(settings: self.appState.shortcutSettings)
                self.inputTapManager.updateShortcutSettings()
                self.rebuildMenu()
                if self.appState.isLocked {
                    self.overlayManager.updateHUD(
                        timeRemaining: self.appState.formattedTimeRemaining,
                        mode: self.appState.mode.displayName
                    )
                }
            }
        }

        appState.onSettingsChanged = { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.rebuildMenu()
                if self.appState.isLocked {
                    self.overlayManager.updateHUD(
                        timeRemaining: self.appState.formattedTimeRemaining,
                        mode: self.appState.mode.displayName
                    )
                }
            }
        }
    }

    // MARK: - Global Hotkeys (across ALL apps)

    private func setupHotKeys() {
        // 1. Carbon Global HotKey Manager — OS-level interception across ANY active app
        GlobalHotKeyManager.shared.onHotKeyPressed = { [weak self] in
            print("🔑 BabyLock: Carbon global hotkey triggered!")
            self?.toggleLock()
        }
        GlobalHotKeyManager.shared.register(settings: appState.shortcutSettings)

        // 2. InputTapManager callback — CGEventTap interception across ANY active app
        inputTapManager.onLockRequested = { [weak self] in
            print("🔑 BabyLock: CGEventTap global hotkey triggered!")
            self?.toggleLock()
        }
        if InputTapManager.isAccessibilityGranted() {
            inputTapManager.startTap()
        }

        // 3. Fallback NSEvent monitor
        globalHotKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleNSEventHotKey(event: event)
        }
        localHotKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.handleNSEventHotKey(event: event) == true {
                return nil
            }
            return event
        }
    }

    @discardableResult
    private func handleNSEventHotKey(event: NSEvent) -> Bool {
        let isMatch = appState.shortcutSettings.matchesLockShortcut(keyCode: event.keyCode, nsFlags: event.modifierFlags) ||
                      appState.shortcutSettings.matchesFailsafeShortcut(keyCode: event.keyCode, nsFlags: event.modifierFlags)

        if isMatch {
            DispatchQueue.main.async { [weak self] in
                self?.toggleLock()
            }
            return true
        }
        return false
    }
}
