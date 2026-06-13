import Foundation

public enum ScreenGeometry {
    public static func accessibilityPoint(forAppKitPoint appKitPoint: CGPoint, screens: [CGRect]) -> CGPoint? {
        guard let primaryScreen = screens.first,
              screens.contains(where: { $0.containsAppKitPoint(appKitPoint) })
        else {
            return nil
        }

        return CGPoint(
            x: appKitPoint.x,
            y: primaryScreen.maxY - appKitPoint.y
        )
    }

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
}

private extension CGRect {
    func containsAppKitPoint(_ point: CGPoint) -> Bool {
        point.x >= minX &&
            point.x < maxX &&
            point.y >= minY &&
            point.y < maxY
    }
}
