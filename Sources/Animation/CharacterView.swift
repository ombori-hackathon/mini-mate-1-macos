import SwiftUI

struct CharacterView: View {
    @Bindable var engine: AnimationEngine
    var preferences = PreferencesStore.shared
    @State private var isHovered = false
    @State private var breatheOffset: CGFloat = 0
    @State private var waveAngle: Double = 0

    private var baseSize: CGFloat {
        80 * preferences.companionSize
    }

    var body: some View {
        ZStack {
            // Shadow underneath
            Ellipse()
                .fill(Color.black.opacity(0.15))
                .frame(width: baseSize * 0.5, height: baseSize * 0.12)
                .offset(y: baseSize * 0.65)
                .blur(radius: 4)

            // Robot character
            VStack(spacing: 0) {
                // Head and body (combined egg shape)
                ZStack {
                    // Main body - metallic white egg shape
                    RobotBody(size: baseSize)

                    // Ear pieces / headphones
                    HStack(spacing: baseSize * 0.75) {
                        EarPiece(size: baseSize, side: .left)
                        EarPiece(size: baseSize, side: .right)
                    }
                    .offset(y: -baseSize * 0.08)

                    // Visor / Face screen
                    RobotFace(
                        state: engine.currentState,
                        frameIndex: engine.frameIndex,
                        isHovered: isHovered,
                        size: baseSize
                    )
                    .offset(y: -baseSize * 0.05)

                    // Antenna / top accent
                    RobotAntenna(size: baseSize)
                        .offset(y: -baseSize * 0.48)

                    // Arms
                    HStack(spacing: baseSize * 0.6) {
                        RobotArm(size: baseSize, side: .left, isWaving: engine.currentState == .waving, waveAngle: waveAngle)
                        RobotArm(size: baseSize, side: .right, isWaving: false, waveAngle: 0)
                    }
                    .offset(y: baseSize * 0.2)

                    // Chest emblem
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(hex: "4facfe"), Color(hex: "00f2fe").opacity(0.5)],
                                center: .center,
                                startRadius: 0,
                                endRadius: baseSize * 0.06
                            )
                        )
                        .frame(width: baseSize * 0.1, height: baseSize * 0.1)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.5), lineWidth: 1)
                        )
                        .offset(y: baseSize * 0.22)
                }

                // Feet
                HStack(spacing: baseSize * 0.12) {
                    RobotFoot(size: baseSize)
                    RobotFoot(size: baseSize)
                }
                .offset(y: -baseSize * 0.05)
            }
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .offset(y: breatheOffset)
        }
        .frame(width: baseSize * 1.4, height: baseSize * 1.5)
        .animation(preferences.enableAnimations ? .spring(response: 0.3, dampingFraction: 0.6) : nil, value: isHovered)
        .animation(preferences.enableAnimations ? .spring(response: 0.4, dampingFraction: 0.5) : nil, value: engine.currentState)
        .onHover { hovering in
            isHovered = hovering
            if hovering && preferences.enableAnimations {
                engine.playOnce(.waving)
            }
        }
        .onAppear {
            if preferences.enableAnimations {
                startBreathingAnimation()
            }
        }
        .onChange(of: engine.currentState) { _, newState in
            if newState == .waving {
                startWaveAnimation()
            }
        }
    }

    private func startBreathingAnimation() {
        withAnimation(
            .easeInOut(duration: 2.0)
            .repeatForever(autoreverses: true)
        ) {
            breatheOffset = -3
        }
    }

    private func startWaveAnimation() {
        withAnimation(.easeInOut(duration: 0.15).repeatCount(6, autoreverses: true)) {
            waveAngle = 25
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeOut(duration: 0.2)) {
                waveAngle = 0
            }
        }
    }
}

// MARK: - Robot Body
struct RobotBody: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            // Outer glow
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: "4facfe").opacity(0.2), .clear],
                        center: .center,
                        startRadius: size * 0.3,
                        endRadius: size * 0.6
                    )
                )
                .frame(width: size * 1.1, height: size * 1.2)

            // Main body - egg shape
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "f8f9fa"),
                            Color(hex: "e9ecef"),
                            Color(hex: "dee2e6")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.75, height: size * 0.95)
                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)

            // Metallic highlight
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.8), .clear],
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                )
                .frame(width: size * 0.65, height: size * 0.85)
                .offset(x: -size * 0.05, y: -size * 0.05)

            // Edge highlight
            Ellipse()
                .stroke(
                    LinearGradient(
                        colors: [.white, Color(hex: "adb5bd")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .frame(width: size * 0.75, height: size * 0.95)
        }
    }
}

// MARK: - Robot Face (Visor)
struct RobotFace: View {
    let state: AnimationState
    let frameIndex: Int
    let isHovered: Bool
    let size: CGFloat

    private var eyeSpacing: CGFloat {
        size * 0.15
    }

    private var eyeSize: CGFloat {
        size * 0.08
    }

    private var eyeHeight: CGFloat {
        switch state {
        case .blinking:
            let heights: [CGFloat] = [1.0, 0.3, 0.1, 0.3]
            return heights[min(frameIndex, heights.count - 1)]
        case .sleeping:
            return 0.15
        default:
            return 1.0
        }
    }

