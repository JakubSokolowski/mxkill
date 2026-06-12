# Hover Highlight Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show a red hover border around the window that `mxkill` is about to target.

**Architecture:** Add a hover-specific Accessibility helper that resolves a pointer location into a target window frame, then add a small border-only AppKit overlay. Integrate the overlay into `ClickPicker` through mouse-move monitoring while keeping the clicked point as the authoritative kill target.

**Tech Stack:** Swift Package Manager, executable Swift test harness, AppKit, ApplicationServices.

---

## File Structure

- `Sources/mxkillCore/HoverTarget.swift`: value type for a hover-highlightable window.
- `Sources/mxkillCore/AccessibilityHoverHitTester.swift`: Accessibility hover hit-testing and AX/AppKit frame conversion helpers.
- `Sources/mxkillCore/HighlightOverlay.swift`: border-only transparent overlay window.
- `Sources/mxkillCore/ClickPicker.swift`: installs mouse-move monitoring and updates the overlay.
- `Sources/mxkillUnitTests/main.swift`: executable harness tests for pure hover frame conversion.

## Task 1: Hover Target Hit Testing Helpers

**Files:**
- Create: `Sources/mxkillCore/HoverTarget.swift`
- Create: `Sources/mxkillCore/AccessibilityHoverHitTester.swift`
- Modify: `Sources/mxkillUnitTests/main.swift`

- [ ] **Step 1: Add failing hover conversion tests**

Add these tests before the final `do` block in `Sources/mxkillUnitTests/main.swift`:

```swift
func testConvertsAXFrameToAppKitFrameOnPrimaryScreen() {
    let screens = [CGRect(x: 0, y: 0, width: 1000, height: 900)]
    let axFrame = CGRect(x: 100, y: 200, width: 300, height: 150)
    let converted = AccessibilityHoverHitTester.appKitFrame(forAXFrame: axFrame, screens: screens)
    expectEqual(converted, CGRect(x: 100, y: 550, width: 300, height: 150), "primary AX frame conversion")
}

func testConvertsAXFrameToAppKitFrameOnAbovePrimaryScreen() {
    let screens = [
        CGRect(x: 0, y: 0, width: 1000, height: 900),
        CGRect(x: 0, y: 900, width: 1000, height: 900)
    ]
    let axFrame = CGRect(x: 100, y: -250, width: 300, height: 150)
    let converted = AccessibilityHoverHitTester.appKitFrame(forAXFrame: axFrame, screens: screens)
    expectEqual(converted, CGRect(x: 100, y: 1000, width: 300, height: 150), "above-primary AX frame conversion")
}

func testConvertsAXFrameToAppKitFrameOnBelowPrimaryScreen() {
    let screens = [
        CGRect(x: 0, y: 0, width: 1000, height: 900),
        CGRect(x: 0, y: -900, width: 1000, height: 900)
    ]
    let axFrame = CGRect(x: 100, y: 1000, width: 300, height: 150)
    let converted = AccessibilityHoverHitTester.appKitFrame(forAXFrame: axFrame, screens: screens)
    expectEqual(converted, CGRect(x: 100, y: -250, width: 300, height: 150), "below-primary AX frame conversion")
}
```

Also call the three new functions in the final `do` block.

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
swift run mxkillUnitTests
```

Expected: FAIL because `AccessibilityHoverHitTester` does not exist.

- [ ] **Step 3: Add hover target and conversion helper**

Create `Sources/mxkillCore/HoverTarget.swift`:

```swift
import Foundation

public struct HoverTarget: Equatable {
    public let frame: CGRect
    public let pid: pid_t?
    public let processName: String?

    public init(frame: CGRect, pid: pid_t?, processName: String?) {
        self.frame = frame
        self.pid = pid
        self.processName = processName
    }
}
```

Create `Sources/mxkillCore/AccessibilityHoverHitTester.swift`:

```swift
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
            if AXUIElementCopyAttributeValue(candidate, kAXParentAttribute as CFString, &parent) == .success {
                current = (parent as! AXUIElement)
            } else {
                current = nil
            }
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

        var positionValue: CFTypeRef?
        var sizeValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &positionValue) == .success,
              AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeValue) == .success,
              let position = positionValue,
              let size = sizeValue
        else {
            return nil
        }

        var point = CGPoint.zero
        var dimensions = CGSize.zero
        guard AXValueGetValue(position as! AXValue, .cgPoint, &point),
              AXValueGetValue(size as! AXValue, .cgSize, &dimensions),
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
}
```

- [ ] **Step 4: Run tests and build**

Run:

```bash
swift run mxkillUnitTests
swift build -c release
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Sources/mxkillCore/HoverTarget.swift Sources/mxkillCore/AccessibilityHoverHitTester.swift Sources/mxkillUnitTests/main.swift
git commit -m "Add hover target hit testing"
```

## Task 2: Highlight Overlay and Picker Integration

**Files:**
- Create: `Sources/mxkillCore/HighlightOverlay.swift`
- Modify: `Sources/mxkillCore/ClickPicker.swift`

- [ ] **Step 1: Add overlay implementation**

Create `Sources/mxkillCore/HighlightOverlay.swift`:

```swift
import AppKit
import Foundation

