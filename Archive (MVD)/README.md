# AR Vocals Visualizer

## Project Overview

The AR Vocals Visualizer is an augmented reality application that transforms the way we interact with and understand vocal music. The app uses the iPhone camera and identifies singers in real-time and then overlays visual representations of their pitch directly above their heads. 

### Key Features (planned, not final)
- **Real-Time Pitch Detection**: Uses the microphone to analyze singing pitch and displays it in real time.
- **Augmented Reality Overlay**: Utilizes ARKit or unity to overlay pitch information above the singer's head as viewed through the iPhone's screen.
- **Solo and Duo Mode (Future Development)**: Initially supports a single singer, but can be multiple.
- **Sound Localization (Future Development)**: Future versions will incorporate sound localization to accurately attribute pitch visuals in environments with multiple singers.

## Technology Stack
- **ARKit**: Leverages ARKit for augmented reality overlays, providing a seamless integration of digital content with the real world.
- **Core Audio**: Utilizes Core Audio for real-time audio processing and pitch detection.
- **SceneKit**: Used with ARKit to  render 3D pitch visualization graphics.
- **SwiftUI**: For building a user-friendly interface on ios.

## APIs and Libraries
- **AudioKit**: An audio synthesis, processing, and analysis library, used here primarily for accurate pitch detection.
- **AVFoundation**: For managing audio capture sessions and microphone input.

## Development Plan

### MVP
- Real-time pitch detection for a single singer with a simple visual overlay.

### Future Developments
- Separate visualizations for two singers based on sound localization.
- Enhanced graphical representation of pitch, volume, and timbre.


# MVD

# How to run
- Install the AR-Final folder onto your computer
- Open the file [text](AR-Final/AR-Final.xcodeproj) with XCode 15
- Run it on an Apple device equipped with developer mode and iOS 17

## Current MVD Progress

- I have spent the most time learning swift, and debugging and package management took the most time, but I have gotten most of this done in the most recent few hours
- I have successfully integrated AudioKit and AVFoundation
- I have successfully integrated the camera and am working on implementing a human-recognition library
- I have integrated ARKit, but have not displayed the AR letters, as I will do that after the human-recognition library


## Video Demo Description
- The video DemoARFinalMVD.mov is a brief demo of the current functionalities of the app
- It does not have audio, because I couldn't record the screen and have the app function at the same time
- It shows the current camera and pitch detection integration

## Next Steps
- If the human-recognition library integration works without many issues, I will integrate this with the shazam API to display song lyrics as well
