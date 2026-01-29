import AppKit
import Quartz

@Observable
@MainActor
class SystemEventObserver {
    var isFullScreenAppActive = false
    var isSystemIdle = false
    var isSystemSleeping = false

    private var fullScreenCheckTimer: Timer?

    func startObserving() {
        // Observe sleep/wake
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(systemWillSleep),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(systemDidWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )

        // Observe screen lock
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(screenLocked),
            name: NSNotification.Name("com.apple.screenIsLocked"),
            object: nil
        )

        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(screenUnlocked),
            name: NSNotification.Name("com.apple.screenIsUnlocked"),
            object: nil
        )

        // Check for full-screen apps periodically
        fullScreenCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkFullScreenApp()
            }
        }
    }

    func stopObserving() {
        fullScreenCheckTimer?.invalidate()
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        DistributedNotificationCenter.default().removeObserver(self)
    }

    @objc private func systemWillSleep(_ notification: Notification) {
        isSystemSleeping = true
    }

    @objc private func systemDidWake(_ notification: Notification) {
        isSystemSleeping = false
    }

    @objc private func screenLocked(_ notification: Notification) {
        isSystemIdle = true
    }

    @objc private func screenUnlocked(_ notification: Notification) {
        isSystemIdle = false
    }

    private func checkFullScreenApp() {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else {
            isFullScreenAppActive = false
            return
        }

        // Check if the frontmost app has a full-screen window
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            isFullScreenAppActive = false
            return
        }

        for window in windowList {
            guard let ownerPID = window[kCGWindowOwnerPID as String] as? Int32,
                  ownerPID == frontApp.processIdentifier,
                  let bounds = window[kCGWindowBounds as String] as? [String: CGFloat] else {
                continue
            }

            let windowWidth = bounds["Width"] ?? 0
            let windowHeight = bounds["Height"] ?? 0

            // Check if window matches screen size (indicating full-screen)
            for screen in NSScreen.screens {
                if abs(windowWidth - screen.frame.width) < 10 &&
                   abs(windowHeight - screen.frame.height) < 10 {
                    isFullScreenAppActive = true
                    return
                }
            }
        }

        isFullScreenAppActive = false
    }
}
