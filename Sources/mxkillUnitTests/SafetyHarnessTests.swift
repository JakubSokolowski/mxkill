import Foundation
import mxkillCore

func testRejectsZeroPid() {
    expectThrows("refusing to signal invalid pid 0", "zero pid rejection") {
        try TargetSafety.validate(pid: 0, currentPid: 123, includeSelf: false)
    }
}

func testRejectsNegativePid() {
    expectThrows("refusing to signal invalid pid -1", "negative pid rejection") {
        try TargetSafety.validate(pid: -1, currentPid: 123, includeSelf: false)
    }
}

func testRejectsSelfByDefault() {
    expectThrows("refusing to signal mxkill itself; pass --include-self to allow it", "self pid rejection") {
        try TargetSafety.validate(pid: 123, currentPid: 123, includeSelf: false)
    }
}

func testAllowsSelfWhenExplicitlyRequested() throws {
    try TargetSafety.validate(pid: 123, currentPid: 123, includeSelf: true)
}
