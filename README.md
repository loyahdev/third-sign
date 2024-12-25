# ThirdSign
An iOS device sideloading tool ZSign ported to iOS using C++ and bridging headers.

I made this to prove how it was possible to exploit signing capibilities on iOS and install apps locally
with an http proxy.

![Untitled design-33](https://github.com/user-attachments/assets/95454acb-5a1f-4bd1-b2b5-6786ec1643d3)
![Untitled design-34](https://github.com/user-attachments/assets/a479c3d8-810e-47ac-81df-7d50a6d170cf)

## Installation Instructions
1. Go to the releases tab and download the latest app zip file.

2. Extract the zip and open the .xcodeproj file.

3. In the Signing and Capabilities section in the main project change the signing team to your own developer account.

4. Build the app and run it. Using a simulator will not work due to do both importing apps and the package files being built for iOS.
