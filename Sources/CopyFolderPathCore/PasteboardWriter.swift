import AppKit

public enum PasteboardWriteError: Error, Equatable {
    case rejected
}

public protocol PasteboardWriting: AnyObject {
    func writeString(_ string: String) throws
}

public final class SystemPasteboardWriter: PasteboardWriting {
    private let pasteboard: NSPasteboard

    public init(pasteboard: NSPasteboard = .general) {
        self.pasteboard = pasteboard
    }

    public func writeString(_ string: String) throws {
        pasteboard.clearContents()

        guard pasteboard.setString(string, forType: .string) else {
            throw PasteboardWriteError.rejected
        }
    }
}
