import AudioKit
import AVFoundation
import AudioKitEX
import SoundpipeAudioKit
import Combine

class AudioManager: ObservableObject {
    @Published var currentPitch: String = "NA"
    @Published var currentAmplitude: String = "NA"

    var engine = AudioEngine()
    var mic: AudioEngine.InputNode!
    var tracker: PitchTap!
    var silence: Fader!
    var timer: Timer?

    init() {
        setupAudioSession()
        setupAudioComponents()
        startAudioProcessing() // Make sure to start processing upon initialization
        setupTimer() // Setup a timer to update data every second
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
                self?.currentAmplitude = "\(amp[0])"
                print("Note: \(note), Amplitude: \(amp[0])")
            }
        }

        print("PitchTap and audio components are configured.")
    }

    private func updatePitchAndAmplitude(pitch: AUValue, amplitude: AUValue) {
        currentPitch = pitch > 1 ? "\(pitch) Hz" : "NA"
        currentAmplitude = "\(amplitude)"
        print("Updated Pitch: \(currentPitch), Amplitude: \(currentAmplitude)")
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

    func stopAudioProcessing() {
        tracker.stop()
        engine.stop()
        print("Audio processing stopped.")
    }

    private func setupTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.simulateDataUpdate()
        }
    }

    private func simulateDataUpdate() {
        print("Simulated update - Pitch: \(currentPitch), Amplitude: \(currentAmplitude)")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        timer?.invalidate()
        stopAudioProcessing()
        print("AudioManager is being deinitialized.")
    }
    
    func frequencyToNoteName(frequency: Float, amplitude: Float) -> String {
        guard frequency > 0 else {
            return "N/A"  // Handle non-positive frequencies as "Not Applicable".
        }
        guard amplitude > 0.05 else {
            return "N/A"  // Handle too quiet notes
        }

        let A4 = 440.0
        let C0 = A4 * pow(2, -4.75)  // Calculate the frequency of C0 from A4
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

        let halfStepsFromC0 = round(12 * log2(Double(frequency)  / C0))
        let noteIndex = Int(halfStepsFromC0) % 12
        let octave = Int(halfStepsFromC0 / 12) - 1  // Adjusted for the C0 base octave

        // Ensure noteIndex wraps correctly by handling negative indices
        let correctedNoteIndex = (noteIndex + 12) % 12

        return "\(noteNames[correctedNoteIndex])\(octave)"
    }

}
