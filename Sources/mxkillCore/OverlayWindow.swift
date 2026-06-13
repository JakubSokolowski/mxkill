import AppKit
import Foundation

public final class OverlayWindow {
    private let window: NSWindow

    public init(
        contentRect: CGRect,
        contentView: NSView,
        level: NSWindow.Level,
        collectionBehavior: NSWindow.CollectionBehavior
    ) {
        window = NSWindow(
            contentRect: contentRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.level = level
        window.collectionBehavior = collectionBehavior
        window.contentView = contentView
        window.setAccessibilityElement(false)
    }

    public func show(frame: CGRect) {
        window.setFrame(frame, display: true)
        window.orderFrontRegardless()
    }

    public func hide() {
        window.orderOut(nil)
    }
}
