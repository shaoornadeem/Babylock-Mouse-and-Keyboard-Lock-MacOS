// SystemGuard.swift — Sleep prevention & crash recovery
// Prevents display sleep and persists lock state for crash recovery

import Foundation
import IOKit.pwr_mgt

class SystemGuard {

    private let appState: AppState
    private var displaySleepAssertionID: IOPMAssertionID = 0
    private var assertionActive = false
    private let recoveryFilePath: String

    init(appState: AppState) {
        self.appState = appState

        // Recovery file in Application Support
        let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let babylockDir = appSupportDir.appendingPathComponent("BabyLock", isDirectory: true)
        try? FileManager.default.createDirectory(at: babylockDir, withIntermediateDirectories: true)
        recoveryFilePath = babylockDir.appendingPathComponent("recovery.json").path

        // Check for crash recovery on init
        checkCrashRecovery()
    }

    // MARK: - Display Sleep Prevention

    func preventDisplaySleep() {
        guard !assertionActive else { return }

        let reason = "BabyLock is active — preventing display sleep for baby play mode" as CFString
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason,
            &displaySleepAssertionID
        )

        if result == kIOReturnSuccess {
            assertionActive = true
            print("☀️ BabyLock: Display sleep prevention enabled")
        } else {
            print("⚠️ BabyLock: Failed to prevent display sleep (code: \(result))")
        }
    }

    func allowDisplaySleep() {
        guard assertionActive else { return }

        let result = IOPMAssertionRelease(displaySleepAssertionID)
        if result == kIOReturnSuccess {
            assertionActive = false
            displaySleepAssertionID = 0
            print("😴 BabyLock: Display sleep prevention released")
        }
    }

    // MARK: - Crash Recovery

    func saveRecoveryState() {
        let state: [String: Any] = [
            "locked": true,
            "timestamp": Date().timeIntervalSince1970,
            "mode": appState.mode.rawValue,
            "autoUnlockMinutes": appState.autoUnlockMinutes,
        ]

        if let data = try? JSONSerialization.data(withJSONObject: state, options: .prettyPrinted) {
            try? data.write(to: URL(fileURLWithPath: recoveryFilePath))
        }
    }

    func clearRecoveryState() {
        try? FileManager.default.removeItem(atPath: recoveryFilePath)
    }

    private func checkCrashRecovery() {
        guard FileManager.default.fileExists(atPath: recoveryFilePath) else { return }

        // Previous crash detected — clean up
        print("⚠️ BabyLock: Crash recovery detected — cleaning up previous session")
        clearRecoveryState()

        // Re-enable global hotkeys in case they were left disabled
        let conn = CGSMainConnectionID()
        let _ = CGSSetGlobalHotKeyOperatingMode(conn, 0)
    }
}
