import Foundation
import mxkillCore

func testConvertsPrimaryScreenPointToAccessibilityCoordinates() {
    let screens = [
        CGRect(x: 0, y: 0, width: 1440, height: 900)
    ]

    let point = AccessibilityHitTester.accessibilityPoint(
        forAppKitPoint: CGPoint(x: 20, y: 100),
        screens: screens
    )

    expectEqual(point, CGPoint(x: 20, y: 800), "primary screen coordinate conversion")
}

func testConvertsHorizontalNonPrimaryScreenPointToAccessibilityCoordinates() {
    let screens = [
        CGRect(x: 0, y: 0, width: 1440, height: 900),
        CGRect(x: -1280, y: 0, width: 1280, height: 1024)
    ]

    let point = AccessibilityHitTester.accessibilityPoint(
        forAppKitPoint: CGPoint(x: -100, y: 200),
        screens: screens
    )

    expectEqual(point, CGPoint(x: -100, y: 700), "non-primary screen coordinate conversion")
}

func testConvertsScreenAbovePrimaryPointToAccessibilityCoordinates() {
    let screens = [
        CGRect(x: 0, y: 0, width: 1440, height: 900),
        CGRect(x: 0, y: 900, width: 1440, height: 900)
    ]

    let point = AccessibilityHitTester.accessibilityPoint(
        forAppKitPoint: CGPoint(x: 20, y: 1000),
        screens: screens
    )

    expectEqual(point, CGPoint(x: 20, y: -100), "screen above primary coordinate conversion")
}

func testConvertsScreenBelowPrimaryPointToAccessibilityCoordinates() {
    let screens = [
        CGRect(x: 0, y: 0, width: 1440, height: 900),
        CGRect(x: 0, y: -900, width: 1440, height: 900)
    ]

    let point = AccessibilityHitTester.accessibilityPoint(
        forAppKitPoint: CGPoint(x: 20, y: -100),
        screens: screens
    )

    expectEqual(point, CGPoint(x: 20, y: 1000), "screen below primary coordinate conversion")
}

func testReturnsNilWhenPointIsOutsideScreens() {
    let screens = [
        CGRect(x: 0, y: 0, width: 1440, height: 900)
    ]

    let point = AccessibilityHitTester.accessibilityPoint(
        forAppKitPoint: CGPoint(x: 1500, y: 100),
        screens: screens
    )

    expectNil(point, "outside screen coordinate conversion")
}

func testConvertsAXFrameToAppKitFrameOnPrimaryScreen() {
    let screens = [CGRect(x: 0, y: 0, width: 1000, height: 900)]
    let axFrame = CGRect(x: 100, y: 200, width: 300, height: 150)
    let converted = AccessibilityHoverHitTester.appKitFrame(forAXFrame: axFrame, screens: screens)
    expectEqual(converted, Optional(CGRect(x: 100, y: 550, width: 300, height: 150)), "primary AX frame conversion")
}

func testConvertsAXFrameToAppKitFrameOnAbovePrimaryScreen() {
    let screens = [
        CGRect(x: 0, y: 0, width: 1000, height: 900),
        CGRect(x: 0, y: 900, width: 1000, height: 900)
    ]
    let axFrame = CGRect(x: 100, y: -250, width: 300, height: 150)
    let converted = AccessibilityHoverHitTester.appKitFrame(forAXFrame: axFrame, screens: screens)
    expectEqual(converted, Optional(CGRect(x: 100, y: 1000, width: 300, height: 150)), "above-primary AX frame conversion")
}

func testConvertsAXFrameToAppKitFrameOnBelowPrimaryScreen() {
    let screens = [
        CGRect(x: 0, y: 0, width: 1000, height: 900),
        CGRect(x: 0, y: -900, width: 1000, height: 900)
    ]
    let axFrame = CGRect(x: 100, y: 1000, width: 300, height: 150)
    let converted = AccessibilityHoverHitTester.appKitFrame(forAXFrame: axFrame, screens: screens)
    expectEqual(converted, Optional(CGRect(x: 100, y: -250, width: 300, height: 150)), "below-primary AX frame conversion")
}
