import SwiftUI
import Combine
import AVFoundation
import CoreMotion
import CoreHaptics
#if canImport(UIKit)
import UIKit
#endif

@MainActor
final class PunchDetector: ObservableObject {
    
    @Published var status: String = "waiting"
    @Published var flashTrigger: Int = 0
    

    private let motionManager = CMMotionManager()
    private var hapticEngine: CHHapticEngine?
    private var winPlayer: AVAudioPlayer?
    private var tapPlayer: AVAudioPlayer?
    private var isDetecting = false

    private var lastPunchTime: Date?
    private var resetTimer: Timer?
    private var pulseTimer: Timer?

    // Detection tuning
    @Published var threshold: Double = 1.4 // magnitude of userAcceleration to count as a punch
    @Published var hysteresisRatio: Double = 0.5
    var hysteresisLow: Double { threshold * hysteresisRatio }
    @Published var cooldown: TimeInterval = 0.2 // ignore subsequent peaks within this window
    @Published var pairingWindow: TimeInterval = 1.0 // must perform second punch within this time

    enum Axis {
        case x, y, z
    }
    @Published var directionAxis: Axis = .z

    @Published var minUpwardAcceleration: Double = 0.0
    @Published var minVerticalDisplacement: Double = 0.0

    private var wasBelow = true
    private var cooldownUntil: Date?

    func start() {
        status = "Listening for two punches…"
        wasBelow = true
        lastPunchTime = nil
        resetTimer?.invalidate(); resetTimer = nil
        pulseTimer?.invalidate(); pulseTimer = nil
        isDetecting = true

        setupHaptics()

        guard motionManager.isDeviceMotionAvailable else {
            status = "Device motion not available."
            return
        }
        motionManager.deviceMotionUpdateInterval = 1.0 / 100.0
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] data, _ in
            guard let self = self, let data = data else { return }
            let a = data.userAcceleration
            let magnitude = sqrt(a.x * a.x + a.y * a.y + a.z * a.z)
            self.process(magnitude: magnitude)
        }
    }

    func stop() {
        motionManager.stopDeviceMotionUpdates()
        isDetecting = false
        resetTimer?.invalidate(); resetTimer = nil
        pulseTimer?.invalidate(); pulseTimer = nil
        if let engine = hapticEngine {
            engine.stop(completionHandler: nil)
        }
        status = "paused"
    }

    private func process(magnitude: Double) {
        guard isDetecting else { return }
        let now = Date()
        if magnitude < hysteresisLow {
            wasBelow = true
        }
        if wasBelow && magnitude > threshold {
            wasBelow = false
            if let cooldownUntil, now < cooldownUntil { return }
            cooldownUntil = now.addingTimeInterval(cooldown)
            punchDetected(at: now)
        }
    }

    private func punchDetected(at now: Date) {
        playTapSound()
        if let first = lastPunchTime {
            if now.timeIntervalSince(first) <= pairingWindow {
                status = "Double punch detected! Vibrating…"
                lastPunchTime = nil
                resetTimer?.invalidate(); resetTimer = nil
                playWinSound()
                // Notify the view to start a 2-second flash effect
                flashTrigger += 1
                // Stop detecting further punches immediately, but allow vibration/sound to continue
                isDetecting = false
                motionManager.stopDeviceMotionUpdates()
                vibrateForTwoSeconds()
            } else {
                // Too slow; treat as new first punch
                lastPunchTime = now
                status = "Punch 1 detected (previous expired)"
                scheduleReset()
            }
        } else {
            lastPunchTime = now
            status = "Punch 1 detected"
            scheduleReset()
        }
    }

    private func scheduleReset() {
        resetTimer?.invalidate()
        resetTimer = Timer.scheduledTimer(withTimeInterval: pairingWindow, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            if self.lastPunchTime != nil {
                self.lastPunchTime = nil
                self.status = "Timeout. Listening…"
            }
        }
    }

    private func setupHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            // If haptics cannot start, we'll fall back later
        }
    }

    private func vibrateForTwoSeconds() {
        if CHHapticEngine.capabilitiesForHardware().supportsHaptics {
            do {
                let event = CHHapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                    ],
                    relativeTime: 0,
                    duration: 2.0
                )
                let pattern = try CHHapticPattern(events: [event], parameters: [])
                let player = try hapticEngine?.makePlayer(with: pattern)
                try player?.start(atTime: 0)
                return
            } catch {
                // Fall through to fallback
            }
        }
        fallbackVibration()
    }

    private func playWinSound() {
        guard let url = Bundle.main.url(forResource: "win", withExtension: "wav") else { return }
        do {
            winPlayer = try AVAudioPlayer(contentsOf: url)
            winPlayer?.prepareToPlay()
            winPlayer?.play()
        } catch {
            // If playback fails, ignore
        }
    }

    private func playTapSound() {
        guard let url = Bundle.main.url(forResource: "tap", withExtension: "wav") else { return }
        do {
            tapPlayer = try AVAudioPlayer(contentsOf: url)
            tapPlayer?.prepareToPlay()
            tapPlayer?.play()
        } catch {
            // If playback fails, ignore
        }
    }

    private func fallbackVibration() {
        // Approximate a 2-second vibration using repeated heavy impacts
        pulseTimer?.invalidate()
        #if canImport(UIKit)
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        var remaining: TimeInterval = 2.0
        pulseTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] timer in
            generator.impactOccurred()
            remaining -= 0.15
            if remaining <= 0 {
                timer.invalidate()
                self?.pulseTimer = nil
            }
        }
        #endif
    }
}

