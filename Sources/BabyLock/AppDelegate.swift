// AppDelegate.swift — Application delegate & component wiring
// Initializes all subsystems and manages application lifecycle

import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {

    var appState: AppState!
    var audioEngine: BabyLockAudioEngine!
    var overlayManager: OverlayManager!
    var playEngine: PlayEngine!
    var inputTapManager: InputTapManager!
    var systemGuard: SystemGuard!
    var watchdog: Watchdog!
    var menuBarController: MenuBarController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🍼 BabyLock for macOS — Starting up...")

        // 1. Initialize core state
        appState = AppState()

        // 2. Initialize audio engine (lazy — starts only when locked)
        audioEngine = BabyLockAudioEngine()

        // 3. Initialize overlay manager
        overlayManager = OverlayManager(appState: appState)

        // 4. Initialize play engine
        playEngine = PlayEngine(
            appState: appState,
            audioEngine: audioEngine,
            overlayManager: overlayManager
        )

        // 5. Initialize input tap manager
        inputTapManager = InputTapManager(
            appState: appState,
            playEngine: playEngine,
            overlayManager: overlayManager
        )

        // 6. Initialize system guard
        systemGuard = SystemGuard(appState: appState)

        // 7. Initialize watchdog
        watchdog = Watchdog(
            appState: appState,
            inputTapManager: inputTapManager
        )

        // 8. Initialize menu bar controller (connects everything)
        menuBarController = MenuBarController(
            appState: appState,
            inputTapManager: inputTapManager,
            audioEngine: audioEngine,
            overlayManager: overlayManager,
            playEngine: playEngine,
            systemGuard: systemGuard,
            watchdog: watchdog
        )

        // 9. Start input tap & check accessibility permission on launch
        if InputTapManager.isAccessibilityGranted() {
            print("✅ BabyLock: Accessibility permission granted — starting tap")
            inputTapManager.startTap()
        } else {
            print("⚠️ BabyLock: Accessibility permission not yet granted")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.showWelcomeDialog()
            }
        }

        print("✅ BabyLock: All systems ready. Press \(appState.shortcutSettings.lockShortcutDisplay) or click 🔓 in the menu bar to lock.")
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if appState.isLocked {
            print("🚫 BabyLock: Quit blocked — currently locked")
            return .terminateCancel
        }

        // Clean up
        inputTapManager.disable()
        audioEngine.stop()
        systemGuard.allowDisplaySleep()
        systemGuard.clearRecoveryState()
        watchdog.stop()

        return .terminateNow
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Final cleanup
        inputTapManager.disable()
        systemGuard.allowDisplaySleep()
    }

    // MARK: - Welcome Dialog

    private func showWelcomeDialog() {
        let alert = NSAlert()
        alert.messageText = "Welcome to BabyLock! 🍼"
        alert.informativeText = """
        BabyLock is a keyboard & mouse lock for macOS that transforms your computer into a safe, interactive sensory playground for toddlers.

        🔒 Lock: Click the menu bar icon → Lock Now (\(appState.shortcutSettings.lockShortcutDisplay))
        🔓 Unlock: Hold \(appState.shortcutSettings.chordKey1Name)+\(appState.shortcutSettings.chordKey2Name) for \(appState.shortcutSettings.chordDurationDisplay), or type "\(appState.shortcutSettings.passphrase)"
        ⌨️ Shortcuts: Fully customizable in Menu Bar → ⌨️ Keyboard Shortcuts... (⌘,)

        ⚠️ IMPORTANT: BabyLock needs Accessibility permission to intercept input. Please grant access now.

        Features:
        • Phonics mode (A-Z) with speech
        • Musical scale mode (pentatonic)
        • Drawing mode with rainbow trails
        • Auto-unlock timer (5/15/30 min)
        • -12 dBFS hearing protection
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Grant Accessibility Permission")
        alert.addButton(withTitle: "Later")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let _ = InputTapManager.checkAccessibilityPermission()
        }
    }
}
