import AppKit
import Foundation

public final class CursorOverlay {
    private let window: NSWindow
    private let size: CGSize
    private let hotSpot: CGPoint

    public init(
        image: NSImage = DestructiveCursor.image(),
        size: CGSize = DestructiveCursor.defaultSize,
        hotSpot: CGPoint = DestructiveCursor.hotSpot(for: DestructiveCursor.defaultSize)
    ) {
        self.size = size
        self.hotSpot = hotSpot

        let imageView = NSImageView(frame: CGRect(origin: .zero, size: size))
        imageView.image = image
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.setAccessibilityElement(false)

        window = NSWindow(
            contentRect: CGRect(origin: .zero, size: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        window.contentView = imageView
        window.setAccessibilityElement(false)
    }

    public static func frame(forPointerLocation point: CGPoint, size: CGSize, hotSpot: CGPoint) -> CGRect {
        CGRect(
            x: point.x - hotSpot.x,
            y: point.y - hotSpot.y,
            width: size.width,
            height: size.height
        )
    }

    public func show(at point: CGPoint) {
        window.setFrame(Self.frame(forPointerLocation: point, size: size, hotSpot: hotSpot), display: true)
        window.orderFrontRegardless()
    }

    public func hide() {
        window.orderOut(nil)
    }
}
