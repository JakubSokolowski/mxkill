import Foundation
import mxkillCore

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
