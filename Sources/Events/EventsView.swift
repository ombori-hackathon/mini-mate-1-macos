import SwiftUI

struct EventsView: View {
    @State private var eventsStore = EventsStore.shared
    @State private var showingAddEvent = false
    @State private var editingEvent: ScheduledEvent?
    @State private var newEventTitle = ""
    @State private var newEventTime = Date()
    @State private var newEventNotes = ""
    @State private var reminderMinutesBefore = 5

    private let reminderOptions = [0, 5, 10, 15, 30, 60]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)

            Divider()

            // Content
            if eventsStore.getTodayEvents().isEmpty && !showingAddEvent {
                emptyStateView
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        // Add/Edit form
                        if showingAddEvent || editingEvent != nil {
                            eventFormView
                                .padding(.horizontal, 16)
                                .padding(.top, 12)
                        }

                        // Events list
                        if !eventsStore.getTodayEvents().isEmpty {
                            eventsListView
                                .padding(.horizontal, 16)
                                .padding(.top, showingAddEvent || editingEvent != nil ? 8 : 12)
                        }
                    }
                    .padding(.bottom, 16)
                }
            }

            Divider()

            // Quick add footer
            quickAddFooter
                .padding(12)
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Schedule")
                    .font(.title2)
                    .fontWeight(.bold)

                Text(Date(), style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    if showingAddEvent {
                        resetForm()
                    } else {
                        showingAddEvent = true
                    }
                }
            }) {
                Image(systemName: showingAddEvent ? "xmark.circle.fill" : "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(showingAddEvent ? .secondary : .blue)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 32))
                    .foregroundStyle(.blue)
            }

            VStack(spacing: 6) {
                Text("No Events Today")
                    .font(.headline)

                Text("Add events to get AI-powered\nreminders when they're due")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    showingAddEvent = true
                }
            }) {
                Label("Add Event", systemImage: "plus")
                    .font(.subheadline.weight(.medium))
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Event Form
    private var eventFormView: some View {
        VStack(spacing: 14) {
            // Title field
            VStack(alignment: .leading, spacing: 6) {
                Label("Event", systemImage: "pencil")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextField("What's happening?", text: $newEventTitle)
                    .textFieldStyle(.roundedBorder)
            }

            // Time picker
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Time", systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    DatePicker("", selection: $newEventTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }

                VStack(alignment: .leading, spacing: 6) {
                    Label("Remind", systemImage: "bell")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Picker("", selection: $reminderMinutesBefore) {
                        Text("At time").tag(0)
                        Text("5 min").tag(5)
                        Text("10 min").tag(10)
                        Text("15 min").tag(15)
                        Text("30 min").tag(30)
                        Text("1 hour").tag(60)
                    }
                    .labelsHidden()
                    .frame(width: 90)
                }

                Spacer()
            }

            // Notes (optional)
            VStack(alignment: .leading, spacing: 6) {
                Label("Notes (optional)", systemImage: "note.text")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextField("Add details...", text: $newEventNotes)
                    .textFieldStyle(.roundedBorder)
            }

            // Actions
            HStack {
                Button("Cancel") {
                    withAnimation(.spring(response: 0.3)) {
                        resetForm()
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                Spacer()

                Button(action: saveEvent) {
                    Text(editingEvent != nil ? "Update" : "Add Event")
                }
                .buttonStyle(.borderedProminent)
                .disabled(newEventTitle.isEmpty)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Events List
    private var eventsListView: some View {
        VStack(spacing: 8) {
            ForEach(eventsStore.getTodayEvents()) { event in
                EnhancedEventRow(
                    event: event,
                    onEdit: {
                        editingEvent = event
                        newEventTitle = event.title
                        newEventTime = event.time
                        newEventNotes = event.notes ?? ""
                        reminderMinutesBefore = event.reminderMinutesBefore
                        showingAddEvent = false
                    },
                    onDelete: {
                        withAnimation(.spring(response: 0.3)) {
                            eventsStore.removeEvent(event)
                        }
                    }
                )
            }
        }
    }

    // MARK: - Quick Add Footer
    private var quickAddFooter: some View {
        HStack(spacing: 8) {
            Text("Quick:")
                .font(.caption)
                .foregroundStyle(.tertiary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    QuickAddChip(title: "Standup", icon: "person.3") {
                        quickAdd("Standup", minutesFromNow: 60)
                    }
                    QuickAddChip(title: "Meeting", icon: "video") {
                        quickAdd("Meeting", minutesFromNow: 30)
                    }
                    QuickAddChip(title: "Call", icon: "phone") {
                        quickAdd("Call", minutesFromNow: 15)
                    }
                    QuickAddChip(title: "Break", icon: "cup.and.saucer") {
                        quickAdd("Coffee Break", minutesFromNow: 30)
                    }
                    QuickAddChip(title: "Lunch", icon: "fork.knife") {
                        quickAdd("Lunch", atHour: 12)
                    }
                    QuickAddChip(title: "Review", icon: "doc.text") {
                        quickAdd("Code Review", minutesFromNow: 60)
                    }
                }
            }
        }
    }

    // MARK: - Actions
    private func saveEvent() {
        if let editing = editingEvent {
            var updated = editing
            updated.title = newEventTitle
            updated.time = newEventTime
            updated.notes = newEventNotes.isEmpty ? nil : newEventNotes
            updated.reminderMinutesBefore = reminderMinutesBefore
            eventsStore.updateEvent(updated)
        } else {
            let event = ScheduledEvent(
                title: newEventTitle,
                time: newEventTime,
                notes: newEventNotes.isEmpty ? nil : newEventNotes,
                reminderMinutesBefore: reminderMinutesBefore
            )
            eventsStore.addEvent(event)
        }

        withAnimation(.spring(response: 0.3)) {
            resetForm()
        }
    }

    private func resetForm() {
        showingAddEvent = false
        editingEvent = nil
        newEventTitle = ""
        newEventTime = Date()
        newEventNotes = ""
        reminderMinutesBefore = 5
    }

    private func quickAdd(_ title: String, minutesFromNow: Int? = nil, atHour: Int? = nil) {
        let calendar = Calendar.current
        let time: Date

        if let minutes = minutesFromNow {
            time = calendar.date(byAdding: .minute, value: minutes, to: Date()) ?? Date()
        } else if let hour = atHour {
            var components = calendar.dateComponents([.year, .month, .day], from: Date())
            components.hour = hour
            components.minute = 0
            time = calendar.date(from: components) ?? Date()
        } else {
            time = Date()
        }

        let event = ScheduledEvent(
            title: title,
            time: time,
            reminderMinutesBefore: 5
        )
        withAnimation(.spring(response: 0.3)) {
            eventsStore.addEvent(event)
        }
    }
}

// MARK: - Enhanced Event Row
struct EnhancedEventRow: View {
    let event: ScheduledEvent
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var showActions = false

    private var statusColor: Color {
        if event.isPast {
            return .secondary
        } else if event.isTimeToRemind {
            return .green
        } else if event.isUpcoming {
            return .orange
        } else {
            return .blue
        }
    }

    private var timeUntil: String {
        let interval = event.time.timeIntervalSince(Date())
        if interval < 0 {
            return "Past"
        } else if interval < 60 {
            return "Now"
        } else if interval < 3600 {
            return "in \(Int(interval / 60))m"
        } else {
            return "in \(Int(interval / 3600))h"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Time indicator
            VStack(spacing: 2) {
                Text(event.timeString)
                    .font(.system(.subheadline, design: .monospaced, weight: .semibold))
                    .foregroundColor(statusColor)

                if !event.isPast {
                    Text(timeUntil)
                        .font(.system(size: 9))
                        .foregroundColor(statusColor.opacity(0.8))
                }
            }
            .frame(width: 50)

            // Status dot
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .stroke(statusColor.opacity(0.3), lineWidth: 2)
                )

            // Event details
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(event.isPast ? .secondary : .primary)
                    .strikethrough(event.isPast)

                if let notes = event.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Status badge
            if event.isTimeToRemind {
                Text("NOW")
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.2))
                    .foregroundStyle(.green)
                    .cornerRadius(6)
            }

            // Actions
            HStack(spacing: 4) {
                Button(action: onEdit) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.secondary.opacity(0.6))
                }
                .buttonStyle(.plain)

                Button(action: onDelete) {
                    Image(systemName: "trash.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.red.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(event.isTimeToRemind ? Color.green.opacity(0.4) : Color.clear, lineWidth: 1.5)
        )
    }
}

// MARK: - Quick Add Chip
struct QuickAddChip: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(title)
                    .font(.caption2)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.primary.opacity(0.06))
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}
