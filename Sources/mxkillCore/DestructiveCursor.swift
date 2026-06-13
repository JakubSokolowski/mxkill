import AppKit
import Foundation

public enum DestructiveCursor {
    public static let defaultSize = CGSize(width: 32, height: 32)

    public static func hotSpot(for size: CGSize) -> CGPoint {
        CGPoint(x: size.width / 2, y: size.height / 2)
    }

    public static func make(size: CGSize = defaultSize) -> NSCursor {
        let image = NSImage(size: size)

        image.lockFocus()
        drawCrosshair(in: CGRect(origin: .zero, size: size))
        drawSkull(in: CGRect(x: 8, y: 7, width: 16, height: 18))
        image.unlockFocus()

        return NSCursor(image: image, hotSpot: hotSpot(for: size))
    }

    private static func drawCrosshair(in rect: CGRect) {
        let center = CGPoint(x: rect.midX, y: rect.midY)

        NSColor.systemRed.setStroke()
        let crosshair = NSBezierPath()
        crosshair.lineWidth = 2
        crosshair.move(to: CGPoint(x: center.x, y: rect.minY + 1))
        crosshair.line(to: CGPoint(x: center.x, y: rect.maxY - 1))
        crosshair.move(to: CGPoint(x: rect.minX + 1, y: center.y))
        crosshair.line(to: CGPoint(x: rect.maxX - 1, y: center.y))
        crosshair.stroke()
    }

    private static func drawSkull(in rect: CGRect) {
        let skull = NSBezierPath(ovalIn: CGRect(
            x: rect.minX + 2,
            y: rect.minY + 5,
            width: rect.width - 4,
            height: rect.height - 3
        ))

        NSColor.white.setFill()
        skull.fill()
        NSColor.black.setStroke()
        skull.lineWidth = 1.25
        skull.stroke()

        NSColor.black.setFill()
        NSBezierPath(ovalIn: CGRect(x: rect.minX + 5, y: rect.minY + 12, width: 3.5, height: 4)).fill()
        NSBezierPath(ovalIn: CGRect(x: rect.maxX - 8.5, y: rect.minY + 12, width: 3.5, height: 4)).fill()

        let nose = NSBezierPath()
        nose.move(to: CGPoint(x: rect.midX, y: rect.minY + 11))
        nose.line(to: CGPoint(x: rect.midX - 2, y: rect.minY + 7))
        nose.line(to: CGPoint(x: rect.midX + 2, y: rect.minY + 7))
        nose.close()
        nose.fill()

        let jaw = NSBezierPath(rect: CGRect(x: rect.minX + 5, y: rect.minY + 3, width: rect.width - 10, height: 5))
        NSColor.white.setFill()
        jaw.fill()
        NSColor.black.setStroke()
        jaw.lineWidth = 1.25
        jaw.stroke()

        let teeth = NSBezierPath()
        teeth.lineWidth = 1
        teeth.move(to: CGPoint(x: rect.midX, y: rect.minY + 3))
        teeth.line(to: CGPoint(x: rect.midX, y: rect.minY + 8))
        teeth.move(to: CGPoint(x: rect.midX - 3, y: rect.minY + 3.5))
        teeth.line(to: CGPoint(x: rect.midX - 3, y: rect.minY + 7.5))
        teeth.move(to: CGPoint(x: rect.midX + 3, y: rect.minY + 3.5))
        teeth.line(to: CGPoint(x: rect.midX + 3, y: rect.minY + 7.5))
        teeth.stroke()
    }
}