    var body: some View {
        ZStack {
            // Visor background
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "2d3436"), Color(hex: "1a1a2e")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size * 0.5, height: size * 0.28)
                .overlay(
                    Capsule()
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: "636e72"), Color(hex: "2d3436")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: .black.opacity(0.3), radius: 4, y: 2)

            // Visor shine
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.2), .clear],
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                )
                .frame(width: size * 0.45, height: size * 0.12)
                .offset(y: -size * 0.05)

            // Eyes
            HStack(spacing: eyeSpacing) {
                RobotEye(size: eyeSize, heightScale: eyeHeight, state: state)
                RobotEye(size: eyeSize, heightScale: eyeHeight, state: state)
            }

            // Mouth (only when talking)
            if state == .talking {
                let mouthHeights: [CGFloat] = [0.02, 0.04, 0.06, 0.04]
                let mouthHeight = mouthHeights[min(frameIndex, mouthHeights.count - 1)]
                Capsule()
                    .fill(Color(hex: "00f2fe"))
                    .frame(width: size * 0.12, height: size * mouthHeight)
                    .offset(y: size * 0.07)
                    .shadow(color: Color(hex: "00f2fe").opacity(0.5), radius: 4)
            }

            // Happy mouth (when hovered or waving)
            if (isHovered || state == .waving) && state != .talking {
                SmileArc()
                    .stroke(Color(hex: "00f2fe"), lineWidth: 2)
                    .frame(width: size * 0.1, height: size * 0.04)
                    .offset(y: size * 0.06)
                    .shadow(color: Color(hex: "00f2fe").opacity(0.5), radius: 2)
            }
        }
    }
}

// MARK: - Robot Eye
struct RobotEye: View {
    let size: CGFloat
    let heightScale: CGFloat
    let state: AnimationState

    private var glowColor: Color {
        switch state {
        case .talking:
            return Color(hex: "00f2fe")
        case .waving:
            return Color(hex: "fd79a8")
        case .thinking:
            return Color(hex: "fdcb6e")
        default:
            return Color(hex: "74b9ff")
        }
    }

    var body: some View {
        ZStack {
            // Eye glow
            Capsule()
                .fill(glowColor.opacity(0.3))
                .frame(width: size * 1.3, height: size * heightScale * 1.3)
                .blur(radius: 3)

            // Eye
            Capsule()
                .fill(glowColor)
                .frame(width: size, height: max(size * heightScale, 2))
                .shadow(color: glowColor.opacity(0.8), radius: 4)

            // Eye highlight
            if heightScale > 0.5 {
                Circle()
                    .fill(.white.opacity(0.6))
                    .frame(width: size * 0.3, height: size * 0.3)
                    .offset(x: size * 0.15, y: -size * heightScale * 0.2)
            }
        }
    }
}

// MARK: - Ear Piece
enum Side { case left, right }

struct EarPiece: View {
    let size: CGFloat
    let side: Side

    var body: some View {
        ZStack {
            // Main ear piece
            RoundedRectangle(cornerRadius: size * 0.04)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "e9ecef"), Color(hex: "adb5bd")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size * 0.08, height: size * 0.18)
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.04)
                        .stroke(Color(hex: "868e96"), lineWidth: 1)
                )

            // Speaker grille
            VStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { _ in
                    Capsule()
                        .fill(Color(hex: "495057"))
                        .frame(width: size * 0.04, height: 1.5)
                }
            }
        }
    }
}

// MARK: - Robot Antenna
struct RobotAntenna: View {
    let size: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            // Antenna ball
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: "fd79a8"), Color(hex: "e84393")],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: size * 0.04
                    )
                )
                .frame(width: size * 0.08, height: size * 0.08)
                .shadow(color: Color(hex: "fd79a8").opacity(0.5), radius: 4)

            // Antenna stem
            RoundedRectangle(cornerRadius: 1)
                .fill(Color(hex: "adb5bd"))
                .frame(width: size * 0.02, height: size * 0.06)
        }
    }
}

// MARK: - Robot Arm
struct RobotArm: View {
    let size: CGFloat
    let side: Side
    let isWaving: Bool
    let waveAngle: Double

    var body: some View {
        VStack(spacing: 0) {
            // Upper arm
            RoundedRectangle(cornerRadius: size * 0.02)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "e9ecef"), Color(hex: "ced4da")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: size * 0.05, height: size * 0.12)

            // Hand
            RobotHand(size: size)
        }
        .rotationEffect(
            .degrees(side == .left ? -15 + (isWaving ? waveAngle : 0) : 15),
            anchor: .top
        )
        .offset(x: side == .left ? -size * 0.02 : size * 0.02)
    }
}

// MARK: - Robot Hand
struct RobotHand: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            // Palm
            Circle()
                .fill(Color(hex: "dee2e6"))
                .frame(width: size * 0.08, height: size * 0.08)

            // Fingers
            HStack(spacing: 1) {
                ForEach(0..<3, id: \.self) { _ in
                    Capsule()
                        .fill(Color(hex: "ced4da"))
                        .frame(width: size * 0.015, height: size * 0.035)
                }
            }
            .offset(y: size * 0.04)
        }
    }
}

// MARK: - Robot Foot
struct RobotFoot: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            // Foot base
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "e9ecef"), Color(hex: "adb5bd")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size * 0.14, height: size * 0.06)
                .shadow(color: .black.opacity(0.1), radius: 2, y: 1)

            // Foot highlight
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.5), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size * 0.1, height: size * 0.03)
                .offset(y: -size * 0.01)
        }
    }
}

// MARK: - Smile Arc Shape
struct SmileArc: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control: CGPoint(x: rect.midX, y: rect.maxY)
        )
        return path
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
