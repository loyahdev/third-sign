# ThirdSign
An iOS device sideloading tool ZSign ported to iOS using C++ and bridging headers.

I made this to prove how it was possible to exploit signing capibilities on iOs and install apps locally
with an http proxy.

## Installation Instructions
1. Go to the releases tab and download the latest app zip file.

2. Extract the zip and open the .xcodeproj file

3. In the Signing and Capabilities section in the main project change the signing team to your own developer account.

4. Build the app and run it. Using a simulator will not work to do both file importing app installing
