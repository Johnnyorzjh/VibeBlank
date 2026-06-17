import Carbon.HIToolbox
import Foundation

final class HotKeyController {
    var onPressed: (() -> Void)?
    private(set) var lastRegistrationError: OSStatus?

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private let hotKeyID = EventHotKeyID(signature: 0x56424C4B, id: 1)

    deinit {
        unregister()
    }

    @discardableResult
    func update(isEnabled: Bool) -> Bool {
        if isEnabled {
            return register()
        } else {
            unregister()
            return true
        }
    }

    private func register() -> Bool {
        guard hotKeyRef == nil else {
            lastRegistrationError = nil
            return true
        }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed)
        )

        let userData = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        let installStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, userData in
                guard let userData else {
                    return noErr
                }

                let controller = Unmanaged<HotKeyController>
                    .fromOpaque(userData)
                    .takeUnretainedValue()

                Task { @MainActor in
                    controller.onPressed?()
                }

                return noErr
            },
            1,
            &eventType,
            userData,
            &eventHandlerRef
        )

        guard installStatus == noErr else {
            lastRegistrationError = installStatus
            return false
        }

        var registeredHotKey: EventHotKeyRef?
        let registerStatus = RegisterEventHotKey(
            UInt32(kVK_ANSI_B),
            UInt32(controlKey | optionKey | cmdKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &registeredHotKey
        )

        if registerStatus == noErr {
            hotKeyRef = registeredHotKey
            lastRegistrationError = nil
            return true
        } else {
            if let eventHandlerRef {
                RemoveEventHandler(eventHandlerRef)
                self.eventHandlerRef = nil
            }
            lastRegistrationError = registerStatus
            return false
        }
    }

    private func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }

        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
            self.eventHandlerRef = nil
        }
    }
}
