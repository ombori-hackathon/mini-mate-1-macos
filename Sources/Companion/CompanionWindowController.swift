import AppKit
import SwiftUI

class CompanionWindowController: NSWindowController {
    private let positionManager = WindowPositionManager()

    convenience init(companionView: some View) {
        // Wrap in a view that ensures transparent background
        let wrappedView = companionView
            .background(Color.clear)

        let hostingView = NSHostingView(rootView: AnyView(wrappedView))
        hostingView.layer?.backgroundColor = .clear

        // Use NSPanel instead of NSWindow - panels can float over full-screen apps
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 250, height: 280),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.contentView = hostingView
        panel.isOpaque = false
        panel.backgroundColor = .clear

        // Highest possible window level to stay above everything including full-screen
        panel.level = .screenSaver

        // Panel-specific settings for floating behavior
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.worksWhenModal = true

        // Collection behavior for full-screen support
        panel.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .ignoresCycle
        ]

        panel.isMovableByWindowBackground = true
        panel.hasShadow = false
        panel.ignoresMouseEvents = false

        // Allow panel to receive mouse events even when app is not active
        panel.acceptsMouseMovedEvents = true

        self.init(window: panel)

        // Restore saved position
        positionManager.restorePosition(panel)

        // Observe window movement
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidMove),
            name: NSWindow.didMoveNotification,
            object: panel
        )

        // Observe screen configuration changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        // Observe active space changes to follow user
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(activeSpaceDidChange),
            name: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil
        )
    }

    @objc private func windowDidMove(_ notification: Notification) {
        constrainToScreen()
        // Save position after drag
        if let window = window {
            positionManager.savePosition(window)
        }
    }

    @objc private func screensDidChange(_ notification: Notification) {
        // Re-validate position when screens change
        if let window = window {
            positionManager.restorePosition(window)
        }
    }

    @objc private func activeSpaceDidChange(_ notification: Notification) {
        // When user switches to a new space (including full-screen), bring window to front
        guard let window = window else { return }

        // Re-order the window to ensure it's visible on the new space
        window.orderFrontRegardless()

        // Ensure window level is maintained at screenSaver level
        window.level = .screenSaver
    }

    func constrainToScreen() {
        guard let window = window, let screen = window.screen ?? NSScreen.main else { return }

        var frame = window.frame
        // Use full screen frame to allow positioning anywhere (including over menu bar/dock)
        let screenFrame = screen.frame

        frame.origin.x = max(screenFrame.minX, min(frame.origin.x, screenFrame.maxX - frame.width))
        frame.origin.y = max(screenFrame.minY, min(frame.origin.y, screenFrame.maxY - frame.height))

        if frame != window.frame {
            window.setFrame(frame, display: true)
        }
    }

    func moveToScreen(_ screen: NSScreen) {
        guard let window = window else { return }
        let screenFrame = screen.frame
        let newOrigin = CGPoint(
            x: screenFrame.maxX - window.frame.width - 20,
            y: screenFrame.minY + 20
        )
        window.setFrameOrigin(newOrigin)
        positionManager.savePosition(window)
    }

    func show() {
        window?.makeKeyAndOrderFront(nil)
    }

    func hide() {
        window?.orderOut(nil)
    }

    func toggle() {
        if window?.isVisible == true {
            hide()
        } else {
            show()
        }
    }
}
