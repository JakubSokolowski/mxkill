import ApplicationServices
import AppKit
import Foundation

public struct TargetProcess: Equatable {
    public let pid: pid_t
    public let processName: String

    public init(pid: pid_t, processName: String) {
        self.pid = pid
        self.processName = processName
    }
}

public enum HitTestError: Error, CustomStringConvertible {
    case noElementAtPoint
    case missingPid

    public var description: String {
        switch self {
        case .noElementAtPoint:
            return "no UI element found at click point"
        case .missingPid:
            return "could not resolve owning process for clicked window"
        }
    }
}

public enum AccessibilityHitTester {
    public static func targetProcess(at screenPoint: CGPoint) throws -> TargetProcess {
        let systemWideElement = AXUIElementCreateSystemWide()
        var element: AXUIElement?
        let result = AXUIElementCopyElementAtPosition(
            systemWideElement,
            Float(screenPoint.x),
            Float(screenPoint.y),
            &element
        )

        guard result == .success, let element else {
            throw HitTestError.noElementAtPoint
        }

        var pid: pid_t = 0
        guard AXUIElementGetPid(element, &pid) == .success, pid > 0 else {
            throw HitTestError.missingPid
        }

        let processName = NSRunningApplication(processIdentifier: pid)?.localizedName ?? "pid \(pid)"
        return TargetProcess(pid: pid, processName: processName)
    }
}
