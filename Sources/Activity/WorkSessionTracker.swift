import Foundation

@Observable
@MainActor
class WorkSessionTracker {
    var sessionDuration: TimeInterval = 0
    var sessionStartTime: Date?
    var isInSession = false

    // Break tracking
    var breaksDue: Int = 0  // Number of breaks that should have been taken
    var onBreakDue: ((Int, TimeInterval) async -> Void)?  // (breakNumber, sessionDuration)

    // Session end tracking
    var sessionEndNotified: Bool = false
    var onSessionEnd: ((TimeInterval) async -> Void)?  // Called when session duration reached

    private var sessionTimer: Timer?
    private let idleThreshold: TimeInterval = 300 // 5 minutes idle = session end

    func startSession() {
        guard !isInSession else { return }
        isInSession = true
        sessionStartTime = Date()
        sessionDuration = 0
        breaksDue = 0  // Reset breaks for new session
        sessionEndNotified = false  // Reset session end notification

        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateSessionDuration()
            }
        }
    }

    func endSession() {
        isInSession = false
        sessionTimer?.invalidate()
        sessionTimer = nil
    }

    func checkIdleTime(_ idleTime: TimeInterval) {
        if idleTime >= idleThreshold && isInSession {
            endSession()
        } else if idleTime < idleThreshold && !isInSession {
            startSession()
        }
    }

    private func updateSessionDuration() {
        guard let start = sessionStartTime else { return }
        sessionDuration = Date().timeIntervalSince(start)
        checkBreakTime()
        checkSessionEnd()
    }

    private func checkBreakTime() {
        let prefs = PreferencesStore.shared
        guard prefs.enableBreakReminders else { return }

        let interval = TimeInterval(prefs.breakIntervalMinutes * 60)
        guard interval > 0 else { return }

        let expectedBreaks = Int(sessionDuration / interval)

        // Trigger callback if we've crossed a new break threshold
        if expectedBreaks > breaksDue {
            breaksDue = expectedBreaks
            let minutes = Int(sessionDuration / 60)
            print("⏰ Break #\(breaksDue) due after \(minutes) minutes")

            Task {
                await onBreakDue?(breaksDue, sessionDuration)
            }
        }
    }

    private func checkSessionEnd() {
        let prefs = PreferencesStore.shared
        guard !sessionEndNotified else { return }

        let sessionLimit = TimeInterval(prefs.sessionDurationMinutes * 60)
        guard sessionLimit > 0 else { return }

        // Notify when session duration is reached
        if sessionDuration >= sessionLimit {
            sessionEndNotified = true
            let minutes = Int(sessionDuration / 60)
            print("🏁 Session complete after \(minutes) minutes")

            Task {
                await onSessionEnd?(sessionDuration)
            }
        }
    }

    var formattedDuration: String {
        let minutes = Int(sessionDuration) / 60
        let seconds = Int(sessionDuration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
