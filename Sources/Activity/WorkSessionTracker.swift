import Foundation

@Observable
@MainActor
class WorkSessionTracker {
    var sessionDuration: TimeInterval = 0
    var sessionStartTime: Date?
    var isInSession = false

    private var sessionTimer: Timer?
    private let idleThreshold: TimeInterval = 300 // 5 minutes idle = session end

    func startSession() {
        guard !isInSession else { return }
        isInSession = true
        sessionStartTime = Date()
        sessionDuration = 0

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
    }

    var formattedDuration: String {
        let minutes = Int(sessionDuration) / 60
        let seconds = Int(sessionDuration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