struct ShakeView: View {
    @StateObject private var detector = PunchDetector()
    @State private var isFlashing = false
    @State private var isBlackBackground = false
    @State private var flashTimer: Timer?
    @State private var wobble = false
    @State private var pulse = false
    @State private var showResultPopup = false
    @Binding var isActive: Bool

    var body: some View {
        VStack(spacing: 80) {
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    Spacer()
                    ZStack {
                        Image("bubble-gr")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 400, height: 200)
//                            .rotationEffect(.degrees(wobble ? 0.5 : -0.5))
//                            .animation(
//                                .easeInOut(duration: 0.8)
//                                    .repeatForever(autoreverses: true),
//                                value: wobble
//                            )
//                            .onAppear { wobble = true }
                        
                        VStack(spacing: 0) {
                            Text("Now")
                                .font(.system(size: 24, weight: .light))
                                .foregroundColor(.white)

                            Text("“Raise your phone\nand shake it!”")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .fontDesign(.rounded)
                                .scaleEffect(pulse ? 1 : 0.975)
                                .opacity(pulse ? 1.0 : 0.8)
                                .animation(
                                    .easeInOut(duration: 0.8)
                                        .repeatForever(autoreverses: true),
                                    value: pulse
                                )
                                .onAppear {
                                    pulse = true
                                }
                        }.offset(y: -16)
                    }

                    Image("wave2")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 400, height: 300)
                        .rotationEffect(.degrees(wobble ? 1 : -1))
                        .animation(
                            .easeInOut(duration: 0.3)
                                .repeatForever(autoreverses: true),
                            value: wobble
                        )
                        .onAppear { wobble = true }
                    
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(isBlackBackground ? Color.purple : Color.white)
//        .navigationTitle("Shake")
        .onAppear { detector.start() }
        .onDisappear {
            detector.stop()
            flashTimer?.invalidate(); flashTimer = nil
            isFlashing = false
            isBlackBackground = false
        }
        .onChange(of: detector.flashTrigger) { _ in
            startFlashEffect()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                showResultPopup = true
            }
        }
        .overlay {
            if showResultPopup {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // change the icon
                    Image(systemName: "sparkles")
                        .font(.system(size: 50))
                        .foregroundColor(.yellow)
                    
                    // change the text
                    Text("Have a good day!")
                        .font(.title2)
                        .bold()
                    
                    Button {
                        showResultPopup = false
                        isActive = false
                    } label: {
                        Text("Back")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(30)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .padding(40)
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(), value: showResultPopup)
            }
        }
        .navigationBarBackButtonHidden()
    }

    private func startFlashEffect() {
        flashTimer?.invalidate()
        isFlashing = true
        isBlackBackground = false // start from white
        let start = Date()
        flashTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { timer in
            let elapsed = Date().timeIntervalSince(start)
            if elapsed >= 2.0 {
                timer.invalidate()
                self.flashTimer = nil
                self.isFlashing = false
                self.isBlackBackground = false // revert to white
            } else {
                withAnimation(.linear(duration: 0.1)) {
                    self.isBlackBackground.toggle()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ShakeView(isActive: .constant(true))
    }
}

