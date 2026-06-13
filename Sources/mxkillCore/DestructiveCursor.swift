import AppKit
import Foundation

public enum DestructiveCursor {
    public static let defaultSize = CGSize(width: 44, height: 44)

    public static func hotSpot(for size: CGSize) -> CGPoint {
        CGPoint(x: size.width - 8, y: 8)
    }

    public static func make(size: CGSize = defaultSize) -> NSCursor {
        NSCursor(image: image(size: size), hotSpot: hotSpot(for: size))
    }

    public static func image(size: CGSize = defaultSize) -> NSImage {
        let image = NSImage(size: size)

        image.lockFocus()
        let hotSpot = hotSpot(for: size)
        drawCrosshair(at: hotSpot, in: CGRect(origin: .zero, size: size))
        drawSkullEmoji(in: CGRect(x: 1, y: size.height - 31, width: 30, height: 30))
        image.unlockFocus()

        return image
    }

    private static func drawCrosshair(at point: CGPoint, in rect: CGRect) {
        NSColor.systemRed.setStroke()
        let crosshair = NSBezierPath()
        crosshair.lineWidth = 2
        crosshair.move(to: CGPoint(x: point.x, y: max(rect.minY + 1, point.y - 8)))
        crosshair.line(to: CGPoint(x: point.x, y: min(rect.maxY - 1, point.y + 8)))
        crosshair.move(to: CGPoint(x: max(rect.minX + 1, point.x - 8), y: point.y))
        crosshair.line(to: CGPoint(x: min(rect.maxX - 1, point.x + 8), y: point.y))
        crosshair.stroke()
    }

    private static func drawSkullEmoji(in rect: CGRect) {
        let font = NSFont(name: "Apple Color Emoji", size: 25) ?? NSFont.systemFont(ofSize: 25)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraph
        ]

        ("💀" as NSString).draw(in: rect, withAttributes: attributes)
    }
}
