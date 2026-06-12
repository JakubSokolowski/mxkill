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
