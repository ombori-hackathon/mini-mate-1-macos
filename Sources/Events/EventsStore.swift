import Foundation
import SwiftUI

@Observable
@MainActor
class EventsStore {
    static let shared = EventsStore()

    var events: [ScheduledEvent] = [] {
        didSet { save() }
    }

    private let eventsKey = "scheduled_events"

    private init() {
        load()
    }

    func addEvent(_ event: ScheduledEvent) {
        events.append(event)
        events.sort { $0.time < $1.time }
    }

    func removeEvent(_ event: ScheduledEvent) {
        events.removeAll { $0.id == event.id }
    }

    func updateEvent(_ event: ScheduledEvent) {
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index] = event
            events.sort { $0.time < $1.time }
        }
    }

    // Get events that need reminders now (at their scheduled time)
    func getUpcomingReminders() -> [ScheduledEvent] {
        events.filter { $0.isTimeToRemind && !$0.isPast }
    }

    // Get today's events
    func getTodayEvents() -> [ScheduledEvent] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        return events.filter { event in
            event.time >= today && event.time < tomorrow
        }
    }

    // Clean up past events (older than today)
    func cleanupPastEvents() {
        let today = Calendar.current.startOfDay(for: Date())
        events.removeAll { $0.time < today }
    }

    private func save() {
        if let encoded = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(encoded, forKey: eventsKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: eventsKey),
           let decoded = try? JSONDecoder().decode([ScheduledEvent].self, from: data) {
            events = decoded
            cleanupPastEvents()
        }
    }
}
