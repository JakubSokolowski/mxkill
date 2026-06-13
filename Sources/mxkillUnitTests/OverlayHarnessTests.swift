import Foundation
import mxkillCore

func testDestructiveCursorHotSpotPlacesIconUpLeftOfPointer() {
    expectEqual(DestructiveCursor.defaultSize, CGSize(width: 44, height: 44), "destructive cursor default size")
    expectEqual(DestructiveCursor.hotSpot(for: DestructiveCursor.defaultSize), CGPoint(x: 24, y: 14), "destructive cursor hot spot")
}

func testCursorOverlayFrameUsesHotSpot() {
    let frame = CursorOverlay.frame(
        forPointerLocation: CGPoint(x: 100, y: 200),
        size: CGSize(width: 44, height: 44),
        hotSpot: CGPoint(x: 24, y: 14)
    )

    expectEqual(frame, CGRect(x: 76, y: 186, width: 44, height: 44), "cursor overlay frame")
}
