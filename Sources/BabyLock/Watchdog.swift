// Watchdog.swift — Anti-hang thread
// Monitors main thread responsiveness and auto-unlocks if the app hangs

import Foundation

class Watchdog {

    private let appState: AppState
    private let inputTapManager: InputTapManager
    private var timer: DispatchSourceTimer?
    private var lastKnownHeartbeat: UInt64 = 0
    private var missedChecks = 0
    private let maxMissedChecks = 3  // 3 × 10s = 30s
    private let checkInterval: TimeInterval = 10.0

    init(appState: AppState, inputTapManager: InputTapManager) {
        self.appState = appState
        self.inputTapManager = inputTapManager
    }

    func start() {
        guard timer == nil else { return }

        appState.bumpHeartbeat()
        lastKnownHeartbeat = appState.heartbeat
        missedChecks = 0

        let source = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .utility))
        source.schedule(deadline: .now() + checkInterval, repeating: checkInterval)
        source.setEventHandler { [weak self] in
            self?.check()
        }
        source.resume()
        timer = source
    }

    func stop() {
        timer?.cancel()
        timer = nil
        missedChecks = 0
    }

    private func check() {
        guard appState.isLocked else {
            missedChecks = 0
            lastKnownHeartbeat = appState.heartbeat
            return
        }

        let currentHeartbeat = appState.heartbeat

        // Active ping to main thread: if main thread is alive, it will bump heartbeat
        DispatchQueue.main.async { [weak self] in
            self?.appState.bumpHeartbeat()
        }

        if currentHeartbeat == lastKnownHeartbeat {
            // Main thread has not processed the previous ping (actual hang)
            missedChecks += 1
            print("⚠️ BabyLock Watchdog: Main thread unresponsive (\(missedChecks)/\(maxMissedChecks))")

            if missedChecks >= maxMissedChecks {
                print("🚨 BabyLock Watchdog: Emergency unlock — main thread hung for >\(Int(checkInterval) * maxMissedChecks)s!")
                DispatchQueue.main.async { [weak self] in
                    self?.inputTapManager.triggerUnlock()
                }
                missedChecks = 0
            }
        } else {
            missedChecks = 0
            lastKnownHeartbeat = currentHeartbeat
        }
    }
}
