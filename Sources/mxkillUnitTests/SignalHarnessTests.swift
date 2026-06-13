import Darwin
import Foundation
import mxkillCore

func testUsesSigtermByDefault() {
    expectEqual(SignalSender.signal(force: false), SIGTERM, "default signal")
}

func testUsesSigkillWhenForced() {
    expectEqual(SignalSender.signal(force: true), SIGKILL, "forced signal")
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

    expectEqual(result, .dryRun(signal: SIGKILL), "dry-run signal result")
    expect(calls.isEmpty, "dry-run does not call kill")
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

    expectEqual(result, .sent(signal: SIGTERM), "sent signal result")
    expectEqual(calls.count, 1, "kill call count")
    expectEqual(calls.first?.0, 999, "kill pid")
    expectEqual(calls.first?.1, SIGTERM, "kill signal")
}

func testThrowsWhenKillFunctionFails() {
    do {
        _ = try SignalSender.send(
            pid: 999,
            force: false,
            dryRun: false,
            killFunction: { _, _ in
                errno = ESRCH
                return -1
            }
        )
        fail("failed kill should throw")
    } catch {
        expect(String(describing: error).contains("failed to signal pid 999"), "failed kill error includes pid")
        expectEqual(error as? SignalSenderError, SignalSenderError.signalFailed(pid: 999, errnoCode: ESRCH), "failed kill error captures errno")
    }
}
