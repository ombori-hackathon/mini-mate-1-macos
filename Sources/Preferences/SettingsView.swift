import SwiftUI

struct SettingsView: View {
    @Bindable var preferences = PreferencesStore.shared
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            ScheduleTab()
                .tabItem {
                    Label("Schedule", systemImage: "calendar")
                }
                .tag(0)

            WorkSessionTab(preferences: preferences)
                .tabItem {
                    Label("Work", systemImage: "clock")
                }
                .tag(1)

            HintsTab(preferences: preferences)
                .tabItem {
                    Label("Hints", systemImage: "bubble.left")
                }
                .tag(2)

            CompanionTab(preferences: preferences)
                .tabItem {
                    Label("Companion", systemImage: "face.smiling")
                }
                .tag(3)

            AboutTab()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
                .tag(4)
        }
        .frame(width: 500, height: 450)
    }
}

// MARK: - Schedule Tab
struct ScheduleTab: View {
    var body: some View {
        EventsView()
    }
}

// MARK: - Work Session Tab
struct WorkSessionTab: View {
    @Bindable var preferences: PreferencesStore

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Session & Breaks Section
                SettingsSection(title: "Session & Breaks", icon: "timer") {
                    SettingsRow(title: "Session Duration") {
                        HStack(spacing: 8) {
                            Slider(
                                value: Binding(
                                    get: { Double(preferences.sessionDurationMinutes) },
                                    set: { preferences.sessionDurationMinutes = Int($0) }
                                ),
                                in: 1...120,
                                step: 1
                            )
                            .frame(width: 150)

                            Text("\(preferences.sessionDurationMinutes) min")
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.secondary)
                                .frame(width: 60, alignment: .trailing)
                        }
                    }

                    SettingsRow(title: "Break Interval") {
                        HStack(spacing: 8) {
                            Slider(
                                value: Binding(
                                    get: { Double(preferences.breakIntervalMinutes) },
                                    set: { preferences.breakIntervalMinutes = Int($0) }
                                ),
                                in: 1...60,
                                step: 1
                            )
                            .frame(width: 150)

                            Text("\(preferences.breakIntervalMinutes) min")
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.secondary)
                                .frame(width: 60, alignment: .trailing)
                        }
                    }
                }

                // Focus Hints Section
                SettingsSection(title: "Focus Hints", icon: "clock.arrow.circlepath") {
                    SettingsToggleRow(
                        title: "Same-App Hints",
                        subtitle: "Get tips when focused on one app",
                        icon: "app.badge.checkmark",
                        color: .blue,
                        isOn: $preferences.enableSameAppHints
                    )

                    if preferences.enableSameAppHints {
                        SettingsRow(title: "Trigger After") {
                            HStack(spacing: 8) {
                                Slider(
                                    value: Binding(
                                        get: { Double(preferences.sameAppThresholdMinutes) },
                                        set: { preferences.sameAppThresholdMinutes = Int($0) }
                                    ),
                                    in: 1...30,
                                    step: 1
                                )
                                .frame(width: 150)

                                Text("\(preferences.sameAppThresholdMinutes) min")
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .frame(width: 60, alignment: .trailing)
                            }
                        }
                    }
                }

                // Activity Tracking Section
                SettingsSection(title: "Activity Tracking", icon: "chart.bar") {
                    SettingsToggleRow(
                        title: "Track App Usage",
                        subtitle: "Monitor which apps you use",
                        icon: "chart.bar.xaxis",
                        color: .purple,
                        isOn: $preferences.enableActivityTracking
                    )
                }
            }
            .padding()
        }
    }
}

