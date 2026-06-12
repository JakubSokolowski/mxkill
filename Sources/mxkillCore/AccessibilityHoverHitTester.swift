import ApplicationServices
import AppKit
import Foundation

public enum AccessibilityHoverHitTester {
    public static func appKitFrame(forAXFrame axFrame: CGRect, screens: [CGRect]) -> CGRect? {
        guard let primaryScreen = screens.first else {
            return nil
        }

        let appKitFrame = CGRect(
            x: axFrame.origin.x,
            y: primaryScreen.maxY - axFrame.origin.y - axFrame.height,
            width: axFrame.width,
            height: axFrame.height
        )

        guard screens.contains(where: { $0.intersects(appKitFrame) }) else {
            return nil
        }

        return appKitFrame
    }

    public static func hoverTarget(at appKitPoint: CGPoint) -> HoverTarget? {
        guard let accessibilityPoint = AccessibilityHitTester.accessibilityPoint(
            forAppKitPoint: appKitPoint,
            screens: NSScreen.screens.map(\.frame)
        ) else {
            return nil
        }

        let systemWideElement = AXUIElementCreateSystemWide()
        var element: AXUIElement?
        guard AXUIElementCopyElementAtPosition(
            systemWideElement,
            Float(accessibilityPoint.x),
            Float(accessibilityPoint.y),
            &element
        ) == .success, let element else {
            return nil
        }

        return hoverTarget(from: element)
    }

    private static func hoverTarget(from element: AXUIElement) -> HoverTarget? {
        var current: AXUIElement? = element

        while let candidate = current {
            if let target = targetIfWindowLike(candidate) {
                return target
            }

            var parent: CFTypeRef?
            guard AXUIElementCopyAttributeValue(candidate, kAXParentAttribute as CFString, &parent) == .success else {
                return nil
            }

            current = axElement(from: parent)
        }

        return nil
    }

    private static func targetIfWindowLike(_ element: AXUIElement) -> HoverTarget? {
        var roleValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleValue) == .success,
              (roleValue as? String) == kAXWindowRole
        else {
            return nil
        }

        guard let point = cgPointAttribute(element, kAXPositionAttribute),
              let dimensions = cgSizeAttribute(element, kAXSizeAttribute),
              let frame = appKitFrame(
                  forAXFrame: CGRect(origin: point, size: dimensions),
                  screens: NSScreen.screens.map(\.frame)
              )
        else {
            return nil
        }

        var pid: pid_t = 0
        let pidValue: pid_t? = AXUIElementGetPid(element, &pid) == .success && pid > 0 ? pid : nil
        let processName = pidValue.flatMap { NSRunningApplication(processIdentifier: $0)?.localizedName }
        return HoverTarget(frame: frame, pid: pidValue, processName: processName)
    }

    private static func cgPointAttribute(_ element: AXUIElement, _ attribute: String) -> CGPoint? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success,
              let axValue = axValue(from: value),
              AXValueGetType(axValue) == .cgPoint
        else {
            return nil
        }

        var point = CGPoint.zero
        guard AXValueGetValue(axValue, .cgPoint, &point) else {
            return nil
        }

        return point
    }

    private static func cgSizeAttribute(_ element: AXUIElement, _ attribute: String) -> CGSize? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success,
              let axValue = axValue(from: value),
              AXValueGetType(axValue) == .cgSize
        else {
            return nil
        }

        var size = CGSize.zero
        guard AXValueGetValue(axValue, .cgSize, &size) else {
            return nil
        }

        return size
    }

    private static func axElement(from value: CFTypeRef?) -> AXUIElement? {
        guard let value,
              CFGetTypeID(value) == AXUIElementGetTypeID()
        else {
            return nil
        }

        return (value as! AXUIElement)
    }

    private static func axValue(from value: CFTypeRef?) -> AXValue? {
        guard let value,
              CFGetTypeID(value) == AXValueGetTypeID()
        else {
            return nil
        }

        return (value as! AXValue)
    }
}
