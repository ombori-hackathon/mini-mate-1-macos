import Foundation

@Observable
@MainActor
class EventReminderService {
    static let shared = EventReminderService()

    private var checkTimer: Timer?
    private var remindedEventIds: Set<UUID> = []

    // Callback to fetch hints immediately after reminder is sent
    var onReminderSent: (() async -> Void)?

    private init() {}

    func startMonitoring() {
        print("📅 Event scheduler started - checking every 10 seconds")

        // Check every 10 seconds for events at their scheduled time
        checkTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.checkForReminders()
            }
        }

        // Initial check
        Task {
            await checkForReminders()
        }
    }

    func stopMonitoring() {
        checkTimer?.invalidate()
        checkTimer = nil
        print("📅 Event scheduler stopped")
    }

    func checkForReminders() async {
        let eventsStore = EventsStore.shared
        let upcomingCount = eventsStore.events.filter { !$0.isPast }.count

        if upcomingCount > 0 {
            print("📅 Checking \(upcomingCount) scheduled events...")
        }

        for event in eventsStore.events {
            // Skip if already reminded or not time yet
            guard !remindedEventIds.contains(event.id),
                  event.isTimeToRemind else { continue }

            print("⏰ EVENT NOW: \(event.title) at \(event.timeString)")

            // Send reminder to API - AI will generate the message
            do {
                try await APIClient.shared.sendEventReminder(event)
                remindedEventIds.insert(event.id)
                print("✅ Reminder sent for: \(event.title)")

                // Fetch hints immediately to show the reminder
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 sec
                await onReminderSent?()
            } catch {
                print("❌ Failed to send event reminder: \(error)")
            }
        }

        // Clean up past events from reminded set
        eventsStore.cleanupPastEvents()
        let currentEventIds = Set(eventsStore.events.map { $0.id })
        remindedEventIds = remindedEventIds.intersection(currentEventIds)
    }

    // Reset reminders (for testing)
    func resetReminders() {
        remindedEventIds.removeAll()
        print("📅 Reminders reset")
    }
}
