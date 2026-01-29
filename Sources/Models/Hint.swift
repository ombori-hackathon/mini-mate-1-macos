import Foundation

enum HintCategory: String, Codable {
    case breakReminder = "break_reminder"
    case appSuggestion = "app_suggestion"
    case workflowTip = "workflow_tip"
    case focusAlert = "focus_alert"
    case eventReminder = "event_reminder"
}

enum HintPriority: String, Codable {
    case low, medium, high
}

enum HintStatus: String, Codable {
    case pending, shown, dismissed
}

struct Hint: Codable, Identifiable {
    let id: Int
    let deviceId: String
    let category: HintCategory
    let priority: HintPriority
    let title: String
    let message: String
    let status: HintStatus
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case deviceId = "device_id"
        case category, priority, title, message, status
        case createdAt = "created_at"
    }
}

struct PendingHintsResponse: Codable {
    let hints: [Hint]
    let count: Int
}
