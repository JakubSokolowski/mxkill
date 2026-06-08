# mxkill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build `mxkill`, a native macOS CLI that lets the user click a window and terminate the owning process.

**Architecture:** Use Swift Package Manager with a thin executable target, a small library target, and an executable test harness target. Keep pure logic in testable library files (`Options`, `TargetSafety`, `SignalSender`) and isolate macOS UI/Accessibility code behind small runtime components used by the executable.

**Tech Stack:** Swift Package Manager, executable Swift test harness, AppKit, ApplicationServices, Darwin.

---

## File Structure

- `Package.swift`: SwiftPM manifest defining the `mxkillCore` library, `mxkill` executable, and `mxkillUnitTests` executable harness.
- `Sources/mxkill/main.swift`: thin CLI entrypoint that calls `MXKill.run(arguments:)`.
- `Sources/mxkillCore/MXKill.swift`: orchestration that parses options, checks Accessibility permission, runs click selection, and sends the chosen signal.
- `Sources/mxkillCore/Options.swift`: hand-written argument parsing and usage text.
- `Sources/mxkillCore/TargetSafety.swift`: PID safety checks, including invalid PID and self-kill refusal.
- `Sources/mxkillCore/SignalSender.swift`: maps options to `SIGTERM`/`SIGKILL` and wraps `kill(2)`.
- `Sources/mxkillCore/AccessibilityPermission.swift`: checks and prompts for macOS Accessibility permission.
- `Sources/mxkillCore/ClickPicker.swift`: AppKit event loop for left click selection, right click cancellation, Escape cancellation, and timeout.
- `Sources/mxkillCore/AccessibilityHitTester.swift`: resolves the clicked screen point to an owning PID and process name.
- `Sources/mxkillUnitTests/main.swift`: executable test harness for pure logic tests.

## Task 1: Swift Package Skeleton

**Files:**
- Create: `Package.swift`
- Create: `Sources/mxkill/main.swift`
- Create: `Sources/mxkillCore/MXKill.swift`
- Create: `Sources/mxkillUnitTests/main.swift`

- [ ] **Step 1: Write the failing executable harness test**

Create `Sources/mxkillUnitTests/main.swift`:

```swift
import Foundation

func expectEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String) {
    if actual != expected {
        fputs("FAIL: \(message): expected \(expected), got \(actual)\n", stderr)
        exit(1)
    }
}

expectEqual("mxkill", "mxkill", "test harness is configured")
print("mxkillUnitTests: PASS")
```

- [ ] **Step 2: Run test harness to verify it fails before the target exists**

Run:

```bash
swift run mxkillUnitTests
```

Expected: FAIL because the `mxkillUnitTests` executable product is not configured yet.

- [ ] **Step 3: Add the SwiftPM manifest and empty executable**

Create `Package.swift`:

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "mxkill",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "mxkill", targets: ["mxkill"]),
        .executable(name: "mxkillUnitTests", targets: ["mxkillUnitTests"])
    ],
    targets: [
        .target(
            name: "mxkillCore"
        ),
        .executableTarget(
            name: "mxkill",
            dependencies: ["mxkillCore"]
        ),
        .executableTarget(
            name: "mxkillUnitTests",
            dependencies: ["mxkillCore"]
        )
    ]
)
```

Create `Sources/mxkill/main.swift`:

```swift
import Darwin
import mxkillCore

exit(MXKill.run(arguments: Array(CommandLine.arguments.dropFirst())))
```

Create `Sources/mxkillCore/MXKill.swift`:

```swift
import Foundation

