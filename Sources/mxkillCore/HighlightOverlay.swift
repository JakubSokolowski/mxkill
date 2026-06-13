import AppKit
import Foundation

public final class HighlightOverlay {
    private let window: OverlayWindow
    private let borderView: NSView

    public init() {
        borderView = NSView(frame: .zero)
        borderView.wantsLayer = true
        borderView.autoresizingMask = [.width, .height]
        borderView.setAccessibilityElement(false)
        borderView.layer?.borderColor = NSColor.systemRed.cgColor
        borderView.layer?.borderWidth = 4
        borderView.layer?.backgroundColor = NSColor.clear.cgColor

        window = OverlayWindow(
            contentRect: .zero,
            contentView: borderView,
            level: .floating,
            collectionBehavior: [.canJoinAllSpaces, .fullScreenAuxiliary]
        )
    }

    public func show(frame: CGRect) {
        window.show(frame: frame)
    }

    public func hide() {
        window.hide()
    }
}
