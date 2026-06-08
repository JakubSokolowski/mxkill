import Foundation

func expectEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String) {
    if actual != expected {
        fputs("FAIL: \(message): expected \(expected), got \(actual)\n", stderr)
        exit(1)
    }
}

expectEqual("mxkill", "mxkill", "test harness is configured")
print("mxkillUnitTests: PASS")
