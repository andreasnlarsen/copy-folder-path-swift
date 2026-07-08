import Foundation

public enum FinderSelectionError: Error, Equatable, CustomStringConvertible {
    case scriptUnavailable
    case automationDenied(message: String)
    case scriptFailed(message: String, number: Int?)
    case invalidReturnedURL(String)

    public var description: String {
        switch self {
        case .scriptUnavailable:
            return "Finder selection script could not be created."
        case .automationDenied(let message):
            return message
        case .scriptFailed(let message, _):
            return message
        case .invalidReturnedURL(let value):
            return "Finder returned an invalid URL: \(value)"
        }
    }
}

public protocol FinderSelectionProviding: AnyObject {
    func selectedFileURLs() throws -> [URL]
}

public final class AppleScriptFinderSelectionProvider: FinderSelectionProviding {
    private let script: NSAppleScript

    public init() throws {
        let source = """
        tell application "Finder"
          set selectedItems to selection
          set selectedURLs to {}
          repeat with selectedItem in selectedItems
            set end of selectedURLs to URL of selectedItem
          end repeat
          return selectedURLs
        end tell
        """

        guard let script = NSAppleScript(source: source) else {
            throw FinderSelectionError.scriptUnavailable
        }

        self.script = script
    }

    public func selectedFileURLs() throws -> [URL] {
        var errorInfo: NSDictionary?
        let result = script.executeAndReturnError(&errorInfo)

        if let errorInfo {
            throw Self.mapScriptError(errorInfo)
        }

        return try Self.strings(from: result).map { value in
            guard let url = URL(string: value) else {
                throw FinderSelectionError.invalidReturnedURL(value)
            }
            return url
        }
    }

    private static func strings(from descriptor: NSAppleEventDescriptor) -> [String] {
        if descriptor.numberOfItems > 0 {
            return (1...descriptor.numberOfItems).compactMap { index in
                descriptor.atIndex(index)?.stringValue
            }
        }

        if let value = descriptor.stringValue {
            return [value]
        }

        return []
    }

    private static func mapScriptError(_ errorInfo: NSDictionary) -> FinderSelectionError {
        let number = (errorInfo[NSAppleScript.errorNumber] as? NSNumber)?.intValue
        let message = (errorInfo[NSAppleScript.errorMessage] as? String)
            ?? "Finder selection script failed."

        switch number {
        case -1743, -1744:
            return .automationDenied(message: message)
        default:
            return .scriptFailed(message: message, number: number)
        }
    }
}
