import AppKit
import Foundation

public enum DestructiveCursor {
    public static let defaultSize = CGSize(width: 44, height: 44)

    public static func hotSpot(for size: CGSize) -> CGPoint {
        CGPoint(x: size.width - 20, y: 14)
    }

    public static func make(size: CGSize = defaultSize) -> NSCursor {
        NSCursor(image: image(size: size), hotSpot: hotSpot(for: size))
    }

    public static func image(size: CGSize = defaultSize) -> NSImage {
        let image = NSImage(size: size)

        image.lockFocus()
        drawSkullEmoji(in: CGRect(x: 2, y: size.height - 32, width: 30, height: 30))
        image.unlockFocus()

        return image
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
