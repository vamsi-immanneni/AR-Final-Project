import SwiftUI
import ARKit
import RealityKit
import Combine

struct ARViewContainer: UIViewRepresentable {
    @EnvironmentObject var audioManager: AudioManager
    @Binding var useFrontCamera: Bool
//    @Binding var isRecording: Bool // Add a binding to track recording state, not implemented

    func makeCoordinator() -> Coordinator {
        Coordinator(arView: ARView(frame: .zero), audioManager: audioManager)
    }
    
    func captureSnapshot(_ arView: ARView, completion: @escaping (UIImage?) -> Void) {
        arView.snapshot(saveToHDR: false) { image in
            completion(image)
        }
    }

    func makeUIView(context: Context) -> ARView {
        let arView = context.coordinator.arView
        setupGestures(arView: arView, context: context)
        updateConfiguration(for: arView, usingFrontCamera: useFrontCamera)
        arView.session.delegate = context.coordinator
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        updateConfiguration(for: uiView, usingFrontCamera: useFrontCamera)
    }

    private func updateConfiguration(for arView: ARView, usingFrontCamera: Bool) {
        let configuration = usingFrontCamera ? ARFaceTrackingConfiguration() : ARBodyTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    // Gestures for pinching and dragging (panning)
    func setupGestures(arView: ARView, context: Context) {
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        panGesture.minimumNumberOfTouches = 2
        panGesture.maximumNumberOfTouches = 2
        arView.addGestureRecognizer(panGesture)

        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        arView.addGestureRecognizer(pinchGesture)
    }
    
    

    // Coordinates AR text
    class Coordinator: NSObject, ARSessionDelegate, UIGestureRecognizerDelegate {
        var arView: ARView
        var audioManager: AudioManager
        var textEntity: ModelEntity?
        var textAnchor: AnchorEntity?
        var cancellables = Set<AnyCancellable>()

        init(arView: ARView, audioManager: AudioManager) {
            self.arView = arView
            self.audioManager = audioManager
            super.init()
            setupTextEntity()
            subscribeToUpdates()
        }
        
        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            guard let faceAnchor = anchors.compactMap({ $0 as? ARFaceAnchor }).first else {
                return
            }
            
            // This is to match the face orientation
            DispatchQueue.main.async {
                self.updateTextEntityTransform(with: faceAnchor.transform)
            }
        }
        
        func lerp(start: simd_float3, end: simd_float3, t: Float) -> simd_float3 {
            return start + (end - start) * t
        }

        func slerp(start: simd_quatf, end: simd_quatf, t: Float) -> simd_quatf {
            return simd_slerp(start, end, t)
        }
        
        func updateTextEntityTransform(with transform: simd_float4x4) {
            guard let textEntity = textEntity else { return }
            
            let targetPosition = simd_make_float3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z) + audioManager.currentScale
            let targetOrientation = simd_quatf(transform)

            // Apply smoothing
            // Adjust t to control smoothing
            let t = Float(0.1)
            let smoothedPosition = lerp(start: textEntity.position, end: targetPosition, t: t)
            let smoothedOrientation = slerp(start: textEntity.orientation, end: targetOrientation, t: t)

            textEntity.position = smoothedPosition
            textEntity.orientation = smoothedOrientation
        }

        func setupTextEntity() {
            let textMesh = MeshResource.generateText("NA", extrusionDepth: 10, font: .systemFont(ofSize: audioManager.currentFontSize), containerFrame: .zero, lineBreakMode: .byWordWrapping)
            var material = SimpleMaterial()
            material.baseColor = MaterialColorParameter.color(
                UIColor.init(displayP3Red: 1.0, green: 0.0, blue: 0.0, alpha: 0.5)
            )

            
            
            material.metallic = MaterialScalarParameter(floatLiteral: Float(audioManager.currentMetallic))
            material.roughness = MaterialScalarParameter(floatLiteral: Float(audioManager.currentRoughness))

            textEntity = ModelEntity(mesh: textMesh, materials: [material])
            
            
            textAnchor = AnchorEntity()
            textAnchor?.position = simd_make_float3(audioManager.currentScale.x, audioManager.currentScale.y, audioManager.zDistance)
            textEntity?.scale = audioManager.currentScale
            textAnchor?.addChild(textEntity!)
            arView.scene.addAnchor(textAnchor!)
            

//            textAnchor = AnchorEntity(world: simd_float4x4(
//                SIMD4<Float>(1, 0, 0, 0),
//                SIMD4<Float>(0, 1, 0, 0),
//                SIMD4<Float>(0, 0, 1, 0),
//                SIMD4<Float>(audioManager.currentScale.x, audioManager.currentScale.y, audioManager.zDistance, 1)
//            ))
//            textEntity?.scale = audioManager.currentScale
//            textAnchor?.addChild(textEntity!)
//            arView.scene.addAnchor(textAnchor!)
            
            
        }

