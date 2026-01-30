import Foundation

struct ActivityReportItem: Codable {
    let appName: String
    let windowTitle: String?      // File name, URL, document title
    let startedAt: String
    let endedAt: String?
    let durationSeconds: Double?
    let idleSeconds: Double?      // Time user has been idle
    let mightBeStuck: Bool?       // Stuck detection flag

    // App switch tracking
    var isAppSwitch: Bool? = nil
    var appSwitchCount: Int? = nil
    var sessionMinutes: Double? = nil

    // Struggle detection
    var struggleScore: Int? = nil       // 0-10, higher = more likely struggling
    var tabSwitchCount: Int? = nil      // Tab switches within same app
    var backAndForthCount: Int? = nil   // Switching between same 2 apps
    var context: String? = nil          // Full context string for AI
    var recentWindows: [String]? = nil  // Recent window titles

    enum CodingKeys: String, CodingKey {
        case appName = "app_name"
        case windowTitle = "window_title"
        case startedAt = "started_at"
        case endedAt = "ended_at"
        case durationSeconds = "duration_seconds"
        case idleSeconds = "idle_seconds"
        case mightBeStuck = "might_be_stuck"
        case isAppSwitch = "is_app_switch"
        case appSwitchCount = "app_switch_count"
        case sessionMinutes = "session_minutes"
        case struggleScore = "struggle_score"
        case tabSwitchCount = "tab_switch_count"
        case backAndForthCount = "back_and_forth_count"
        case context = "context"
        case recentWindows = "recent_windows"
    }
}

struct ActivityBatchReport: Codable {
    let deviceId: String
    let activities: [ActivityReportItem]

    enum CodingKeys: String, CodingKey {
        case deviceId = "device_id"
        case activities
    }
}
