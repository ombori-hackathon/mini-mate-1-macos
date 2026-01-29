import SwiftUI

struct CompanionView: View {
    @Bindable var hintService: HintService
    @Bindable var animationEngine: AnimationEngine
    var preferences = PreferencesStore.shared

    var body: some View {
        VStack(spacing: 12) {
            // Speech bubble for hints - instant swap
            if let hint = hintService.currentHint {
                HintBubbleView(hint: hint) {
                    hintService.dismissCurrentHint()
                }
                .id(hint.id) // Force new view on hint change
                .transition(.opacity)
                .onAppear {
                    if preferences.enableAnimations {
                        animationEngine.playOnce(.talking)
                    }
                }
            }

            // Animated character
            CharacterView(engine: animationEngine)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .animation(.easeOut(duration: 0.15), value: hintService.currentHint?.id)
    }
}

// MARK: - Clean Hint Bubble
struct HintBubbleView: View {
    let hint: Hint
    let onDismiss: () -> Void
    var displaySeconds: Int = PreferencesStore.shared.hintDisplaySeconds

    @State private var dismissProgress: CGFloat = 0
    @State private var autoDismissTask: Task<Void, Never>?

    private var accentColor: Color {
        switch hint.category {
        case .breakReminder:
            return .green
        case .appSuggestion:
            return .blue
        case .workflowTip:
            return .orange
        case .focusAlert:
            return .red
        case .eventReminder:
            return .purple
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Title row
            HStack(spacing: 8) {
                Text(hint.title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Spacer()

                // Close button
                Button(action: {
                    autoDismissTask?.cancel()
                    onDismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary.opacity(0.6))
                }
                .buttonStyle(.plain)
            }

            // Message
            Text(hint.message)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            // Progress bar (10 seconds)
            GeometryReader { geo in
                Capsule()
                    .fill(accentColor.opacity(0.3))
                    .frame(height: 3)
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(accentColor)
                            .frame(width: geo.size.width * (1 - dismissProgress), height: 3)
                    }
            }
            .frame(height: 3)
        }
        .padding(14)
        .frame(width: 200)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(accentColor.opacity(0.3), lineWidth: 1)
        )
        // Small pointer
        .overlay(alignment: .bottom) {
            Triangle()
                .fill(.regularMaterial)
                .frame(width: 14, height: 8)
                .offset(y: 7)
        }
        .onAppear {
            startAutoDismiss()
        }
        .onDisappear {
            autoDismissTask?.cancel()
        }
    }

    private func startAutoDismiss() {
        autoDismissTask = Task {
            let duration = Double(displaySeconds)
            let steps = displaySeconds * 5  // Smooth animation
            let stepDuration = duration / Double(steps)

            for i in 0...steps {
                if Task.isCancelled { break }
                try? await Task.sleep(nanoseconds: UInt64(stepDuration * 1_000_000_000))
                await MainActor.run {
                    dismissProgress = CGFloat(i) / CGFloat(steps)
                }
            }

            if !Task.isCancelled {
                await MainActor.run {
                    onDismiss()
                }
            }
        }
    }
}

// Simple triangle pointer
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.closeSubpath()
        }
    }
}
