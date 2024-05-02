import SwiftUI
import RealityKit

struct ContentView: View {
    @StateObject var audioManager = AudioManager()
    @State private var useFrontCamera = false
//    @State private var isRecording = false // State to toggle recording
    @State private var showMenu = true // State to toggle menu visibility
    @State private var color: Color = .white
//    @EnvironmentObject var videoRecorder: VideoRecorder // Not yet implemented

    var body: some View {
        VStack {
            if showMenu {
                menuContent
            }
            
            ARViewContainer(useFrontCamera: $useFrontCamera)
                .edgesIgnoringSafeArea(.all)
                .environmentObject(audioManager)
        }
        .overlay(
            BottomBar, alignment: .bottom
        )
    }

    var BottomBar: some View {
        HStack {
            Button(action: {
                withAnimation { showMenu.toggle() }
            }) {
                Image(systemName: showMenu ? "chevron.down" : "chevron.up")
                    .font(.title)
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .clipShape(Circle())
            }
            .padding(.leading, 20)
            
            Spacer()
            Button(action: takeSnapshot) {
                Image(systemName: "camera.circle")
                    .font(.largeTitle)
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .clipShape(Circle())
                    .foregroundColor(.white)
            }
            
//            Spacer()
//            Button(action: {
//                Permissions.checkCameraPermissions { cameraAllowed in
//                    Permissions.checkMicrophonePermissions { micAllowed in
//                        if cameraAllowed && micAllowed {
//                            
//                            isRecording.toggle()
//                            if isRecording {
//                                print("Recording started")
//                                videoRecorder.startRecording()
//                            } else {
//                                print("Recording ended")
//                                videoRecorder.stopRecording()
//                            }
//                        } else {
//                            // Handle the case where permissions are not granted
//                            print("Camera or microphone access not granted")
//                        }
//                    }
//                }
//            }) {
//                Image(systemName: isRecording ? "record.circle.fill" : "record.circle")
//                    .font(.system(size: 50))
//                    .foregroundColor(isRecording ? .red : .white)
//            }
            
            
            Spacer()
            Button(action: {
                useFrontCamera.toggle()
            }) {
                Image(systemName: "camera.rotate")
                    .font(.title)
                    .foregroundColor(.white)
            }
            .padding(.trailing, 20)
        }
        .frame(height: 80)
        .background(Color.black.opacity(0.5))
        .edgesIgnoringSafeArea(.all)
    }
    
    func takeSnapshot() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        guard let arView = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController?.view as? ARView else { return }
        
        print("taking snap")

        arView.snapshot(saveToHDR: false) { image in
            DispatchQueue.main.async {
                if let image = image {
                    print("image saved")
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                }
            }
        }
    }

    var menuContent: some View {
        VStack {
            ColorPicker("Color", selection: $color)
                .padding()
                .onChange(of: color) { newValue in
                    audioManager.updateColor(newValue)
                }
            
            MaterialControlsView()
                .environmentObject(audioManager)
        }
    }
}

struct MaterialControlsView: View {
    @EnvironmentObject var audioManager: AudioManager
    @State private var metallic: Double = 0
    @State private var roughness: Double = 1
    @State private var fontSize: Double = 1
    @State private var minDepth: Double = 1
    @State private var sensitivity: Double = 1
    

    var body: some View {
        Form {
            Slider(value: $metallic, in: 0...1, step: 0.01) {
                
            } onEditingChanged: { _ in
                audioManager.updateMetallic(Float(metallic))
            }
            Text("Metallic: \(Int(metallic * 100))%")
            
            Slider(value: $roughness, in: 0...1, step: 0.01) {
                
            } onEditingChanged: { _ in
                audioManager.updateRoughness(Float(roughness))
            }
            Text("Roughness: \(Int(roughness * 100))%")
            
            Slider(value: $fontSize, in: 1...10, step: 1) {
                
            } onEditingChanged: { _ in
                audioManager.updateFontSize(CGFloat(fontSize))
            }
            Text("Font Size: \(Int(fontSize * 4))")
            
            Slider(value: $minDepth, in: 0...10, step: 1) {
                
            } onEditingChanged: { _ in
                audioManager.updateMinDepth(Float(minDepth))
            }
            Text("Minimum Depth: \(Int(minDepth))")
            
            Slider(value: $sensitivity, in: 0...10, step: 1) {
                
            } onEditingChanged: { _ in
                audioManager.updateSensitivity(Float(sensitivity))
            }
            Text("Sound Sensitivity: \(Int(sensitivity * 4))X")
            
            
        }
    }
}

