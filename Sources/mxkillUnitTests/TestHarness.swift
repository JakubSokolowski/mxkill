import Darwin
import Foundation

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
