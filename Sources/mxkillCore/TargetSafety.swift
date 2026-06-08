import Foundation

public enum TargetSafety {
    public static func validate(pid: pid_t, currentPid: pid_t = getpid(), includeSelf: Bool) throws {
        guard pid > 0 else {
            throw TargetSafetyError.invalidPid(pid)
        }

        if pid == currentPid && !includeSelf {
            throw TargetSafetyError.refusingSelf
        }
    }
}

public enum TargetSafetyError: Error, CustomStringConvertible, Equatable {
    case invalidPid(pid_t)
    case refusingSelf

    public var description: String {
        switch self {
        case .invalidPid(let pid):
            return "refusing to signal invalid pid \(pid)"
        case .refusingSelf:
            return "refusing to signal mxkill itself; pass --include-self to allow it"
        }
    }
}
