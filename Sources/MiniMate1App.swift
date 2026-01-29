import SwiftUI
import AppKit

@main
struct MiniMate1App: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    var body: some Scene {
        Settings {
            SettingsView()
        }

        MenuBarExtra("MiniMate", systemImage: "face.smiling") {
            Button("Show/Hide Companion") {
                appDelegate.toggleCompanion()
            }
            .keyboardShortcut("m", modifiers: [.command, .shift])

            Divider()

            Text("Session: \(appDelegate.workSessionTracker.formattedDuration)")
                .font(.caption)

            if appDelegate.systemEventObserver.isFullScreenAppActive {
                Text("Full-screen mode detected")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            Button("Settings...") {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
            .keyboardShortcut(",", modifiers: .command)

            Button("Reset Position") {
                if let screen = ScreenManager.shared.mainScreen {
                    appDelegate.companionController?.moveToScreen(screen)
                }
            }

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}
