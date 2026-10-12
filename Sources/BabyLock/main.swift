// main.swift — BabyLock for macOS entry point
// Menu bar agent app (no dock icon, no main window)

import AppKit

// Set as accessory app (no dock icon)
NSApplication.shared.setActivationPolicy(.accessory)

// Create and set the delegate
let delegate = AppDelegate()
NSApplication.shared.delegate = delegate

// Run the application
NSApplication.shared.run()