// MARK: - Hints Tab
struct HintsTab: View {
    @Bindable var preferences: PreferencesStore

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Hint Types Section
                SettingsSection(title: "Hint Types", icon: "lightbulb") {
                    SettingsToggleRow(
                        title: "Break Reminders",
                        subtitle: "Remind you to take breaks",
                        icon: "cup.and.saucer",
                        color: .green,
                        isOn: $preferences.enableBreakReminders
                    )

                    SettingsToggleRow(
                        title: "Focus Alerts",
                        subtitle: "Help you stay focused",
                        icon: "eye",
                        color: .red,
                        isOn: $preferences.enableFocusAlerts
                    )

                    SettingsToggleRow(
                        title: "Workflow Tips",
                        subtitle: "Productivity suggestions",
                        icon: "lightbulb",
                        color: .orange,
                        isOn: $preferences.enableWorkflowTips
                    )

                    SettingsToggleRow(
                        title: "App Tips",
                        subtitle: "Shortcuts for current app",
                        icon: "sparkles",
                        color: .blue,
                        isOn: $preferences.enableAppTips
                    )
                }

                // Frequency Section
                SettingsSection(title: "Frequency", icon: "repeat") {
                    SettingsRow(title: "Max Hints / Hour") {
                        HStack(spacing: 8) {
                            Slider(
                                value: Binding(
                                    get: { Double(preferences.maxHintsPerHour) },
                                    set: { preferences.maxHintsPerHour = Int($0) }
                                ),
                                in: 1...30,
                                step: 1
                            )
                            .frame(width: 150)

                            Text("\(preferences.maxHintsPerHour)")
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.secondary)
                                .frame(width: 40, alignment: .trailing)
                        }
                    }

                    SettingsRow(title: "Hint Display Time") {
                        HStack(spacing: 8) {
                            Slider(
                                value: Binding(
                                    get: { Double(preferences.hintDisplaySeconds) },
                                    set: { preferences.hintDisplaySeconds = Int($0) }
                                ),
                                in: 1...60,
                                step: 1
                            )
                            .frame(width: 150)

                            Text("\(preferences.hintDisplaySeconds) sec")
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.secondary)
                                .frame(width: 60, alignment: .trailing)
                        }
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Companion Tab
struct CompanionTab: View {
    @Bindable var preferences: PreferencesStore

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Behavior Section
                SettingsSection(title: "Behavior", icon: "gearshape") {
                    SettingsToggleRow(
                        title: "Show on Startup",
                        subtitle: "Display companion when app launches",
                        icon: "power",
                        color: .green,
                        isOn: $preferences.showOnStartup
                    )

                    SettingsToggleRow(
                        title: "Animations",
                        subtitle: "Enable character animations",
                        icon: "sparkles.tv",
                        color: .purple,
                        isOn: $preferences.enableAnimations
                    )
                }

                // Appearance Section
                SettingsSection(title: "Appearance", icon: "paintbrush") {
                    SettingsRow(title: "Companion Size") {
                        HStack(spacing: 8) {
                            Slider(value: $preferences.companionSize, in: 0.5...1.5, step: 0.1)
                                .frame(width: 150)

                            Text("\(Int(preferences.companionSize * 100))%")
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.secondary)
                                .frame(width: 50, alignment: .trailing)
                        }
                    }
                }

                // Reset Section
                SettingsSection(title: "Reset", icon: "arrow.counterclockwise") {
                    Button(action: {
                        preferences.resetToDefaults()
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Reset All Settings")
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }
}

// MARK: - About Tab
struct AboutTab: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // App Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: .purple.opacity(0.4), radius: 20)

                VStack(spacing: 8) {
                    HStack(spacing: 20) {
                        Circle().fill(.white).frame(width: 12, height: 12)
                        Circle().fill(.white).frame(width: 12, height: 12)
                    }
                    Capsule().fill(.white).frame(width: 24, height: 8)
                }
            }

            VStack(spacing: 6) {
                Text("MiniMate")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Version 1.0.0")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text("Your friendly AI-powered\ndesktop productivity companion")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Divider()
                .frame(width: 200)

            VStack(spacing: 6) {
                Label("SwiftUI + FastAPI + Ollama", systemImage: "hammer")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Label("Hackathon 2026", systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Reusable Components

struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundColor(.primary)

            VStack(spacing: 1) {
                content
            }
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(10)
        }
    }
}

struct SettingsRow<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.primary)

            Spacer()

            content
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct SettingsToggleRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(color.opacity(0.15))
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
    }
}
