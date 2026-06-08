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
    print("mxkillUnitTests: PASS")
} catch {
    fail("unexpected thrown error: \(error)")
}