public enum MXKill {
    public static func run(arguments: [String]) -> Int32 {
        print("mxkill is not implemented yet")
        return 0
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run:

```bash
swift run mxkillUnitTests
swift build
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Package.swift Sources/mxkill/main.swift Sources/mxkillCore/MXKill.swift Sources/mxkillUnitTests/main.swift docs/superpowers/plans/2026-06-08-mxkill-implementation.md
git commit -m "Add Swift package skeleton"
```

## Task 2: CLI Options Parser

**Files:**
- Create: `Sources/mxkillCore/Options.swift`
- Create: `Tests/mxkillTests/OptionsTests.swift`
- Delete: `Tests/mxkillTests/SkeletonTests.swift`

- [ ] **Step 1: Write parser tests**

Create `Tests/mxkillTests/OptionsTests.swift`:

```swift
import XCTest
@testable import mxkillCore

final class OptionsTests: XCTestCase {
    func testDefaultsUseTermSignalAndNoTimeout() throws {
        let options = try Options.parse([])

        XCTAssertFalse(options.force)
        XCTAssertFalse(options.dryRun)
        XCTAssertFalse(options.includeSelf)
        XCTAssertNil(options.timeoutSeconds)
    }

    func testParsesSupportedFlags() throws {
        let options = try Options.parse(["--force", "--dry-run", "--timeout", "3.5", "--include-self"])

        XCTAssertTrue(options.force)
        XCTAssertTrue(options.dryRun)
        XCTAssertTrue(options.includeSelf)
        XCTAssertEqual(options.timeoutSeconds, 3.5)
    }

    func testRejectsUnknownFlag() {
        XCTAssertThrowsError(try Options.parse(["--bogus"])) { error in
            XCTAssertEqual(String(describing: error), "unknown option: --bogus")
        }
    }

    func testRejectsMissingTimeoutValue() {
        XCTAssertThrowsError(try Options.parse(["--timeout"])) { error in
            XCTAssertEqual(String(describing: error), "--timeout requires a positive number")
        }
    }

    func testRejectsInvalidTimeoutValue() {
        XCTAssertThrowsError(try Options.parse(["--timeout", "0"])) { error in
            XCTAssertEqual(String(describing: error), "--timeout requires a positive number")
        }
    }
}
```

- [ ] **Step 2: Run parser tests to verify they fail**

Run:

```bash
swift test --filter OptionsTests
```

Expected: FAIL because `Options` does not exist.

- [ ] **Step 3: Implement the parser**

Create `Sources/mxkillCore/Options.swift`:

```swift
import Foundation

public struct Options: Equatable {
    var force = false
    var dryRun = false
    var includeSelf = false
    var timeoutSeconds: Double?

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

    var description: String {
        switch self {
        case .unknownOption(let option):
            return "unknown option: \(option)"
        case .invalidTimeout:
            return "--timeout requires a positive number"
        }
    }
}
```

- [ ] **Step 4: Remove skeleton test and run all tests**

Run:

```bash
rm Tests/mxkillTests/SkeletonTests.swift
swift test
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Sources/mxkillCore/Options.swift Tests/mxkillTests/OptionsTests.swift
git rm Tests/mxkillTests/SkeletonTests.swift
git commit -m "Add CLI option parsing"
```

## Task 3: Target Safety Checks

**Files:**
- Create: `Sources/mxkillCore/TargetSafety.swift`
- Create: `Tests/mxkillTests/TargetSafetyTests.swift`

- [ ] **Step 1: Write safety tests**

Create `Tests/mxkillTests/TargetSafetyTests.swift`:

```swift
import XCTest
@testable import mxkillCore

final class TargetSafetyTests: XCTestCase {
    func testRejectsZeroPid() {
        XCTAssertThrowsError(try TargetSafety.validate(pid: 0, currentPid: 123, includeSelf: false)) { error in
            XCTAssertEqual(String(describing: error), "refusing to signal invalid pid 0")
        }
    }

    func testRejectsNegativePid() {
        XCTAssertThrowsError(try TargetSafety.validate(pid: -1, currentPid: 123, includeSelf: false)) { error in
            XCTAssertEqual(String(describing: error), "refusing to signal invalid pid -1")
        }
    }

    func testRejectsSelfByDefault() {
        XCTAssertThrowsError(try TargetSafety.validate(pid: 123, currentPid: 123, includeSelf: false)) { error in
            XCTAssertEqual(String(describing: error), "refusing to signal mxkill itself; pass --include-self to allow it")
        }
    }

    func testAllowsSelfWhenExplicitlyRequested() throws {
        try TargetSafety.validate(pid: 123, currentPid: 123, includeSelf: true)
    }
}
```

- [ ] **Step 2: Run safety tests to verify they fail**

Run:

```bash
swift test --filter TargetSafetyTests
```

Expected: FAIL because `TargetSafety` does not exist.

- [ ] **Step 3: Implement safety checks**

Create `Sources/mxkillCore/TargetSafety.swift`:

```swift
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

    var description: String {
        switch self {
        case .invalidPid(let pid):
            return "refusing to signal invalid pid \(pid)"
        case .refusingSelf:
            return "refusing to signal mxkill itself; pass --include-self to allow it"
        }
    }
}
```

- [ ] **Step 4: Run tests**

Run:

```bash
swift test
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Sources/mxkillCore/TargetSafety.swift Tests/mxkillTests/TargetSafetyTests.swift
git commit -m "Add target safety checks"
```

## Task 4: Signal Selection and Dry Run

**Files:**
- Create: `Sources/mxkillCore/SignalSender.swift`
- Create: `Tests/mxkillTests/SignalSenderTests.swift`

- [ ] **Step 1: Write signal tests**

Create `Tests/mxkillTests/SignalSenderTests.swift`:

```swift
import XCTest
@testable import mxkillCore

final class SignalSenderTests: XCTestCase {
    func testUsesSigtermByDefault() {
        XCTAssertEqual(SignalSender.signal(force: false), SIGTERM)
    }

    func testUsesSigkillWhenForced() {
        XCTAssertEqual(SignalSender.signal(force: true), SIGKILL)
    }

    func testDryRunDoesNotInvokeKillFunction() throws {
        var calls: [(pid_t, Int32)] = []
        let result = try SignalSender.send(
            pid: 999,
            force: true,
            dryRun: true,
            killFunction: { pid, signal in
                calls.append((pid, signal))
                return 0
            }
        )

        XCTAssertEqual(result, .dryRun(signal: SIGKILL))
        XCTAssertTrue(calls.isEmpty)
    }

    func testSendInvokesKillFunction() throws {
        var calls: [(pid_t, Int32)] = []
        let result = try SignalSender.send(
            pid: 999,
            force: false,
            dryRun: false,
            killFunction: { pid, signal in
                calls.append((pid, signal))
                return 0
            }
        )

        XCTAssertEqual(result, .sent(signal: SIGTERM))
        XCTAssertEqual(calls.count, 1)
        XCTAssertEqual(calls.first?.0, 999)
        XCTAssertEqual(calls.first?.1, SIGTERM)
    }

    func testThrowsWhenKillFunctionFails() {
        XCTAssertThrowsError(try SignalSender.send(
            pid: 999,
            force: false,
            dryRun: false,
            killFunction: { _, _ in -1 }
        )) { error in
            XCTAssertTrue(String(describing: error).contains("failed to signal pid 999"))
        }
    }
}
```

- [ ] **Step 2: Run signal tests to verify they fail**

Run:

```bash
swift test --filter SignalSenderTests
```

Expected: FAIL because `SignalSender` does not exist.

- [ ] **Step 3: Implement signal sending**

Create `Sources/mxkillCore/SignalSender.swift`:

```swift
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
    let pid: pid_t
    let errnoCode: Int32

    static func signalFailed(pid: pid_t, errnoCode: Int32) -> SignalSenderError {
        SignalSenderError(pid: pid, errnoCode: errnoCode)
    }

    var description: String {
        "failed to signal pid \(pid): \(String(cString: strerror(errnoCode)))"
    }
}
```

- [ ] **Step 4: Run tests**

Run:

```bash
swift test
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Sources/mxkillCore/SignalSender.swift Tests/mxkillTests/SignalSenderTests.swift
git commit -m "Add signal sender"
```

## Task 5: macOS Runtime Components

**Files:**
- Create: `Sources/mxkillCore/AccessibilityPermission.swift`
- Create: `Sources/mxkillCore/AccessibilityHitTester.swift`
- Create: `Sources/mxkillCore/ClickPicker.swift`

- [ ] **Step 1: Add runtime component files**

Create `Sources/mxkillCore/AccessibilityPermission.swift`:

```swift
import ApplicationServices
import Foundation

public enum AccessibilityPermission {
    public static func isTrusted(prompt: Bool) -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    public static let instructions = """
    mxkill needs Accessibility permission to identify the window you click.
    Open System Settings > Privacy & Security > Accessibility and enable your terminal app, then run mxkill again.
    """
}
```

Create `Sources/mxkillCore/AccessibilityHitTester.swift`:

```swift
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

    var description: String {
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
```

Create `Sources/mxkillCore/ClickPicker.swift`:

```swift
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
```

- [ ] **Step 2: Build**

Run:

```bash
swift build
```

Expected: PASS. Fix compile errors only in the runtime files if AppKit/ApplicationServices signatures require minor adjustment.

- [ ] **Step 3: Run all tests**

Run:

```bash
swift test
```

Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add Sources/mxkillCore/AccessibilityPermission.swift Sources/mxkillCore/AccessibilityHitTester.swift Sources/mxkillCore/ClickPicker.swift
git commit -m "Add macOS click picking components"
```

## Task 6: Wire the Executable

**Files:**
- Modify: `Sources/mxkillCore/MXKill.swift`
- Modify: `Sources/mxkill/main.swift`

- [ ] **Step 1: Replace temporary entrypoint**

Replace `Sources/mxkillCore/MXKill.swift` with:

```swift
import Foundation

public enum MXKill {
    public static func run(arguments: [String]) -> Int32 {
        let options: Options
        do {
            options = try Options.parse(arguments)
        } catch {
            fputs("\(error)\n\n\(Options.usage)\n", stderr)
            return 64
        }

        guard AccessibilityPermission.isTrusted(prompt: true) else {
            fputs("\(AccessibilityPermission.instructions)\n", stderr)
            return 77
        }

        let pickResult = ClickPicker().pick(timeoutSeconds: options.timeoutSeconds)

        switch pickResult {
        case .cancelled:
            print("mxkill: cancelled")
            return 0
        case .timedOut:
            fputs("mxkill: timed out waiting for click\n", stderr)
            return 70
        case .selected(let point):
            do {
                let target = try AccessibilityHitTester.targetProcess(at: point)
                try TargetSafety.validate(pid: target.pid, includeSelf: options.includeSelf)
                let result = try SignalSender.send(pid: target.pid, force: options.force, dryRun: options.dryRun)

                switch result {
                case .dryRun(let signal):
                    print("mxkill: would send signal \(signal) to \(target.processName) [pid \(target.pid)]")
                case .sent(let signal):
                    print("mxkill: sent signal \(signal) to \(target.processName) [pid \(target.pid)]")
                }

                return 0
            } catch {
                fputs("mxkill: \(error)\n", stderr)
                return 1
            }
        }
    }
}
```

Confirm `Sources/mxkill/main.swift` remains:

```swift
import mxkillCore

exit(MXKill.run(arguments: Array(CommandLine.arguments.dropFirst())))
```

- [ ] **Step 2: Build release binary**

Run:

```bash
swift build -c release
```

Expected: PASS and `.build/release/mxkill` exists.

- [ ] **Step 3: Run automated tests**

Run:

```bash
swift test
```

Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add Sources/mxkillCore/MXKill.swift Sources/mxkill/main.swift
git commit -m "Wire mxkill executable"
```

## Task 7: Manual macOS Verification

**Files:**
- Modify: `docs/superpowers/specs/2026-06-08-mxkill-design.md` only if verification discovers a documented behavior needs correction.

- [ ] **Step 1: Verify invalid arguments**

Run:

```bash
.build/release/mxkill --bogus
```

Expected: exits non-zero and prints `unknown option: --bogus` plus usage.

- [ ] **Step 2: Verify permission path**

Run:

```bash
.build/release/mxkill --dry-run --timeout 1
```

Expected if permission is missing: prints Accessibility instructions and exits non-zero.

Expected if permission is granted: enters picker mode and exits with timeout after 1 second.

- [ ] **Step 3: Verify dry run against a disposable app**

Open TextEdit or another disposable app window, then run:

```bash
.build/release/mxkill --dry-run --timeout 15
```

Click the disposable app window.

Expected: prints `would send signal 15` with the app name and PID. The app remains running.

- [ ] **Step 4: Verify cancellation**

Run:

```bash
.build/release/mxkill --timeout 15
```

Press Escape or right click.

Expected: prints `mxkill: cancelled` and does not terminate an app.

- [ ] **Step 5: Verify default termination**

Open a disposable app or helper process with a visible window, then run:

```bash
.build/release/mxkill --timeout 15
```

Click the disposable app window.

Expected: prints `sent signal 15` and the selected app exits or begins its normal termination flow.

- [ ] **Step 6: Verify force termination**

Open a disposable app or helper process with a visible window, then run:

```bash
.build/release/mxkill --force --timeout 15
```

Click the disposable app window.

Expected: prints `sent signal 9` and the selected app is killed.

- [ ] **Step 7: Commit verification documentation if changed**

If no docs changed:

```bash
git status --short
```

Expected: clean working tree.

If docs changed:

```bash
git add docs/superpowers/specs/2026-06-08-mxkill-design.md
git commit -m "Update mxkill design after verification"
```

## Self-Review

- Spec coverage: Tasks cover SwiftPM packaging, CLI flags, Accessibility permission handling, click selection, hit testing, signal sending, safety checks, cancellation, timeout, automated tests, and manual OS verification.
- Red-flag scan: The plan uses concrete steps, commands, and code blocks throughout.
- Type consistency: `Options`, `TargetSafety`, `SignalSender`, `ClickPicker`, `AccessibilityHitTester`, and `TargetProcess` names are consistent across tests, implementation snippets, and executable wiring.
