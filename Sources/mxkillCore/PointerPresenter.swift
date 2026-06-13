import AppKit
import Foundation

public final class PointerPresenter {
    private let highlightOverlay: HighlightOverlay
    private let cursorOverlay: CursorOverlay
    private let highlightThrottleInterval: TimeInterval
    private var lastHighlightUpdate: Date?
    private var systemCursorHidden = false

    public init(
        highlightOverlay: HighlightOverlay = HighlightOverlay(),
        cursorOverlay: CursorOverlay = CursorOverlay(),
        highlightThrottleInterval: TimeInterval = 0.05
    ) {
        self.highlightOverlay = highlightOverlay
        self.cursorOverlay = cursorOverlay
        self.highlightThrottleInterval = highlightThrottleInterval
    }

    public func start(at point: CGPoint) {
        hideSystemCursor()
        cursorOverlay.show(at: point)
        lastHighlightUpdate = nil
    }

    public func update(at point: CGPoint) {
        cursorOverlay.show(at: point)

        let now = Date()
        if let lastHighlightUpdate,
           now.timeIntervalSince(lastHighlightUpdate) < highlightThrottleInterval {
            return
        }

        lastHighlightUpdate = now

        guard let target = AccessibilityHoverHitTester.hoverTarget(at: point) else {
            highlightOverlay.hide()
            return
        }

        highlightOverlay.show(frame: target.frame)
    }

    public func stop() {
        highlightOverlay.hide()
        cursorOverlay.hide()
        lastHighlightUpdate = nil
        showSystemCursor()
    }

    private func hideSystemCursor() {
        guard !systemCursorHidden else {
            return
        }

        CGDisplayHideCursor(CGMainDisplayID())
        systemCursorHidden = true
    }

    private func showSystemCursor() {
        guard systemCursorHidden else {
            return
        }

        CGDisplayShowCursor(CGMainDisplayID())
        systemCursorHidden = false
    }
}
