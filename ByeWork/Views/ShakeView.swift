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
    @Published var punchCount: Int = 0
    let maxPunches: Int = 4
    

    private let motionManager = CMMotionManager()
    private var hapticEngine: CHHapticEngine?
    private var winPlayer: AVAudioPlayer?
    private var tapPlayer: AVAudioPlayer?
    private var phaserDown1Player: AVAudioPlayer?
    private var phaserDown2Player: AVAudioPlayer?
    private var phaserDown3Player: AVAudioPlayer?
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
        status = "Listening for five punches…"
        wasBelow = true
        lastPunchTime = nil
        punchCount = 0
        resetTimer?.invalidate(); resetTimer = nil
        pulseTimer?.invalidate(); pulseTimer = nil
        isDetecting = true

        setupHaptics()
        setupAudioSession()

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
        
        // If we have a previous punch, ensure we're still within the pairing window; otherwise reset count
        if let first = lastPunchTime {
            if now.timeIntervalSince(first) > pairingWindow {
                // Window expired – start a new sequence
                punchCount = 0
                lastPunchTime = nil
                resetTimer?.invalidate(); resetTimer = nil
                return
            }
        }

        // Count this punch
        punchCount += 1

        // Set/refresh the window start time and reset timer
        lastPunchTime = now
        scheduleReset()

        // Update status with progress
        status = "Punch \(punchCount) of \(maxPunches)"
        
        if punchCount == 1 {
            playPhaserDown1Sound()
        } else if punchCount == 2 {
            playPhaserDown2Sound()
        } else if punchCount == 3 {
            playPhaserDown3Sound()
        }

        // If we reached the target, trigger win behavior
        if punchCount >= maxPunches {
            status = "Combo detected! Vibrating…"
            // Clear sequence state
            punchCount = 0
            lastPunchTime = nil
            resetTimer?.invalidate(); resetTimer = nil

            // Play win, flash, stop detecting, and vibrate just like before
            playWinSound()
            flashTrigger += 1
            isDetecting = false
            motionManager.stopDeviceMotionUpdates()
            vibrateForTwoSeconds()
        }
    }

    private func scheduleReset() {
        resetTimer?.invalidate()
        resetTimer = Timer.scheduledTimer(withTimeInterval: pairingWindow, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            if self.lastPunchTime != nil {
                self.lastPunchTime = nil
                self.punchCount = 0
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
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
            #if os(iOS)
            try? session.overrideOutputAudioPort(.speaker)
            #endif
        } catch {
            // Ignore failures
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
            winPlayer?.volume = 1.0
            winPlayer?.prepareToPlay()
            winPlayer?.play()
        } catch {
            // If playback fails, ignore
        }
    }

    private func playTapSound() {
        if tapPlayer == nil {
            guard let url = Bundle.main.url(forResource: "tap", withExtension: "wav") else { return }
            do {
                tapPlayer = try AVAudioPlayer(contentsOf: url)
                tapPlayer?.volume = 1.0
                tapPlayer?.prepareToPlay()
                tapPlayer?.play()
            } catch {
                // If playback fails, ignore
            }
        } else {
            tapPlayer?.currentTime = 0.0
            tapPlayer?.play()
        }
    }

    private func playPhaserDown1Sound() {
        guard let url = Bundle.main.url(forResource: "phaserDown1", withExtension: "m4a") else { return }
        do {
            phaserDown1Player = try AVAudioPlayer(contentsOf: url)
            phaserDown1Player?.volume = 1.0
            phaserDown1Player?.prepareToPlay()
            phaserDown1Player?.play()
        } catch {
            // If playback fails, ignore
        }
    }
    
    private func playPhaserDown2Sound() {
        guard let url = Bundle.main.url(forResource: "phaserDown2", withExtension: "m4a") else { return }
        do {
            phaserDown2Player = try AVAudioPlayer(contentsOf: url)
            phaserDown2Player?.volume = 1.0
            phaserDown2Player?.prepareToPlay()
            phaserDown2Player?.play()
        } catch {
            // If playback fails, ignore
        }
    }
    
    private func playPhaserDown3Sound() {
        guard let url = Bundle.main.url(forResource: "phaserDown3", withExtension: "m4a") else { return }
        do {
            phaserDown3Player = try AVAudioPlayer(contentsOf: url)
            phaserDown3Player?.volume = 1.0
            phaserDown3Player?.prepareToPlay()
            phaserDown3Player?.play()
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

