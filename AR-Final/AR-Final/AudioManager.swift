import AudioKit
import AVFoundation
import AudioKitEX
import SoundpipeAudioKit
import Combine
import SwiftUI

class AudioManager: ObservableObject {
    @Published var currentPitch: String = "NA"
    @Published var currentAmplitude: Float = 0.0
    @Published var zDistance: Float = -0.2
    @Published var currentMetallic: Float = 0.0
    @Published var currentRoughness: Float = 1.0
    @Published var currentEmissive: CGFloat = 0.0
    @Published var currentOpacity: CGFloat = 1.0
    @Published var isEmissive: Bool = false
    @Published var currentScale: SIMD3<Float> = SIMD3<Float>(0.01, 0.01, 0.01)  // Initial location offset for AR text
    @Published var currentColor: Color = .white 
    @Published var currentFontSize: CGFloat = 10
    @Published var currentExtrusionDepth: Float = 10
    @Published var currentSensitivity: Float = 1
    @Published var currentMinDepth: Float = 0

    var engine = AudioEngine()
    var mic: AudioEngine.InputNode!
    var tracker: PitchTap!
    var silence: Fader!

    init() {
        setupAudioSession()
        setupAudioComponents()
        startAudioProcessing()
    }

    private func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetoothA2DP])
            try audioSession.setActive(true)
            print("Audio session configured for play and record.")
        } catch {
            print("Failed to configure audio session: \(error.localizedDescription)")
        }
    }

    private func setupAudioComponents() {
        guard let input = engine.input else {
            fatalError("Audio input could not be initialized")
        }
        mic = input
        let mixer = Mixer(mic)
        silence = Fader(mixer, gain: 0)
        engine.output = silence

        tracker = PitchTap(mic) { [weak self] pitch, amp in
            DispatchQueue.main.async {
                let note = self?.frequencyToNoteName(frequency: pitch[0], amplitude: amp[0]) ?? "N/A"
                self?.currentPitch = note
                self?.currentAmplitude = Float(amp[0])
//                print(note)
//                print(amp[0])
            }
        }
    }

    func startAudioProcessing() {
        do {
            try engine.start()
            tracker.start()
            print("Audio engine and pitch tracking started successfully.")
        } catch {
            print("Error starting audio processing: \(error.localizedDescription)")
        }
    }

    func frequencyToNoteName(frequency: Float, amplitude: Float) -> String {
        guard frequency > 0 else {
            return "N/A"
        }
        guard amplitude > 0.05 else {
            return "N/A"
        }

        let A4 = 440.0
        let C0 = A4 * pow(2, -4.75)
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

        let halfStepsFromC0 = round(12 * log2(Double(frequency) / C0))
        let noteIndex = Int(halfStepsFromC0) % 12
        let octave = Int(halfStepsFromC0 / 12) - 1

        let correctedNoteIndex = (noteIndex + 12) % 12
        return "\(noteNames[correctedNoteIndex])\(octave)"
    }

    // Methods to update material properties
    func updateColor(_ color: Color) {
        DispatchQueue.main.async {
            self.currentColor = color
        }
    }
    
    func updateCurrentScale(value: SIMD3<Float>){
        DispatchQueue.main.async {
            self.currentScale = value
        }
    }

    func updateMetallic(_ value: Float) {
        DispatchQueue.main.async {
            self.currentMetallic = value
        }
    }

    func updateRoughness(_ value: Float) {
        DispatchQueue.main.async {
            self.currentRoughness = value
        }
    }

    func updateFontSize(_ value: CGFloat) {
        DispatchQueue.main.async {
            self.currentFontSize = value * 2
        }
    }
    
    func updateMinDepth(_ value: Float) {
        DispatchQueue.main.async {
            self.currentMinDepth = value
        }
    }
    
    func updateSensitivity(_ value: Float) {
        DispatchQueue.main.async {
            self.currentSensitivity = value
        }
    }
    
    func updateExtrusionDepth(_ value: Float) {
        let calcDepth = self.currentAmplitude * 10 * self.currentSensitivity
        
        if (calcDepth < self.currentMinDepth){
            self.currentExtrusionDepth = self.currentMinDepth
        } else {
            self.currentExtrusionDepth = calcDepth
        }
        
        
        DispatchQueue.main.async {
            self.currentExtrusionDepth = self.currentAmplitude * 10
        }

    }
}
