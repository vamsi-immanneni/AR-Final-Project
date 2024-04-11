import SwiftUI
import ARKit
import RealityKit

struct ContentView: View {
    @StateObject var audioManager = AudioManager()

    var body: some View {
        VStack {
            Text("Current Pitch: \(audioManager.currentPitch)")
                .padding()
                .foregroundColor(.white)
                .background(Color.blue)
                .cornerRadius(10)

            Text("Current Amplitude: \(audioManager.currentAmplitude)")
                .padding()
                .foregroundColor(.white)
                .background(Color.green)
                .cornerRadius(10)

            ARViewContainer()
                .edgesIgnoringSafeArea(.all)
        }
    }
}


struct ARViewContainer: UIViewRepresentable {
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        let configuration = ARWorldTrackingConfiguration()
        arView.session.run(configuration)
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        // Update AR view if necessary
    }
}
