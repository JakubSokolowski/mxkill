import AppKit
import Foundation

public final class CursorOverlay {
    private let window: OverlayWindow
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

        window = OverlayWindow(
            contentRect: CGRect(origin: .zero, size: size),
            contentView: imageView,
            level: .screenSaver,
            collectionBehavior: [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        )
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
        window.show(frame: Self.frame(forPointerLocation: point, size: size, hotSpot: hotSpot))
    }

    public func hide() {
        window.hide()
    }
}
