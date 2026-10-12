// GlobalHotKeyManager.swift — System-wide OS-level hotkey manager using Carbon
// Intercepts Command+Option+L and Control+Option+L globally across ALL macOS applications

import Foundation
import Carbon

class GlobalHotKeyManager {

    static let shared = GlobalHotKeyManager()

    private var hotKeyRefs: [EventHotKeyRef] = []
    private var eventHandlerRef: EventHandlerRef?
    var onHotKeyPressed: (() -> Void)?

    init() {}

    func registerAll() {
        register(settings: ShortcutSettings.load())
    }

    func register(settings: ShortcutSettings) {
        unregisterAll()

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let handler: EventHandlerUPP = { _, event, userData -> OSStatus in
            guard let event = event, let userData = userData else {
                return OSStatus(eventNotHandledErr)
            }

            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )

            if status == noErr && hotKeyID.signature == OSType(0x42414259) { // "BABY"
                let manager = Unmanaged<GlobalHotKeyManager>.fromOpaque(userData).takeUnretainedValue()
                DispatchQueue.main.async {
                    manager.onHotKeyPressed?()
                }
                return noErr
            }
            return OSStatus(eventNotHandledErr)
        }

        let refcon = Unmanaged.passUnretained(self).toOpaque()
        let installStatus = InstallEventHandler(
            GetEventDispatcherTarget(),
            handler,
            1,
            &eventType,
            refcon,
            &eventHandlerRef
        )

        guard installStatus == noErr else {
            print("⚠️ BabyLock: Failed to install Carbon event handler (\(installStatus))")
            return
        }

        // Primary user-configured hotkey (id 1)
        registerSingleHotKey(
            id: 1,
            keyCode: UInt32(settings.lockKeyCode),
            carbonModifiers: settings.lockCarbonModifiers
        )

        // Safety failsafe 1: ⌘⌥L (Cmd + Option + L) if not already primary
        let cmdOptMods = UInt32(cmdKey | optionKey)
        if !(settings.lockKeyCode == UInt16(kVK_ANSI_L) && settings.lockCarbonModifiers == cmdOptMods) {
            registerSingleHotKey(id: 2, keyCode: UInt32(kVK_ANSI_L), carbonModifiers: cmdOptMods)
        }

        // Safety failsafe 2: ⌘⌃L (Cmd + Ctrl + L) if not already primary
        let cmdCtrlMods = UInt32(cmdKey | controlKey)
        if !(settings.lockKeyCode == UInt16(kVK_ANSI_L) && settings.lockCarbonModifiers == cmdCtrlMods) {
            registerSingleHotKey(id: 3, keyCode: UInt32(kVK_ANSI_L), carbonModifiers: cmdCtrlMods)
        }

        print("✅ BabyLock: Registered system-wide Carbon hotkey: \(settings.lockShortcutDisplay)")
    }

    private func registerSingleHotKey(id: UInt32, keyCode: UInt32, carbonModifiers: UInt32) {
        var hotKeyRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: OSType(0x42414259), id: id) // "BABY", id
        let status = RegisterEventHotKey(
            keyCode,
            carbonModifiers,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )

        if status == noErr, let ref = hotKeyRef {
            hotKeyRefs.append(ref)
        } else {
            print("⚠️ BabyLock: Failed to register hotkey id \(id) (\(status))")
        }
    }

    func unregisterAll() {
        for ref in hotKeyRefs {
            UnregisterEventHotKey(ref)
        }
        hotKeyRefs.removeAll()

        if let handler = eventHandlerRef {
            RemoveEventHandler(handler)
            eventHandlerRef = nil
        }
    }

    deinit {
        unregisterAll()
    }
}
