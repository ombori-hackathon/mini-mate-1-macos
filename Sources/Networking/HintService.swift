import Foundation

@Observable
@MainActor
class HintService {
    var currentHint: Hint?
    var isConnected = false

    private var pollTimer: Timer?
    private var lastShownHintId: Int = 0
    private var preferences = PreferencesStore.shared

    func startPolling() {
        // Periodic polling as backup (app switches trigger immediate fetch)
        pollTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.fetchHints()
            }
        }
    }

    func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    /// Check if a hint category is enabled in user preferences
    private func isHintCategoryEnabled(_ category: HintCategory) -> Bool {
        switch category {
        case .breakReminder:
            return preferences.enableBreakReminders
        case .focusAlert:
            return preferences.enableFocusAlerts
        case .workflowTip:
            return preferences.enableWorkflowTips
        case .appSuggestion:
            return preferences.enableAppTips
        case .eventReminder:
            return true  // Always show event reminders
        }
    }

    /// Filter hints and dismiss disabled categories on server
    private func filterAndDismissDisabledHints(_ hints: [Hint]) async -> [Hint] {
        var enabledHints: [Hint] = []

        for hint in hints {
            if isHintCategoryEnabled(hint.category) {
                enabledHints.append(hint)
            } else {
                // Dismiss disabled hint types on server so they don't keep coming back
                Task {
                    try? await APIClient.shared.updateHintStatus(hintId: hint.id, status: .dismissed)
                }
            }
        }

        return enabledHints
    }

    func fetchHints() async {
        // Don't fetch if already showing a hint
        guard currentHint == nil else { return }

        do {
            let allHints = try await APIClient.shared.getPendingHints()
            self.isConnected = true

            // Filter by enabled categories and dismiss disabled ones
            let hints = await filterAndDismissDisabledHints(allHints)

            // Only show new hints (not ones we've already shown)
            if let hint = hints.first, hint.id != lastShownHintId {
                showHint(hint)
            }
        } catch {
            self.isConnected = false
        }
    }

    // Called immediately after app switch - shows hint instantly
    func fetchHintsNow() async {
        do {
            let allHints = try await APIClient.shared.getPendingHints()
            self.isConnected = true

            // Filter by enabled categories and dismiss disabled ones
            let hints = await filterAndDismissDisabledHints(allHints)

            // Show new hint, replacing current instantly
            if let hint = hints.first, hint.id != lastShownHintId {
                // Dismiss current hint instantly (no animation wait)
                if let current = currentHint {
                    Task { try? await APIClient.shared.updateHintStatus(hintId: current.id, status: .dismissed) }
                }
                // Replace immediately
                currentHint = nil
                // Tiny delay for smooth transition
                try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
                showHint(hint)
            }
        } catch {
            self.isConnected = false
        }
    }

    private func showHint(_ hint: Hint) {
        lastShownHintId = hint.id
        currentHint = hint

        // Mark as shown on server (fire and forget)
        Task {
            try? await APIClient.shared.updateHintStatus(hintId: hint.id, status: .shown)
        }
    }

    func dismissCurrentHint() {
        guard let hint = currentHint else { return }

        // Clear immediately for smooth UX
        currentHint = nil

        // Mark as dismissed on server (fire and forget)
        Task {
            try? await APIClient.shared.updateHintStatus(hintId: hint.id, status: .dismissed)
        }
    }
}
