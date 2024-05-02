import SwiftUI

@main
struct ARFinal_App: App {
    @StateObject private var screenRecorder = ScreenRecorder()  // Owns the VideoRecorder
    @StateObject private var audioManager = AudioManager()    // Owns the AudioManager

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(screenRecorder)  // Provides the object down the view hierarchy
                .environmentObject(audioManager)   // Provides the object down the view hierarchy
        }
    }
}
