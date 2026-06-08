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

do {
    testHarnessIsConfigured()
    try testDefaultsUseTermSignalAndNoTimeout()
    try testParsesSupportedFlags()
    testRejectsUnknownFlag()
    testRejectsMissingTimeoutValue()
    testRejectsInvalidTimeoutValue()
    print("mxkillUnitTests: PASS")
} catch {
    fail("unexpected thrown error: \(error)")
}
