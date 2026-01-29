import SwiftUI

struct EventsView: View {
    @State private var eventsStore = EventsStore.shared
    @State private var showingAddEvent = false
    @State private var newEventTitle = ""
    @State private var newEventTime = Date()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Today's Schedule")
                    .font(.headline)
                Spacer()
                Button(action: { showingAddEvent.toggle() }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }

            // Add event form
            if showingAddEvent {
                VStack(spacing: 12) {
                    TextField("Event title (e.g., Standup, Meeting)", text: $newEventTitle)
                        .textFieldStyle(.roundedBorder)

                    DatePicker("Time", selection: $newEventTime, displayedComponents: .hourAndMinute)

                    HStack {
                        Button("Cancel") {
                            showingAddEvent = false
                            newEventTitle = ""
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)

                        Spacer()

                        Button("Add Event") {
                            addEvent()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(newEventTitle.isEmpty)
                    }
                }
                .padding()
                .background(Color.primary.opacity(0.05))
                .cornerRadius(8)
            }

            // Events list
            if eventsStore.getTodayEvents().isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No events scheduled")
                        .foregroundStyle(.secondary)
                    Text("Add events and get AI reminders!")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(eventsStore.getTodayEvents()) { event in
                            EventRow(event: event, onDelete: {
                                eventsStore.removeEvent(event)
                            })
                        }
                    }
                }
                .frame(maxHeight: 150)
            }

            Divider()

            // Quick add buttons
            VStack(alignment: .leading, spacing: 8) {
                Text("Quick Add")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    QuickAddButton(title: "Coffee", icon: "cup.and.saucer.fill") {
                        quickAdd("Coffee Break")
                    }
                    QuickAddButton(title: "Standup", icon: "person.3.fill") {
                        quickAdd("Standup")
                    }
                    QuickAddButton(title: "Meeting", icon: "video.fill") {
                        quickAdd("Meeting")
                    }
                    QuickAddButton(title: "Lunch", icon: "fork.knife") {
                        quickAdd("Lunch")
                    }
                }
            }
        }
        .padding()
    }

    private func addEvent() {
        let event = ScheduledEvent(
            title: newEventTitle,
            time: newEventTime
        )
        eventsStore.addEvent(event)
        newEventTitle = ""
        newEventTime = Date()
        showingAddEvent = false
    }

    private func quickAdd(_ title: String) {
        newEventTitle = title
        // Set time to next hour
        let calendar = Calendar.current
        let now = Date()
        let nextHour = calendar.date(byAdding: .hour, value: 1, to: now)!
        let components = calendar.dateComponents([.year, .month, .day, .hour], from: nextHour)
        newEventTime = calendar.date(from: components) ?? nextHour
        showingAddEvent = true
    }
}

struct EventRow: View {
    let event: ScheduledEvent
    let onDelete: () -> Void

    var body: some View {
        HStack {
            // Time badge
            Text(event.timeString)
                .font(.system(.caption, design: .monospaced, weight: .medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(event.isPast ? Color.secondary.opacity(0.2) : Color.blue.opacity(0.2))
                .foregroundColor(event.isPast ? .secondary : .blue)
                .cornerRadius(6)

            // Title
            Text(event.title)
                .foregroundStyle(event.isPast ? .secondary : .primary)
                .strikethrough(event.isPast)

            Spacer()

            // Status
            if event.isTimeToRemind {
                Text("NOW")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.2))
                    .foregroundStyle(.green)
                    .cornerRadius(4)
            }

            // Delete button
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

struct QuickAddButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(title)
                    .font(.caption2)
            }
            .frame(width: 60, height: 50)
            .background(Color.primary.opacity(0.05))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}