        // Some of AudioManager updates
        func subscribeToUpdates() {
            audioManager.$currentColor.sink { [weak self] newColor in
                self?.updateMaterialColor(newColor)
            }.store(in: &cancellables)

            audioManager.$currentFontSize.sink { [weak self] newSize in
                self?.updateTextFont(size: newSize)
            }.store(in: &cancellables)
            
            audioManager.$currentAmplitude.sink { [weak self] newDepth in
                self?.audioManager.updateExtrusionDepth(newDepth)
                self?.updateTextDepth(size: newDepth)
            }.store(in: &cancellables)
            
            
            audioManager.$currentMetallic.sink { [weak self] curMet in
                let roughness = self?.audioManager.currentRoughness ?? 0.0
                self?.updateMetRough(met: curMet, rough: roughness)
            }.store(in: &cancellables)
            
            audioManager.$currentRoughness.sink { [weak self] curRough in
                let met = self?.audioManager.currentMetallic ?? 0.0
                self?.updateMetRough(met: met, rough: curRough)
            }.store(in: &cancellables)
            
            
        }
        
        func updateMetRough(met: Float, rough: Float){
            let newTextMesh = MeshResource.generateText(audioManager.currentPitch, extrusionDepth: audioManager.currentExtrusionDepth, font: .systemFont(ofSize: audioManager.currentFontSize))
            textEntity?.model?.mesh = newTextMesh
            
            if let material = textEntity?.model?.materials.first as? SimpleMaterial {
                var updatedMaterial = material
                
                // Update the metallic and roughness properties
                updatedMaterial.metallic = MaterialScalarParameter(floatLiteral: Float(met))
                updatedMaterial.roughness = MaterialScalarParameter(floatLiteral: Float(rough))

                textEntity?.model?.materials = [updatedMaterial]
            }
        }

        func updateMaterialColor(_ newColor: Color) {
            var alpha: CGFloat = 0
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            UIColor(newColor).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            
            red = max(0, min(1, red))
            green = max(0, min(1, green))
            blue = max(0, min(1, blue))
            alpha = max(0, min(1, alpha))
            
            
            if let material = textEntity?.model?.materials.first as? SimpleMaterial {
                var updatedMaterial = material
//                updatedMaterial.baseColor = newBaseColor
                print("\(alpha)")
                updatedMaterial.baseColor = MaterialColorParameter.color(
                    UIColor.init(displayP3Red: red, green: green, blue: blue, alpha: alpha*0.99)
                )
                
                print("\(updatedMaterial.metallic)")
                
                print(updatedMaterial.baseColor)
                
                textEntity?.model?.materials = [updatedMaterial]
            }
        }

        func updateTextFont(size: CGFloat) {
            let newTextMesh = MeshResource.generateText(audioManager.currentPitch, extrusionDepth: audioManager.currentExtrusionDepth, font: .systemFont(ofSize: size))
            textEntity?.model?.mesh = newTextMesh
        }
        
        func updateTextDepth(size: Float) {
//            print("update depth to \(audioManager.currentExtrusionDepth)")
            let newTextMesh = MeshResource.generateText(audioManager.currentPitch, extrusionDepth: audioManager.currentExtrusionDepth, font: .systemFont(ofSize: audioManager.currentFontSize))
            textEntity?.model?.mesh = newTextMesh
        }


        @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
            let translation = recognizer.translation(in: arView)
            let translationVector = simd_make_float3(Float(translation.x), -Float(translation.y), 0) * 0.001
            updateTextEntityPosition(with: translationVector)
            audioManager.updateCurrentScale(value: translationVector)
            
            recognizer.setTranslation(CGPoint.zero, in: arView)
            
        }

        @objc func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
            let scale = recognizer.scale
            let deltaZ = (0.1) * (1.0 - scale)
            audioManager.zDistance += Float(deltaZ)
            recognizer.scale = 1.0  // Reset scale to detect incremental changes
            updateTextEntityZPosition()
        }

        func updateTextEntityPosition(with translation: SIMD3<Float>) {
            if let currentAnchor = textEntity?.anchor {
                currentAnchor.position += translation
            }
        }

        func updateTextEntityZPosition() {
            if let currentAnchor = textEntity?.anchor {
                var position = currentAnchor.position
                position.z = audioManager.zDistance
                currentAnchor.position = position
            }
        }
    }
}
