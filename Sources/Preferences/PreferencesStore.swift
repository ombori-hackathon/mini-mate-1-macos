import Foundation

@Observable
@MainActor
class PreferencesStore {
    static let shared = PreferencesStore()

    // Work Session Settings
    var workSessionMinutes: Int {
        didSet { UserDefaults.standard.set(workSessionMinutes, forKey: "workSessionMinutes") }
    }

    var breakDurationMinutes: Int {
        didSet { UserDefaults.standard.set(breakDurationMinutes, forKey: "breakDurationMinutes") }
    }

    // Hint Settings
    var enableBreakReminders: Bool {
        didSet { UserDefaults.standard.set(enableBreakReminders, forKey: "enableBreakReminders") }
    }

    var enableFocusAlerts: Bool {
        didSet { UserDefaults.standard.set(enableFocusAlerts, forKey: "enableFocusAlerts") }
    }

    var enableWorkflowTips: Bool {
        didSet { UserDefaults.standard.set(enableWorkflowTips, forKey: "enableWorkflowTips") }
    }

    var enableAppTips: Bool {
        didSet { UserDefaults.standard.set(enableAppTips, forKey: "enableAppTips") }
    }

    var maxHintsPerHour: Int {
        didSet { UserDefaults.standard.set(maxHintsPerHour, forKey: "maxHintsPerHour") }
    }

    var hintDisplaySeconds: Int {
        didSet { UserDefaults.standard.set(hintDisplaySeconds, forKey: "hintDisplaySeconds") }
    }

    // Companion Settings
    var showOnStartup: Bool {
        didSet { UserDefaults.standard.set(showOnStartup, forKey: "showOnStartup") }
    }

    var companionSize: Double {
        didSet { UserDefaults.standard.set(companionSize, forKey: "companionSize") }
    }

    var enableAnimations: Bool {
        didSet { UserDefaults.standard.set(enableAnimations, forKey: "enableAnimations") }
    }

    // Activity Tracking
    var enableActivityTracking: Bool {
        didSet { UserDefaults.standard.set(enableActivityTracking, forKey: "enableActivityTracking") }
    }

    var idleThresholdMinutes: Int {
        didSet { UserDefaults.standard.set(idleThresholdMinutes, forKey: "idleThresholdMinutes") }
    }

    // Time-Based Hint Settings
    var sessionDurationMinutes: Int {
        didSet { UserDefaults.standard.set(sessionDurationMinutes, forKey: "sessionDurationMinutes") }
    }

    var breakIntervalMinutes: Int {
        didSet { UserDefaults.standard.set(breakIntervalMinutes, forKey: "breakIntervalMinutes") }
    }

    var sameAppThresholdMinutes: Int {
        didSet { UserDefaults.standard.set(sameAppThresholdMinutes, forKey: "sameAppThresholdMinutes") }
    }

    var enableSameAppHints: Bool {
        didSet { UserDefaults.standard.set(enableSameAppHints, forKey: "enableSameAppHints") }
    }

    private init() {
        // Load saved values or use defaults
        self.workSessionMinutes = UserDefaults.standard.object(forKey: "workSessionMinutes") as? Int ?? 30
        self.breakDurationMinutes = UserDefaults.standard.object(forKey: "breakDurationMinutes") as? Int ?? 5
        self.enableBreakReminders = UserDefaults.standard.object(forKey: "enableBreakReminders") as? Bool ?? true
        self.enableFocusAlerts = UserDefaults.standard.object(forKey: "enableFocusAlerts") as? Bool ?? true
        self.enableWorkflowTips = UserDefaults.standard.object(forKey: "enableWorkflowTips") as? Bool ?? true
        self.enableAppTips = UserDefaults.standard.object(forKey: "enableAppTips") as? Bool ?? true
        self.maxHintsPerHour = UserDefaults.standard.object(forKey: "maxHintsPerHour") as? Int ?? 3
        self.hintDisplaySeconds = UserDefaults.standard.object(forKey: "hintDisplaySeconds") as? Int ?? 10
        self.showOnStartup = UserDefaults.standard.object(forKey: "showOnStartup") as? Bool ?? true
        self.companionSize = UserDefaults.standard.object(forKey: "companionSize") as? Double ?? 1.0
        self.enableAnimations = UserDefaults.standard.object(forKey: "enableAnimations") as? Bool ?? true
        self.enableActivityTracking = UserDefaults.standard.object(forKey: "enableActivityTracking") as? Bool ?? true
        self.idleThresholdMinutes = UserDefaults.standard.object(forKey: "idleThresholdMinutes") as? Int ?? 5
        // Time-based hints
        self.sessionDurationMinutes = UserDefaults.standard.object(forKey: "sessionDurationMinutes") as? Int ?? 60
        self.breakIntervalMinutes = UserDefaults.standard.object(forKey: "breakIntervalMinutes") as? Int ?? 30
        self.sameAppThresholdMinutes = UserDefaults.standard.object(forKey: "sameAppThresholdMinutes") as? Int ?? 10
        self.enableSameAppHints = UserDefaults.standard.object(forKey: "enableSameAppHints") as? Bool ?? true
    }

    func resetToDefaults() {
        workSessionMinutes = 30
        breakDurationMinutes = 5
        enableBreakReminders = true
        enableFocusAlerts = true
        enableWorkflowTips = true
        enableAppTips = true
        maxHintsPerHour = 3
        hintDisplaySeconds = 10
        showOnStartup = true
        companionSize = 1.0
        enableAnimations = true
        enableActivityTracking = true
        idleThresholdMinutes = 5
        // Time-based hints
        sessionDurationMinutes = 60
        breakIntervalMinutes = 30
        sameAppThresholdMinutes = 10
        enableSameAppHints = true
    }
}
