import Carbon
import Foundation

public struct HotKeyRegistrationError: Error, Equatable {
    public let status: OSStatus

    public init(status: OSStatus) {
        self.status = status
    }
}

public protocol HotKeyRegistering: AnyObject {
    var isRegistered: Bool { get }
    func register(handler: @escaping () -> Void) throws
    func unregister()
}

public final class CarbonHotKeyRegistrar: HotKeyRegistering {
    private var eventHandlerRef: EventHandlerRef?
    private var hotKeyRef: EventHotKeyRef?
    private var handler: (() -> Void)?

    public var isRegistered: Bool {
        hotKeyRef != nil
    }

    public init() {
        installEventHandler()
    }

    deinit {
        unregister()

        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
        }
    }

    public func register(handler: @escaping () -> Void) throws {
        guard !isRegistered else {
            self.handler = handler
            return
        }

        self.handler = handler

        let hotKeyID = EventHotKeyID(signature: Self.fourCharCode("CFPH"), id: 1)
        var newHotKeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            UInt32(kVK_ANSI_C),
            UInt32(cmdKey | shiftKey),
            hotKeyID,
            GetEventDispatcherTarget(),
            UInt32(kEventHotKeyExclusive),
            &newHotKeyRef
        )

        guard status == noErr, let newHotKeyRef else {
            self.handler = nil
            throw HotKeyRegistrationError(status: status)
        }

        hotKeyRef = newHotKeyRef
    }

    public func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }

        hotKeyRef = nil
        handler = nil
    }

    private func installEventHandler() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetEventDispatcherTarget(),
            { _, _, userData in
                guard let userData else {
                    return noErr
                }

                let registrar = Unmanaged<CarbonHotKeyRegistrar>
                    .fromOpaque(userData)
                    .takeUnretainedValue()
                registrar.handler?()
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandlerRef
        )
    }

    private static func fourCharCode(_ string: String) -> OSType {
        precondition(string.utf8.count == 4)

        return string.utf8.reduce(0) { result, character in
            (result << 8) + OSType(character)
        }
    }
}
