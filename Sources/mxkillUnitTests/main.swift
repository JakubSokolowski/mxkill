import Foundation

func testHarnessIsConfigured() {
    expectEqual("mxkill", "mxkill", "test harness is configured")
}

do {
    testHarnessIsConfigured()
    try testDefaultsUseTermSignalAndNoTimeout()
    try testParsesSupportedFlags()
    testRejectsUnknownFlag()
    testRejectsMissingTimeoutValue()
    testRejectsInvalidTimeoutValue()
    testRejectsInfiniteTimeoutValue()
    testRejectsZeroPid()
    testRejectsNegativePid()
    testRejectsSelfByDefault()
    try testAllowsSelfWhenExplicitlyRequested()
    testUsesSigtermByDefault()
    testUsesSigkillWhenForced()
    try testDryRunDoesNotInvokeKillFunction()
    try testSendInvokesKillFunction()
    testThrowsWhenKillFunctionFails()
    testConvertsPrimaryScreenPointToAccessibilityCoordinates()
    testConvertsHorizontalNonPrimaryScreenPointToAccessibilityCoordinates()
    testConvertsScreenAbovePrimaryPointToAccessibilityCoordinates()
    testConvertsScreenBelowPrimaryPointToAccessibilityCoordinates()
    testReturnsNilWhenPointIsOutsideScreens()
    testConvertsAXFrameToAppKitFrameOnPrimaryScreen()
    testConvertsAXFrameToAppKitFrameOnAbovePrimaryScreen()
    testConvertsAXFrameToAppKitFrameOnBelowPrimaryScreen()
    testDestructiveCursorHotSpotPlacesIconUpLeftOfPointer()
    testCursorOverlayFrameUsesHotSpot()
    print("mxkillUnitTests: PASS")
} catch {
    fail("unexpected thrown error: \(error)")
}
