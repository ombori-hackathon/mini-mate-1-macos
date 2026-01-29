import Foundation

struct ScheduledEvent: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var time: Date

    init(id: UUID = UUID(), title: String, time: Date) {
        self.id = id
        self.title = title
        self.time = time
    }

    // Check if it's time to show this reminder (within 1 minute of scheduled time)
    var isTimeToRemind: Bool {
        let now = Date()
        let diff = time.timeIntervalSince(now)
        return diff >= -60 && diff <= 60  // Within 1 minute window
    }

    var isPast: Bool {
        Date() > time.addingTimeInterval(60)  // Past the 1 minute window
    }

    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: time)
    }
}
