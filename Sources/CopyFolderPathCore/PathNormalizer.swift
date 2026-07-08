import Foundation

public enum PathNormalizationError: Error, Equatable {
    case nonFileURL(String)
}

public struct PathNormalizer {
    public init() {}

    public func displayPath(for url: URL) throws -> String {
        guard url.isFileURL else {
            throw PathNormalizationError.nonFileURL(url.absoluteString)
        }

        var path = url.path
        if path != "/" && path.hasSuffix("/") {
            path.removeLast()
        }
        return path
    }

    public func displayPaths(for urls: [URL]) throws -> [String] {
        try urls.map(displayPath(for:))
    }
}
