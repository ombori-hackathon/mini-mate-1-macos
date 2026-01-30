import AppKit

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var companionController: CompanionWindowController?
    var hintService = HintService()
    var activityMonitor = ActivityMonitor()
    var workSessionTracker = WorkSessionTracker()
    var animationEngine = AnimationEngine()
    var systemEventObserver = SystemEventObserver()
    var eventReminderService = EventReminderService.shared
    var preferences = PreferencesStore.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Check/request accessibility permission
        if preferences.enableActivityTracking {
            _ = PermissionManager.shared.checkAndRequestIfNeeded()
        }

        // Create companion window with animation engine
        let companionView = CompanionView(
            hintService: hintService,
            animationEngine: animationEngine
        )
        companionController = CompanionWindowController(companionView: companionView)

        // Show on startup based on preference
        if preferences.showOnStartup {
            companionController?.show()
        }

        // Start services
        hintService.startPolling()

        if preferences.enableActivityTracking {
            activityMonitor.startMonitoring()

            // Fetch hints immediately on app switch
            activityMonitor.onAppSwitch = { [weak self] in
                await self?.hintService.fetchHintsNow()
            }

            // Same-app duration hint trigger
            activityMonitor.onSameAppThreshold = { [weak self] appName, duration in
                guard let self else { return }
                do {
                    try await APIClient.shared.sendTimeTrigger(
                        triggerType: "same_app_duration",
                        appName: appName,
                        windowTitle: self.activityMonitor.activeWindowTitle,
                        durationMinutes: duration / 60,
                        breakNumber: nil,
                        recentWindows: Array(self.activityMonitor.recentWindowTitles.prefix(5))
                    )
                    // Small delay then fetch hints
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    await self.hintService.fetchHintsNow()
                } catch {
                    print("Failed to send same-app trigger: \(error)")
                }
            }
        }

        workSessionTracker.startSession()

        // Break reminder trigger
        workSessionTracker.onBreakDue = { [weak self] breakNumber, duration in
            guard let self else { return }
            do {
                try await APIClient.shared.sendTimeTrigger(
                    triggerType: "break_reminder",
                    appName: nil,
                    windowTitle: nil,
                    durationMinutes: duration / 60,
                    breakNumber: breakNumber,
                    recentWindows: nil
                )
                // Small delay then fetch hints
                try? await Task.sleep(nanoseconds: 500_000_000)
                await self.hintService.fetchHintsNow()
            } catch {
                print("Failed to send break reminder: \(error)")
            }
        }

        // Session end trigger
        workSessionTracker.onSessionEnd = { [weak self] duration in
            guard let self else { return }
            do {
                try await APIClient.shared.sendTimeTrigger(
                    triggerType: "session_end",
                    appName: nil,
                    windowTitle: nil,
                    durationMinutes: duration / 60,
                    breakNumber: nil,
                    recentWindows: nil
                )
                // Small delay then fetch hints
                try? await Task.sleep(nanoseconds: 500_000_000)
                await self.hintService.fetchHintsNow()
            } catch {
                print("Failed to send session end: \(error)")
            }
        }
        systemEventObserver.startObserving()

        // Connect event reminder to hint fetching
        eventReminderService.onReminderSent = { [weak self] in
            await self?.hintService.fetchHintsNow()
        }
        eventReminderService.startMonitoring()

        // Sync preferences with API
        syncPreferencesWithAPI()

        // Connect activity monitor to session tracker and check system state
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.workSessionTracker.checkIdleTime(self.activityMonitor.idleTime)
                self.handleSystemState()
            }
        }
    }

    private func syncPreferencesWithAPI() {
        Task {
            do {
                try await APIClient.shared.updatePreferences(
                    workSessionMinutes: preferences.workSessionMinutes,
                    maxHintsPerHour: preferences.maxHintsPerHour,
                    enableBreakReminders: preferences.enableBreakReminders,
                    enableWorkflowTips: preferences.enableWorkflowTips,
                    enableAppSuggestions: preferences.enableAppTips
                )
            } catch {
                print("Failed to sync preferences: \(error)")
            }
        }
    }

    private func handleSystemState() {
        // Hide companion during full-screen apps or system sleep
        if systemEventObserver.isFullScreenAppActive ||
           systemEventObserver.isSystemSleeping ||
           systemEventObserver.isSystemIdle {
            companionController?.hide()
            activityMonitor.stopMonitoring()
            animationEngine.setState(.sleeping)
        } else if companionController?.window?.isVisible == false {
            companionController?.show()
            activityMonitor.startMonitoring()
            animationEngine.setState(.idle)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        hintService.stopPolling()
        activityMonitor.stopMonitoring()
        workSessionTracker.endSession()
        systemEventObserver.stopObserving()
        eventReminderService.stopMonitoring()
    }

    func toggleCompanion() {
        companionController?.toggle()
    }
}
