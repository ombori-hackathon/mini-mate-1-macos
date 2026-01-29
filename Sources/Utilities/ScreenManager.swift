import AppKit

@MainActor
class ScreenManager {
    static let shared = ScreenManager()

    var allScreens: [NSScreen] { NSScreen.screens }
    var mainScreen: NSScreen? { NSScreen.main }

    func screenContaining(point: CGPoint) -> NSScreen? {
        allScreens.first { NSPointInRect(point, $0.frame) }
    }

    func screenContaining(window: NSWindow) -> NSScreen? {
        window.screen
    }

    func activeScreen() -> NSScreen? {
        // Return screen with mouse cursor
        let mouseLocation = NSEvent.mouseLocation
        return screenContaining(point: mouseLocation) ?? mainScreen
    }
}
