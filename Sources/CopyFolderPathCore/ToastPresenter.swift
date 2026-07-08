import AppKit

public final class AppKitToastPresenter: ToastPresenting {
    public enum Timing {
        public static let defaultVisibleDuration: TimeInterval = 0.58
        public static let previewVisibleDuration: TimeInterval = 3.0
    }

    private enum Layout {
        static let windowSize = NSSize(width: 268, height: 44)
        static let fadeOutDuration: TimeInterval = 0.13
        static let topInset: CGFloat = 72
    }

    private lazy var panel: ToastPanel = Self.makePanelForTesting()
    private var closeTimer: Timer?
    private let visibleDuration: TimeInterval

    public init(visibleDuration: TimeInterval = Timing.defaultVisibleDuration) {
        self.visibleDuration = visibleDuration
    }

    public func show(_ kind: ToastKind) {
        if Thread.isMainThread {
            showOnMain(kind)
            return
        }

        DispatchQueue.main.async {
            self.showOnMain(kind)
        }
    }

    public static func makePanelForTesting() -> ToastPanel {
        let panel = ToastPanel(
            contentRect: NSRect(origin: .zero, size: Layout.windowSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.isReleasedWhenClosed = false
        panel.ignoresMouseEvents = true
        panel.hidesOnDeactivate = false
        panel.level = .statusBar
        panel.collectionBehavior = [.transient, .ignoresCycle, .canJoinAllSpaces, .fullScreenAuxiliary]
        panel.animationBehavior = .none
        panel.contentView = ToastView(frame: NSRect(origin: .zero, size: Layout.windowSize))
        return panel
    }

    private func showOnMain(_ kind: ToastKind) {
        guard let toastView = panel.contentView as? ToastView else {
            return
        }

        toastView.message = message(for: kind)
        panel.setFrame(frame(for: NSScreen.main), display: true)
        panel.alphaValue = 1
        panel.displayIfNeeded()
        panel.orderFrontRegardless()

        closeTimer?.invalidate()

        closeTimer = Timer.scheduledTimer(withTimeInterval: visibleDuration, repeats: false) { [weak self] _ in
            self?.hide()
        }
    }

    private func hide() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = Layout.fadeOutDuration
            panel.animator().alphaValue = 0
        } completionHandler: {
            self.panel.orderOut(nil)
        }
    }

    private func frame(for screen: NSScreen?) -> NSRect {
        let visibleFrame = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let origin = NSPoint(
            x: visibleFrame.midX - (Layout.windowSize.width / 2),
            y: visibleFrame.maxY - Layout.topInset
        )
        return NSRect(origin: origin, size: Layout.windowSize)
    }

    private func message(for kind: ToastKind) -> String {
        switch kind {
        case .copied:
            return "Path copied"
        case .noSelection:
            return "Nothing selected"
        case .permissionDenied:
            return "Finder permission needed"
        case .failed:
            return "Copy failed"
        }
    }
}

public final class ToastPanel: NSPanel {
    public override var canBecomeKey: Bool { false }
    public override var canBecomeMain: Bool { false }
}

final class ToastView: NSView {
    var message = "Path copied" {
        didSet {
            needsDisplay = true
        }
    }

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let pillRect = NSRect(x: 4, y: 3, width: 260, height: 38)
        let pillPath = NSBezierPath(roundedRect: pillRect, xRadius: 19, yRadius: 19)
        NSColor(calibratedRed: 22 / 255, green: 24 / 255, blue: 29 / 255, alpha: 0.92).setFill()
        pillPath.fill()

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13, weight: .semibold),
            .foregroundColor: NSColor.white
        ]
        let textSize = (message as NSString).size(withAttributes: attributes)
        let iconWidth: CGFloat = 13
        let gap: CGFloat = 7
        let totalWidth = iconWidth + gap + textSize.width
        let startX = pillRect.midX - (totalWidth / 2)
        let centerY = pillRect.midY

        drawCheckmark(
            in: NSRect(x: startX, y: centerY - 6.5, width: iconWidth, height: iconWidth)
        )

        let textRect = NSRect(
            x: startX + iconWidth + gap,
            y: centerY - (textSize.height / 2),
            width: textSize.width,
            height: textSize.height
        )
        (message as NSString).draw(in: textRect, withAttributes: attributes)
    }

    private func drawCheckmark(in rect: NSRect) {
        let path = NSBezierPath()
        path.move(to: NSPoint(x: rect.minX + 2.5, y: rect.midY + 0.5))
        path.line(to: NSPoint(x: rect.minX + 5.5, y: rect.maxY - 3))
        path.line(to: NSPoint(x: rect.maxX - 2, y: rect.minY + 2.5))
        path.lineWidth = 2
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        NSColor(calibratedRed: 101 / 255, green: 217 / 255, blue: 117 / 255, alpha: 1).setStroke()
        path.stroke()
    }
}
