import Foundation

struct ScheduledEvent: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var time: Date
    var notes: String?
    var reminderMinutesBefore: Int

    init(id: UUID = UUID(), title: String, time: Date, notes: String? = nil, reminderMinutesBefore: Int = 5) {
        self.id = id
        self.title = title
        self.time = time
        self.notes = notes
        self.reminderMinutesBefore = reminderMinutesBefore
    }

    // Custom decoder to handle old events without new fields
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        time = try container.decode(Date.self, forKey: .time)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        reminderMinutesBefore = try container.decodeIfPresent(Int.self, forKey: .reminderMinutesBefore) ?? 5
    }

    enum CodingKeys: String, CodingKey {
        case id, title, time, notes, reminderMinutesBefore
    }

    // Check if it's time to show this reminder (based on reminderMinutesBefore)
    var isTimeToRemind: Bool {
        let now = Date()
        let reminderTime = time.addingTimeInterval(-Double(reminderMinutesBefore * 60))
        let diff = reminderTime.timeIntervalSince(now)
        return diff >= -60 && diff <= 60  // Within 1 minute of reminder time
    }

    // Check if event is coming up soon (within 15 minutes)
    var isUpcoming: Bool {
        let now = Date()
        let diff = time.timeIntervalSince(now)
        return diff > 60 && diff <= 900  // Between 1 and 15 minutes
    }

    var isPast: Bool {
        Date() > time.addingTimeInterval(60)  // Past the event time + 1 minute
    }

    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: time)
    }
}
