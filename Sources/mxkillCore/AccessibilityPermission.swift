import ApplicationServices
import Foundation

public enum AccessibilityPermission {
    public static func isTrusted(prompt: Bool) -> Bool {
        let options = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt
        ] as CFDictionary

        return AXIsProcessTrustedWithOptions(options)
    }

    public static let instructions = """
    mxkill needs Accessibility permission to identify the window you click.
    Open System Settings > Privacy & Security > Accessibility and enable your terminal app, then run mxkill again.
    """
}
