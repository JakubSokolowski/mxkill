import Darwin
import Foundation
import mxkillCore

func fail(_ message: String) -> Never {
    fputs("FAIL: \(message)\n", stderr)
    exit(1)
}

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    if !condition() {
        fail(message)
    }
}

func expectEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String) {
    if actual != expected {
        fail("\(message): expected \(expected), got \(actual)")
    }
}

func expectNil<T>(_ value: T?, _ message: String) {
    if let value {
        fail("\(message): expected nil, got \(value)")
    }
}

func expectThrows(_ expectedDescription: String, _ message: String, _ operation: () throws -> Void) {
    do {
        try operation()
        fail("\(message): expected throw")
    } catch {
        expectEqual(String(describing: error), expectedDescription, message)
    }
}

func testHarnessIsConfigured() {
    expectEqual("mxkill", "mxkill", "test harness is configured")
}

func testDefaultsUseTermSignalAndNoTimeout() throws {
    let options = try Options.parse([])
    expect(!options.force, "default force is false")
    expect(!options.dryRun, "default dryRun is false")
    expect(!options.includeSelf, "default includeSelf is false")
    expectNil(options.timeoutSeconds, "default timeout is nil")
}

func testParsesSupportedFlags() throws {
    let options = try Options.parse(["--force", "--dry-run", "--timeout", "3.5", "--include-self"])
    expect(options.force, "force flag is parsed")
    expect(options.dryRun, "dry-run flag is parsed")
    expect(options.includeSelf, "include-self flag is parsed")
    expectEqual(options.timeoutSeconds, 3.5, "timeout is parsed")
}

func testRejectsUnknownFlag() {
    expectThrows("unknown option: --bogus", "unknown option rejection") {
        _ = try Options.parse(["--bogus"])
    }
}

func testRejectsMissingTimeoutValue() {
    expectThrows("--timeout requires a positive number", "missing timeout rejection") {
        _ = try Options.parse(["--timeout"])
    }
}

func testRejectsInvalidTimeoutValue() {
    expectThrows("--timeout requires a positive number", "invalid timeout rejection") {
        _ = try Options.parse(["--timeout", "0"])
    }
}

func testRejectsInfiniteTimeoutValue() {
    expectThrows("--timeout requires a positive number", "infinite timeout rejection") {
        _ = try Options.parse(["--timeout", "inf"])
    }
}

func testRejectsZeroPid() {
    expectThrows("refusing to signal invalid pid 0", "zero pid rejection") {
        try TargetSafety.validate(pid: 0, currentPid: 123, includeSelf: false)
    }
}

func testRejectsNegativePid() {
    expectThrows("refusing to signal invalid pid -1", "negative pid rejection") {
        try TargetSafety.validate(pid: -1, currentPid: 123, includeSelf: false)
    }
}

func testRejectsSelfByDefault() {
    expectThrows("refusing to signal mxkill itself; pass --include-self to allow it", "self pid rejection") {
        try TargetSafety.validate(pid: 123, currentPid: 123, includeSelf: false)
    }
}

func testAllowsSelfWhenExplicitlyRequested() throws {
    try TargetSafety.validate(pid: 123, currentPid: 123, includeSelf: true)
}

func testUsesSigtermByDefault() {
    expectEqual(SignalSender.signal(force: false), SIGTERM, "default signal")
}

func testUsesSigkillWhenForced() {
    expectEqual(SignalSender.signal(force: true), SIGKILL, "forced signal")
}

func testDryRunDoesNotInvokeKillFunction() throws {
    var calls: [(pid_t, Int32)] = []
    let result = try SignalSender.send(
        pid: 999,
        force: true,
        dryRun: true,
        killFunction: { pid, signal in
            calls.append((pid, signal))
            return 0
        }
    )

    expectEqual(result, .dryRun(signal: SIGKILL), "dry-run signal result")
    expect(calls.isEmpty, "dry-run does not call kill")
}

func testSendInvokesKillFunction() throws {
    var calls: [(pid_t, Int32)] = []
    let result = try SignalSender.send(
        pid: 999,
        force: false,
        dryRun: false,
        killFunction: { pid, signal in
            calls.append((pid, signal))
            return 0
        }
    )

    expectEqual(result, .sent(signal: SIGTERM), "sent signal result")
    expectEqual(calls.count, 1, "kill call count")
    expectEqual(calls.first?.0, 999, "kill pid")
    expectEqual(calls.first?.1, SIGTERM, "kill signal")
}

func testThrowsWhenKillFunctionFails() {
    do {
        _ = try SignalSender.send(
            pid: 999,
            force: false,
            dryRun: false,
            killFunction: { _, _ in
                errno = ESRCH
                return -1
            }
        )
        fail("failed kill should throw")
    } catch {
        expect(String(describing: error).contains("failed to signal pid 999"), "failed kill error includes pid")
        expectEqual(error as? SignalSenderError, SignalSenderError.signalFailed(pid: 999, errnoCode: ESRCH), "failed kill error captures errno")
    }
}

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

func testConvertsNonPrimaryScreenPointToAccessibilityCoordinates() {
    let screens = [
        CGRect(x: 0, y: 0, width: 1440, height: 900),
        CGRect(x: -1280, y: 0, width: 1280, height: 1024)
    ]

    let point = AccessibilityHitTester.accessibilityPoint(
        forAppKitPoint: CGPoint(x: -100, y: 200),
        screens: screens
    )

    expectEqual(point, CGPoint(x: -100, y: 824), "non-primary screen coordinate conversion")
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
    testConvertsNonPrimaryScreenPointToAccessibilityCoordinates()
    testReturnsNilWhenPointIsOutsideScreens()
    print("mxkillUnitTests: PASS")
} catch {
    fail("unexpected thrown error: \(error)")
}
