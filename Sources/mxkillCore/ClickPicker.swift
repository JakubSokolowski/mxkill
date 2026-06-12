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

        guard let mouseMoveMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged],
            handler: { [weak self] event in
                self?.updateHighlight(at: event.locationInWindow)
            }
        ) else {
            return false
        }

        monitors.append(mouseMoveMonitor)

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

    private func removeMonitors() {
        for monitor in monitors {
            NSEvent.removeMonitor(monitor)
        }

        monitors.removeAll()
    }

    private func cleanup() {
        overlay.hide()
        removeMonitors()
        NSCursor.arrow.set()
    }
}
