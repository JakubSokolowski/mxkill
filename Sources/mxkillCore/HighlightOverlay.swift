import AppKit
import Foundation

public final class HighlightOverlay {
    private let window: NSWindow
    private let borderView: NSView

    public init() {
        borderView = NSView(frame: .zero)
        borderView.wantsLayer = true
        borderView.autoresizingMask = [.width, .height]
        borderView.setAccessibilityElement(false)
        borderView.layer?.borderColor = NSColor.systemRed.cgColor
        borderView.layer?.borderWidth = 4
        borderView.layer?.backgroundColor = NSColor.clear.cgColor

        window = NSWindow(
            contentRect: .zero,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.setAccessibilityElement(false)
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.contentView = borderView
    }

    public func show(frame: CGRect) {
        window.setFrame(frame, display: true)
        window.orderFrontRegardless()
    }

    public func hide() {
        window.orderOut(nil)
    }
}
