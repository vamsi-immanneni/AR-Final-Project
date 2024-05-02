import ReplayKit
import SwiftUI

// Not used because it removes the mic for use in the app
class ScreenRecorder: ObservableObject {
    private let recorder = RPScreenRecorder.shared()

    @Published var isRecording = false

    func startRecording() {
        guard recorder.isAvailable else {
            print("Screen recording is not available at the moment.")
            return
        }
        
        recorder.startRecording { [weak self] (error) in
            DispatchQueue.main.async {
                if let error = error {
                    print("Failed to start recording: \(error)")
                } else {
                    print("Recording started successfully.")
                    self?.isRecording = true
                }
            }
        }
    }

    func stopRecording() {
        recorder.stopRecording { [weak self] (previewController, error) in
            DispatchQueue.main.async {
                if let error = error {
                    print("Failed to stop recording: \(error)")
                } else {
                    print("Recording stopped successfully.")
                    self?.isRecording = false
                }
            }
        }
    }
}
