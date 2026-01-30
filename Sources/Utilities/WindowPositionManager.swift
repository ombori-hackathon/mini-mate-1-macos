import AppKit

@MainActor
class WindowPositionManager {
    private let userDefaultsKey = "companionWindowPosition"

    func savePosition(_ window: NSWindow) {
        let origin = window.frame.origin
        let position = ["x": origin.x, "y": origin.y]
        UserDefaults.standard.set(position, forKey: userDefaultsKey)
    }

    func restorePosition(_ window: NSWindow) {
        guard let position = UserDefaults.standard.dictionary(forKey: userDefaultsKey),
              let x = position["x"] as? CGFloat,
              let y = position["y"] as? CGFloat else {
            // Default to bottom-right of main screen
            positionInBottomRight(window)
            return
        }

        let point = CGPoint(x: x, y: y)

        // Verify the position is still on a valid screen
        if let screen = ScreenManager.shared.screenContaining(point: point) {
            let screenFrame = screen.visibleFrame
            // Ensure window is fully visible
            let newX = max(screenFrame.minX, min(point.x, screenFrame.maxX - window.frame.width))
            let newY = max(screenFrame.minY, min(point.y, screenFrame.maxY - window.frame.height))
            window.setFrameOrigin(CGPoint(x: newX, y: newY))
        } else {
            positionInBottomRight(window)
        }
    }

    func positionInBottomRight(_ window: NSWindow) {
        guard let screen = ScreenManager.shared.mainScreen else { return }
        let screenFrame = screen.visibleFrame
        let x = screenFrame.maxX - window.frame.width - 20
        let y = screenFrame.minY + 20
        window.setFrameOrigin(CGPoint(x: x, y: y))
    }
}
