import Foundation
import Combine

@Observable
@MainActor
class AnimationEngine {
    var currentState: AnimationState = .idle
    var frameIndex: Int = 0

    private var frameTimer: Timer?
    private var idleVariationTimer: Timer?
    private var stateCompletion: (() -> Void)?

    init() {
        startIdleVariations()
    }

    func startIdleVariations() {
        idleVariationTimer?.invalidate()
        idleVariationTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.currentState == .idle else { return }
                // Random chance to blink
                if Bool.random() {
                    self.playOnce(.blinking)
                }
            }
        }
    }

    func playOnce(_ state: AnimationState, completion: (() -> Void)? = nil) {
        guard currentState == .idle || currentState == .sleeping else { return }

        stopFrameTimer()
        currentState = state
        frameIndex = 0
        stateCompletion = completion

        startFrameTimer()
    }

    func setState(_ state: AnimationState) {
        stopFrameTimer()
        currentState = state
        frameIndex = 0

        if state.looping {
            startFrameTimer()
        }
    }

    private func startFrameTimer() {
        let interval = 1.0 / currentState.framesPerSecond
        frameTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.advanceFrame()
            }
        }
    }

    private func stopFrameTimer() {
        frameTimer?.invalidate()
        frameTimer = nil
    }

    private func advanceFrame() {
        frameIndex += 1

        if frameIndex >= currentState.frameCount {
            if currentState.looping {
                frameIndex = 0
            } else {
                // Animation complete, return to idle
                stopFrameTimer()
                let completion = stateCompletion
                stateCompletion = nil
                currentState = .idle
                frameIndex = 0
                completion?()
            }
        }
    }

    func react(to hint: Hint?) {
        if hint != nil {
            playOnce(.talking) {
                // Stay in talking mode while hint is visible
            }
        }
    }

    // Note: deinit removed for MainActor isolated class
    // Timers will be cleaned up when the class is deallocated
}
