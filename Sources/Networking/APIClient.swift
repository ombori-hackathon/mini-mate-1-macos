import Foundation

actor APIClient {
    static let shared = APIClient()

    private let baseURL = URL(string: "http://localhost:8000")!
    private let session = URLSession.shared
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        return decoder
    }()
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        return encoder
    }()

    // Device ID (persistent per machine)
    let deviceId: String = {
        // Use machine's hardware UUID for consistent device identification
        let task = Process()
        task.launchPath = "/usr/sbin/ioreg"
        task.arguments = ["-rd1", "-c", "IOPlatformExpertDevice"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8),
           let range = output.range(of: "IOPlatformUUID\" = \""),
           let endRange = output[range.upperBound...].firstIndex(of: "\"") {
            return String(output[range.upperBound..<endRange])
        }
        return UUID().uuidString
    }()

    // Health check
    func checkHealth() async throws -> Bool {
        let url = baseURL.appendingPathComponent("health")
        let (data, _) = try await session.data(from: url)
        let response = try decoder.decode(HealthResponse.self, from: data)
        return response.status == "healthy"
    }

    // Get pending hints
    func getPendingHints() async throws -> [Hint] {
        let url = baseURL.appendingPathComponent("hints/\(deviceId)/pending")
        let (data, _) = try await session.data(from: url)
        let response = try decoder.decode(PendingHintsResponse.self, from: data)
        return response.hints
    }

    // Update hint status
    func updateHintStatus(hintId: Int, status: HintStatus) async throws {
        let url = baseURL.appendingPathComponent("hints/\(hintId)/status")
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["status": status.rawValue]
        request.httpBody = try encoder.encode(body)
        let _ = try await session.data(for: request)
    }

    // Report activity
    func reportActivity(_ activities: [ActivityReportItem]) async throws {
        let url = baseURL.appendingPathComponent("activities/report")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let report = ActivityBatchReport(deviceId: deviceId, activities: activities)
        request.httpBody = try encoder.encode(report)
        let _ = try await session.data(for: request)
    }

    // Send event reminder to generate AI hint
    func sendEventReminder(_ event: ScheduledEvent) async throws {
        let url = baseURL.appendingPathComponent("events/reminder")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "device_id": deviceId,
            "event_title": event.title,
            "event_time": ISO8601DateFormatter().string(from: event.time)
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let _ = try await session.data(for: request)
    }

    // Update user preferences
    func updatePreferences(
        workSessionMinutes: Int,
        maxHintsPerHour: Int,
        enableBreakReminders: Bool,
        enableWorkflowTips: Bool,
        enableAppSuggestions: Bool
    ) async throws {
        let url = baseURL.appendingPathComponent("preferences/\(deviceId)")
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "work_session_minutes": workSessionMinutes,
            "max_hints_per_hour": maxHintsPerHour,
            "enable_break_reminders": enableBreakReminders,
            "enable_workflow_tips": enableWorkflowTips,
            "enable_app_suggestions": enableAppSuggestions
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let _ = try await session.data(for: request)
    }

    // Send time-based trigger for hints
    func sendTimeTrigger(
        triggerType: String,
        appName: String?,
        windowTitle: String?,
        durationMinutes: Double,
        breakNumber: Int?,
        recentWindows: [String]?
    ) async throws {
        let url = baseURL.appendingPathComponent("hints/time-trigger")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = [
            "device_id": deviceId,
            "trigger_type": triggerType,
            "duration_minutes": durationMinutes
        ]

        if let appName = appName {
            body["app_name"] = appName
        }
        if let windowTitle = windowTitle {
            body["window_title"] = windowTitle
        }
        if let breakNumber = breakNumber {
            body["break_number"] = breakNumber
        }
        if let recentWindows = recentWindows {
            body["recent_windows"] = recentWindows
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let _ = try await session.data(for: request)
    }
}
