import Foundation

public struct Options: Equatable {
    public var force = false
    public var dryRun = false
    public var includeSelf = false
    public var timeoutSeconds: Double?

    public static let usage = """
    Usage: mxkill [--force] [--dry-run] [--timeout seconds] [--include-self]
    """

    public static func parse(_ arguments: [String]) throws -> Options {
        var options = Options()
        var index = 0

        while index < arguments.count {
            let argument = arguments[index]

            switch argument {
            case "--force":
                options.force = true
            case "--dry-run":
                options.dryRun = true
            case "--include-self":
                options.includeSelf = true
            case "--timeout":
                index += 1
                guard index < arguments.count,
                      let timeout = Double(arguments[index]),
                      timeout > 0
                else {
                    throw OptionsError.invalidTimeout
                }
                options.timeoutSeconds = timeout
            default:
                throw OptionsError.unknownOption(argument)
            }

            index += 1
        }

        return options
    }
}

public enum OptionsError: Error, CustomStringConvertible, Equatable {
    case unknownOption(String)
    case invalidTimeout

    public var description: String {
        switch self {
        case .unknownOption(let option):
            return "unknown option: \(option)"
        case .invalidTimeout:
            return "--timeout requires a positive number"
        }
    }
}
