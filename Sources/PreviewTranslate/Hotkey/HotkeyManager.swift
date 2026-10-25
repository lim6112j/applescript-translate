import AppKit
import Carbon.HIToolbox

/// Registers a system-wide shortcut. Carbon's RegisterEventHotKey is used instead of
/// an NSEvent monitor because it does not require Accessibility access to receive keys.
final class HotkeyManager {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private let handler: () -> Void
    private let hotKeyID = EventHotKeyID(signature: OSType(0x50545256), id: 1) // "PTRV"

    var shortcutDescription: String { "⌥⌘T" }

    init(handler: @escaping () -> Void) {
        self.handler = handler
    }

    func register() {
        unregister()

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let userData = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData -> OSStatus in
                guard let userData else { return OSStatus(eventNotHandledErr) }
                let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                manager.handle(event)
                return noErr
            },
            1,
            &eventType,
            userData,
            &eventHandlerRef
        )

        let modifiers = UInt32(optionKey | cmdKey)
        RegisterEventHotKey(
            UInt32(kVK_ANSI_T),
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
            self.eventHandlerRef = nil
        }
    }

    private func handle(_ event: EventRef?) {
        guard let event else { return }
        var eventID = EventHotKeyID()
        let status = GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &eventID
        )
        guard status == noErr, eventID.signature == hotKeyID.signature else { return }
        DispatchQueue.main.async { [handler] in handler() }
    }

    deinit {
        unregister()
    }
}
