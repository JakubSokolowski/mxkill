import Darwin
import Foundation

public enum SignalResult: Equatable {
    case dryRun(signal: Int32)
    case sent(signal: Int32)
}

public enum SignalSender {
    public static func signal(force: Bool) -> Int32 {
        force ? SIGKILL : SIGTERM
    }

    public static func send(
        pid: pid_t,
        force: Bool,
        dryRun: Bool,
        killFunction: (pid_t, Int32) -> Int32 = Darwin.kill
    ) throws -> SignalResult {
        let chosenSignal = signal(force: force)

        if dryRun {
            return .dryRun(signal: chosenSignal)
        }

        if killFunction(pid, chosenSignal) == 0 {
            return .sent(signal: chosenSignal)
        }

        throw SignalSenderError.signalFailed(pid: pid, errnoCode: errno)
    }
}

public struct SignalSenderError: Error, CustomStringConvertible, Equatable {
    public let pid: pid_t
    public let errnoCode: Int32

    public static func signalFailed(pid: pid_t, errnoCode: Int32) -> SignalSenderError {
        SignalSenderError(pid: pid, errnoCode: errnoCode)
    }

    public var description: String {
        "failed to signal pid \(pid): \(String(cString: strerror(errnoCode)))"
    }
}
