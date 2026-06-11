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
    case pointOutsideScreens
    case elementAtPositionFailed(AXError)
    case noElementAtPoint
    case pidLookupFailed(AXError)
    case missingPid

    public var description: String {
        switch self {
        case .pointOutsideScreens:
            return "click point is not on any visible screen"
        case .elementAtPositionFailed(let error):
            return "Accessibility hit testing failed (\(error)); check that mxkill has Accessibility permission"
        case .noElementAtPoint:
            return "no UI element found at click point; try clicking inside a visible app window"
        case .pidLookupFailed(let error):
            return "could not read owning process for clicked UI element (\(error)); check Accessibility permission and try again"
        case .missingPid:
            return "clicked UI element did not report a valid owning process"
        }
    }
}

public enum AccessibilityHitTester {
    public static func accessibilityPoint(forAppKitPoint appKitPoint: CGPoint, screens: [CGRect]) -> CGPoint? {
        guard let screen = screens.first(where: { screen in
            appKitPoint.x >= screen.minX &&
                appKitPoint.x < screen.maxX &&
                appKitPoint.y >= screen.minY &&
                appKitPoint.y < screen.maxY
        }) else {
            return nil
        }

        return CGPoint(
            x: appKitPoint.x,
            y: screen.maxY - (appKitPoint.y - screen.minY)
        )
    }

    public static func targetProcess(at screenPoint: CGPoint) throws -> TargetProcess {
        guard let accessibilityPoint = accessibilityPoint(
            forAppKitPoint: screenPoint,
            screens: NSScreen.screens.map(\.frame)
        ) else {
            throw HitTestError.pointOutsideScreens
        }

        let systemWideElement = AXUIElementCreateSystemWide()
        var element: AXUIElement?
        let result = AXUIElementCopyElementAtPosition(
            systemWideElement,
            Float(accessibilityPoint.x),
            Float(accessibilityPoint.y),
            &element
        )

        guard result == .success else {
            throw HitTestError.elementAtPositionFailed(result)
        }

        guard let element else {
            throw HitTestError.noElementAtPoint
        }

        var pid: pid_t = 0
        let pidResult = AXUIElementGetPid(element, &pid)
        guard pidResult == .success else {
            throw HitTestError.pidLookupFailed(pidResult)
        }

        guard pid > 0 else {
            throw HitTestError.missingPid
        }

        let processName = NSRunningApplication(processIdentifier: pid)?.localizedName ?? "pid \(pid)"
        return TargetProcess(pid: pid, processName: processName)
    }
}