public final class HighlightOverlay {
    private let window: NSWindow
    private let borderView: NSView

    public init() {
        borderView = NSView(frame: .zero)
        borderView.wantsLayer = true
        borderView.layer?.borderColor = NSColor.systemRed.cgColor
        borderView.layer?.borderWidth = 4
        borderView.layer?.backgroundColor = NSColor.clear.cgColor

        window = NSWindow(
            contentRect: .zero,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.ignoresMouseEvents = true
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.contentView = borderView
    }

    public func show(frame: CGRect) {
        window.setFrame(frame, display: true)
        window.orderFrontRegardless()
    }

    public func hide() {
        window.orderOut(nil)
    }
}
```

- [ ] **Step 2: Integrate overlay into ClickPicker**

Modify `Sources/mxkillCore/ClickPicker.swift`:

```swift
import AppKit
import Foundation

public enum PickResult: Equatable {
    case selected(CGPoint)
    case cancelled
    case timedOut
    case failedToInstallMonitor
}

public final class ClickPicker {
    private var result: PickResult?
    private var monitors: [Any] = []
    private let overlay: HighlightOverlay

    public init(overlay: HighlightOverlay = HighlightOverlay()) {
        self.overlay = overlay
    }

    public func pick(timeoutSeconds: Double?) -> PickResult {
        NSApplication.shared.setActivationPolicy(.accessory)
        NSCursor.crosshair.set()

        guard installMonitors() else {
            cleanup()
            return .failedToInstallMonitor
        }

        scheduleTimeout(timeoutSeconds)

        while result == nil {
            autoreleasepool {
                let event = NSApp.nextEvent(
                    matching: .any,
                    until: Date(timeIntervalSinceNow: 0.1),
                    inMode: .default,
                    dequeue: true
                )

                if let event {
                    NSApp.sendEvent(event)
                }
            }
        }

        let finalResult = result ?? .cancelled
        cleanup()
        return finalResult
    }

    private func installMonitors() -> Bool {
        guard let leftMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown], handler: { [weak self] event in
            self?.result = .selected(event.locationInWindow)
        }) else {
            return false
        }

        monitors.append(leftMouseMonitor)

        guard let rightMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.rightMouseDown], handler: { [weak self] _ in
            self?.result = .cancelled
        }) else {
            return false
        }

        monitors.append(rightMouseMonitor)

        if let mouseMoveMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged], handler: { [weak self] event in
            self?.updateHighlight(at: event.locationInWindow)
        }) {
            monitors.append(mouseMoveMonitor)
        }

        if let keyMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown], handler: { [weak self] event in
            if event.keyCode == 53 {
                self?.result = .cancelled
            }
        }) {
            monitors.append(keyMonitor)
        }

        return true
    }

    private func updateHighlight(at point: CGPoint) {
        guard let target = AccessibilityHoverHitTester.hoverTarget(at: point) else {
            overlay.hide()
            return
        }

        overlay.show(frame: target.frame)
    }

    private func scheduleTimeout(_ timeoutSeconds: Double?) {
        guard let timeoutSeconds else {
            return
        }

        Timer.scheduledTimer(withTimeInterval: timeoutSeconds, repeats: false) { [weak self] _ in
            if self?.result == nil {
                self?.result = .timedOut
            }
        }
    }

    private func cleanup() {
        overlay.hide()
        removeMonitors()
        NSCursor.arrow.set()
    }

    private func removeMonitors() {
        for monitor in monitors {
            NSEvent.removeMonitor(monitor)
        }

        monitors.removeAll()
    }
}
```

- [ ] **Step 3: Build and test**

Run:

```bash
swift run mxkillUnitTests
swift build -c release
```

Expected: PASS.

- [ ] **Step 4: Manually verify overlay**

Run:

```bash
.build/release/mxkill --dry-run --timeout 15
```

Expected:

- Hovering a normal app window shows a red border around it.
- Moving between windows moves the border.
- Moving outside targetable windows hides the border.
- Clicking a window prints `mxkill: would send signal 15 ...`.
- Timeout or cancel removes the border.

- [ ] **Step 5: Commit**

```bash
git add Sources/mxkillCore/HighlightOverlay.swift Sources/mxkillCore/ClickPicker.swift
git commit -m "Add hover highlight overlay"
```

## Self-Review

- Spec coverage: The plan covers hover hit testing, frame conversion, overlay display, picker integration, cleanup, and manual verification.
- Red-flag scan: The plan uses concrete file paths, code blocks, commands, and expected outcomes.
- Type consistency: `HoverTarget`, `AccessibilityHoverHitTester`, `HighlightOverlay`, and `ClickPicker` names are consistent across tasks.
