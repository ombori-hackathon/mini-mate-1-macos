import Foundation

enum AnimationState: String, CaseIterable {
    case idle
    case blinking
    case waving
    case talking
    case thinking
    case sleeping

    var frameCount: Int {
        switch self {
        case .idle: return 1
        case .blinking: return 4
        case .waving: return 6
        case .talking: return 4
        case .thinking: return 2
        case .sleeping: return 2
        }
    }

    var framesPerSecond: Double {
        switch self {
        case .idle: return 1
        case .blinking: return 12
        case .waving: return 8
        case .talking: return 10
        case .thinking: return 2
        case .sleeping: return 1
        }
    }

    var duration: TimeInterval {
        Double(frameCount) / framesPerSecond
    }

    var looping: Bool {
        switch self {
        case .idle, .sleeping: return true
        default: return false
        }
    }
}
