import Foundation
import AppKit

@MainActor
class PermissionManager {
    static let shared = PermissionManager()

    var hasAccessibilityPermission: Bool {
        AXIsProcessTrusted()
    }

    func requestAccessibilityPermission() {
        let promptKey = "AXTrustedCheckOptionPrompt"
        let options = [promptKey: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    func checkAndRequestIfNeeded() -> Bool {
        if hasAccessibilityPermission {
            return true
        }
        requestAccessibilityPermission()
        return false
    }
}
