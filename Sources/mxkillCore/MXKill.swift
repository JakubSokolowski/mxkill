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

        let picker = ClickPicker()
        let pickResult = picker.pick(timeoutSeconds: options.timeoutSeconds)

        switch pickResult {
        case .cancelled:
            print("mxkill: cancelled")
            return 0
        case .timedOut:
            fputs("mxkill: timed out waiting for click\n", stderr)
            return 70
        case .failedToInstallMonitor:
            fputs("mxkill: failed to install click monitor; check Accessibility permission and try again\n", stderr)
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
