import Foundation
import AppKit
import Quartz

@Observable
@MainActor
class ActivityMonitor {
    var activeAppName: String = ""
    var activeAppBundleId: String = ""
    var activeWindowTitle: String = ""
    var idleTime: TimeInterval = 0
    var isMonitoring = false

    // Stuck/struggle detection
    var timeOnCurrentTask: TimeInterval = 0
    var mightBeStuck: Bool = false
    var struggleScore: Int = 0  // Higher = more likely struggling

    // App switch tracking
    var appSwitchCount: Int = 0
    var recentApps: [String] = []

    // Context tracking for helpful hints
    var currentContext: String = ""  // What user is working on
    var recentWindowTitles: [String] = []  // Track window changes
    var tabSwitchCount: Int = 0  // Switches within same app
    var backAndForthCount: Int = 0  // Going between same 2 apps repeatedly

    // Rich context for AI hints
    var detectedSearchQuery: String = ""  // What user is searching for
    var detectedFileType: String = ""  // File extension if coding
    var detectedTopic: String = ""  // Main topic from titles
    var recentActivity: [String] = []  // Last 5 activities summary

    // Typing detection
    var isUserTyping: Bool = false  // True if user is actively typing
    var lastIdleTime: TimeInterval = 0  // Previous idle time for comparison
    var typingStartTime: Date?  // When user started typing

    // Callback when app switches - used to fetch hints immediately
    var onAppSwitch: (() async -> Void)?

    private var pollTimer: Timer?
    private var activityBuffer: [ActivityReportItem] = []
    private var lastAppChange: Date = Date()
    private var lastReportedApp: String = ""
    private var lastWindowTitle: String = ""
    private var windowTitleStartTime: Date = Date()
    private var stuckThreshold: TimeInterval = 120 // 2 minutes on same thing = might be stuck
    private var sessionStartTime: Date = Date()
    private var previousApp: String = ""
    private var appBeforePrevious: String = ""

    private let reportInterval: TimeInterval = 8 // Report every 8 sec

    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true

        // Initial state
        updateActiveApp()

