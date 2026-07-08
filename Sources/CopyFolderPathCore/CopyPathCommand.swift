import Foundation

public enum ToastKind: Equatable {
    case copied(pathCount: Int)
    case noSelection
    case permissionDenied
    case failed(String)
}

public enum CopyPathResult: Equatable {
    case copied(paths: [String])
    case noSelection
    case permissionDenied(String)
    case failed(String)
}

public protocol ToastPresenting: AnyObject {
    func show(_ kind: ToastKind)
}

public protocol CopyPathRunning: AnyObject {
    @discardableResult
    func run() -> CopyPathResult
}

public final class CopyPathCommand: CopyPathRunning {
    private let selectionProvider: FinderSelectionProviding
    private let normalizer: PathNormalizer
    private let pasteboardWriter: PasteboardWriting
    private let toastPresenter: ToastPresenting

    public init(
        selectionProvider: FinderSelectionProviding,
        normalizer: PathNormalizer = PathNormalizer(),
        pasteboardWriter: PasteboardWriting,
        toastPresenter: ToastPresenting
    ) {
        self.selectionProvider = selectionProvider
        self.normalizer = normalizer
        self.pasteboardWriter = pasteboardWriter
        self.toastPresenter = toastPresenter
    }

    @discardableResult
    public func run() -> CopyPathResult {
        do {
            let urls = try selectionProvider.selectedFileURLs()
            guard !urls.isEmpty else {
                toastPresenter.show(.noSelection)
                return .noSelection
            }

            let paths = try normalizer.displayPaths(for: urls)
            try pasteboardWriter.writeString(paths.joined(separator: "\n"))
            toastPresenter.show(.copied(pathCount: paths.count))
            return .copied(paths: paths)
        } catch let error as FinderSelectionError {
            return handleFinderSelectionError(error)
        } catch {
            let message = String(describing: error)
            toastPresenter.show(.failed(message))
            return .failed(message)
        }
    }

    private func handleFinderSelectionError(_ error: FinderSelectionError) -> CopyPathResult {
        switch error {
        case .automationDenied(let message):
            toastPresenter.show(.permissionDenied)
            return .permissionDenied(message)
        default:
            let message = error.description
            toastPresenter.show(.failed(message))
            return .failed(message)
        }
    }
}
