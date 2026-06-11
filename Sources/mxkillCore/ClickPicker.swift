import AppKit
import Foundation

public enum PickResult: Equatable {
    case selected(CGPoint)
    case cancelled
    case timedOut
}

public final class ClickPicker {
    private var result: PickResult?
    private var monitors: [Any] = []

    public init() {}

    public func pick(timeoutSeconds: Double?) -> PickResult {
        NSApplication.shared.setActivationPolicy(.accessory)
        NSCursor.crosshair.set()

        installMonitors()
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

        removeMonitors()
        NSCursor.arrow.set()
        return result ?? .cancelled
    }

    private func installMonitors() {
        monitors.append(NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown]) { [weak self] _ in
            self?.result = .selected(NSEvent.mouseLocation)
        } as Any)

        monitors.append(NSEvent.addGlobalMonitorForEvents(matching: [.rightMouseDown]) { [weak self] _ in
            self?.result = .cancelled
        } as Any)

        monitors.append(NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            if event.keyCode == 53 {
                self?.result = .cancelled
            }
        } as Any)
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
}