        // Poll every second
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.poll()
            }
        }

        // Report activity periodically
        Timer.scheduledTimer(withTimeInterval: reportInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.reportActivity()
            }
        }
    }

    func stopMonitoring() {
        pollTimer?.invalidate()
        pollTimer = nil
        isMonitoring = false
    }

    private func poll() {
        updateIdleTime()
        updateActiveApp()
        updateWindowTitle()
        checkIfStuck()
    }

    private func updateIdleTime() {
        // Get time since last user input
        let seconds = CGEventSource.secondsSinceLastEventType(
            .hidSystemState,
            eventType: CGEventType(rawValue: ~0)!
        )

        // Detect if user is actively typing (idle time resets frequently)
        let wasTyping = isUserTyping
        isUserTyping = seconds < 2.0 && lastIdleTime > seconds  // Idle reset = user input

        if isUserTyping && !wasTyping {
            typingStartTime = Date()
        }

        lastIdleTime = idleTime
        idleTime = seconds
    }

    private func updateActiveApp() {
        guard PermissionManager.shared.hasAccessibilityPermission else { return }

        if let frontApp = NSWorkspace.shared.frontmostApplication {
            let appName = frontApp.localizedName ?? "Unknown"
            let bundleId = frontApp.bundleIdentifier ?? ""

            // Track app changes
            if appName != lastReportedApp {
                // Close previous activity
                if !lastReportedApp.isEmpty {
                    let duration = Date().timeIntervalSince(lastAppChange)
                    let item = ActivityReportItem(
                        appName: lastReportedApp,
                        windowTitle: lastWindowTitle,
                        startedAt: ISO8601DateFormatter().string(from: lastAppChange),
                        endedAt: ISO8601DateFormatter().string(from: Date()),
                        durationSeconds: duration,
                        idleSeconds: idleTime,
                        mightBeStuck: mightBeStuck
                    )
                    activityBuffer.append(item)
                }

                // Track app switch
                appSwitchCount += 1

                // Track back-and-forth (user switching between same 2 apps repeatedly)
                if appName == appBeforePrevious {
                    backAndForthCount += 1
                } else {
                    backAndForthCount = 0
                }
                appBeforePrevious = previousApp
                previousApp = appName

                // Reset tab switch count for new app
                tabSwitchCount = 0

                if !recentApps.contains(appName) {
                    recentApps.insert(appName, at: 0)
                    if recentApps.count > 10 {
                        recentApps.removeLast()
                    }
                }

                // Start tracking new app
                lastReportedApp = appName
                lastAppChange = Date()
                lastWindowTitle = ""
                windowTitleStartTime = Date()
                mightBeStuck = false

                // Report app switch immediately for instant hints!
                Task {
                    await reportAppSwitch(to: appName, bundleId: bundleId)
                }
            }

            activeAppName = appName
            activeAppBundleId = bundleId
        }
    }

    private func reportAppSwitch(to appName: String, bundleId: String) async {
        // Get fresh window title right before sending
        updateWindowTitle()

        // Build rich context
        buildContext()

        // Build detailed context string for AI
        var contextParts: [String] = []
        contextParts.append("Switched to: \(appName)")
        if !activeWindowTitle.isEmpty {
            contextParts.append("Current: \(activeWindowTitle)")
        }
        if !detectedSearchQuery.isEmpty {
            contextParts.append("Was searching: \(detectedSearchQuery)")
        }
        if !detectedTopic.isEmpty {
            contextParts.append("Topic: \(detectedTopic)")
        }
        if !detectedFileType.isEmpty {
            contextParts.append("Working on: \(detectedFileType) file")
        }
        if isUserTyping {
            contextParts.append("User is typing")
        }
        if let typingStart = typingStartTime {
            let typingMinutes = Int(Date().timeIntervalSince(typingStart) / 60)
            if typingMinutes > 0 {
                contextParts.append("Typing for: \(typingMinutes) min")
            }
        }
        if !recentActivity.isEmpty {
            contextParts.append("Recent: \(recentActivity.joined(separator: ", "))")
        }

        let richContext = contextParts.joined(separator: " | ")
        print("📤 \(appName): \(activeWindowTitle.prefix(40))")
        if !detectedSearchQuery.isEmpty {
            print("   🔍 Search: \(detectedSearchQuery)")
        }

        // Create activity report with full context for helpful AI hints
        let item = ActivityReportItem(
            appName: appName,
            windowTitle: activeWindowTitle,
            startedAt: ISO8601DateFormatter().string(from: Date()),
            endedAt: nil,
            durationSeconds: timeOnCurrentTask,
            idleSeconds: idleTime,
            mightBeStuck: mightBeStuck,
            isAppSwitch: true,
            appSwitchCount: appSwitchCount,
            sessionMinutes: Date().timeIntervalSince(sessionStartTime) / 60,
            struggleScore: struggleScore,
            tabSwitchCount: tabSwitchCount,
            backAndForthCount: backAndForthCount,
            context: richContext,
            recentWindows: Array(recentWindowTitles.prefix(8))
        )

        do {
            try await APIClient.shared.reportActivity([item])

            // Tiny delay for server to generate hint, then fetch immediately
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            await onAppSwitch?()
        } catch {
            // Silent fail
        }
    }

    private func updateWindowTitle() {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return }

        var title: String = ""

        // Method 1: Use CGWindowListCopyWindowInfo to get window titles (works for most apps including Electron)
        let pid = frontApp.processIdentifier
        if let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] {
            for window in windowList {
                if let windowPID = window[kCGWindowOwnerPID as String] as? Int32,
                   windowPID == pid {
                    // Try window name
                    if let windowName = window[kCGWindowName as String] as? String,
                       !windowName.isEmpty,
                       windowName != activeAppName {
                        title = windowName
                        break
                    }
                }
            }
        }

        // Debug: Print what we got for problem apps
        let debugApps = ["Cursor", "Code", "Visual Studio Code"]
        if debugApps.contains(activeAppName) && (title.isEmpty || title == activeAppName) {
            print("⚠️ \(activeAppName): Could not get window title (Electron limitation)")
        }

        // Method 2: If still empty, try Accessibility API
        if title.isEmpty && PermissionManager.shared.hasAccessibilityPermission {
            let appElement = AXUIElementCreateApplication(frontApp.processIdentifier)

            var focusedWindow: CFTypeRef?
            let result = AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focusedWindow)

            if result == .success, let window = focusedWindow {
                var titleValue: CFTypeRef?
                let titleResult = AXUIElementCopyAttributeValue(window as! AXUIElement, kAXTitleAttribute as CFString, &titleValue)
                if titleResult == .success, let t = titleValue as? String, !t.isEmpty {
                    title = t
                }

                // Try document attribute for code editors
                if title.isEmpty || title == activeAppName {
                    var docValue: CFTypeRef?
                    if AXUIElementCopyAttributeValue(window as! AXUIElement, kAXDocumentAttribute as CFString, &docValue) == .success,
                       let docPath = docValue as? String {
                        let filename = (docPath as NSString).lastPathComponent
                        if !filename.isEmpty {
                            title = filename
                        }
                    }
                }
            }
        }

        // Method 3: For browsers, try focused element
        if title.isEmpty && PermissionManager.shared.hasAccessibilityPermission {
            let browsers = ["Google Chrome", "Safari", "Arc", "Firefox", "Brave Browser", "Microsoft Edge"]
            if browsers.contains(activeAppName) {
                let appElement = AXUIElementCreateApplication(frontApp.processIdentifier)
                var focusedElement: CFTypeRef?
                if AXUIElementCopyAttributeValue(appElement, kAXFocusedUIElementAttribute as CFString, &focusedElement) == .success,
                   let element = focusedElement {
                    var desc: CFTypeRef?
                    if AXUIElementCopyAttributeValue(element as! AXUIElement, kAXDescriptionAttribute as CFString, &desc) == .success,
                       let d = desc as? String, !d.isEmpty {
                        title = d
                    }
                }
            }
        }

        // Update if we got a title
        if !title.isEmpty && title != lastWindowTitle {
            tabSwitchCount += 1
            recentWindowTitles.insert(title, at: 0)
            if recentWindowTitles.count > 10 {
                recentWindowTitles.removeLast()
            }
            lastWindowTitle = title
            windowTitleStartTime = Date()
            mightBeStuck = false
            struggleScore = 0
            activeWindowTitle = title
        } else if !title.isEmpty {
            activeWindowTitle = title
        }
    }

    private func checkIfStuck() {
        // Check if user has been on the same window for too long
        timeOnCurrentTask = Date().timeIntervalSince(windowTitleStartTime)

        let isWorkApp = ["Xcode", "Visual Studio Code", "Code", "Cursor", "PyCharm", "IntelliJ IDEA",
                         "WebStorm", "Android Studio", "Sublime Text", "Atom", "Terminal", "iTerm2", "Warp"].contains(activeAppName)

        let isBrowser = ["Safari", "Google Chrome", "Firefox", "Arc", "Brave Browser"].contains(activeAppName)

        // Calculate struggle score based on multiple factors
        struggleScore = 0

        // Factor 1: Time on same window (more time = higher score)
        if timeOnCurrentTask > 60 { struggleScore += 1 }
        if timeOnCurrentTask > 120 { struggleScore += 2 }
        if timeOnCurrentTask > 180 { struggleScore += 2 }

        // Factor 2: Back and forth between apps (searching for answers)
        if backAndForthCount > 3 { struggleScore += 2 }

        // Factor 3: Many tab switches in same app (looking for something)
        if tabSwitchCount > 5 { struggleScore += 1 }
        if tabSwitchCount > 10 { struggleScore += 2 }

        // Factor 4: Window title contains error/debug keywords
        let troubleKeywords = ["error", "Error", "ERROR", "failed", "Failed", "exception", "Exception",
                               "bug", "Bug", "debug", "Debug", "issue", "Issue", "problem", "fix",
                               "stackoverflow", "Stack Overflow", "google", "search"]
        let titleLower = activeWindowTitle.lowercased()
        for keyword in troubleKeywords {
            if titleLower.contains(keyword.lowercased()) {
                struggleScore += 2
                break
            }
        }

        // Factor 5: User is active but not making progress
        if idleTime < 30 && timeOnCurrentTask > stuckThreshold {
            struggleScore += 2
        }

        // Determine if stuck based on score
        mightBeStuck = struggleScore >= 4

        // Build context string for AI
        buildContext()
    }

    private func buildContext() {
        // Analyze recent window titles to extract useful context
        analyzeRecentActivity()

        var parts: [String] = []

        // Current app and window
        parts.append("App: \(activeAppName)")
        if !activeWindowTitle.isEmpty {
            parts.append("Window: \(activeWindowTitle)")
        }

        // Search query if detected
        if !detectedSearchQuery.isEmpty {
            parts.append("Searching: \(detectedSearchQuery)")
        }

        // Topic if detected
        if !detectedTopic.isEmpty {
            parts.append("Topic: \(detectedTopic)")
        }

        // File type if coding
        if !detectedFileType.isEmpty {
            parts.append("File: \(detectedFileType)")
        }

        // Time context
        let minutes = Int(timeOnCurrentTask / 60)
        if minutes > 0 {
            parts.append("Time: \(minutes) min")
        }

        // Recent activity summary
        if !recentActivity.isEmpty {
            parts.append("Recent: \(recentActivity.joined(separator: " → "))")
        }

        currentContext = parts.joined(separator: " | ")
    }

    private func analyzeRecentActivity() {
        // Reset
        detectedSearchQuery = ""
        detectedFileType = ""
        detectedTopic = ""
        recentActivity = []

        // Analyze recent window titles
        for title in recentWindowTitles.prefix(5) {
            let lower = title.lowercased()

            // Detect search queries
            if lower.contains("google") || lower.contains("search") {
                // Extract search query from "query - Google Search" format
                if let range = title.range(of: " - Google") ?? title.range(of: " - Search") {
                    let query = String(title[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
                    if !query.isEmpty && detectedSearchQuery.isEmpty {
                        detectedSearchQuery = query
                    }
                }
            }

            // Detect file types from code editors
            let extensions = [".py", ".js", ".ts", ".swift", ".java", ".go", ".rs", ".cpp", ".c", ".html", ".css", ".json", ".yaml", ".md"]
            for ext in extensions {
                if lower.contains(ext) {
                    detectedFileType = ext
                    break
                }
            }

            // Detect topics from titles
            let topicKeywords = ["error", "bug", "fix", "how to", "tutorial", "guide", "learn", "docs", "documentation", "api", "issue"]
            for keyword in topicKeywords {
                if lower.contains(keyword) {
                    detectedTopic = keyword
                    break
                }
            }

            // Build activity summary (shortened titles)
            let shortTitle = title.count > 25 ? String(title.prefix(25)) + "..." : title
            if !recentActivity.contains(shortTitle) {
                recentActivity.append(shortTitle)
            }
        }
    }

    private func reportActivity() async {
        // Include current ongoing activity with full context
        if !lastReportedApp.isEmpty {
            let duration = Date().timeIntervalSince(lastAppChange)
            let item = ActivityReportItem(
                appName: lastReportedApp,
                windowTitle: activeWindowTitle,
                startedAt: ISO8601DateFormatter().string(from: lastAppChange),
                endedAt: nil,
                durationSeconds: duration,
                idleSeconds: idleTime,
                mightBeStuck: mightBeStuck
            )
            activityBuffer.append(item)
        }

        guard !activityBuffer.isEmpty else { return }

        let itemsToReport = activityBuffer
        activityBuffer.removeAll()

        do {
            try await APIClient.shared.reportActivity(itemsToReport)
            print("Reported \(itemsToReport.count) activity items - Window: \(activeWindowTitle), Stuck: \(mightBeStuck)")
        } catch {
            // Put items back if reporting failed
            activityBuffer.insert(contentsOf: itemsToReport, at: 0)
            print("Failed to report activity: \(error)")
        }
    }
}
