# ThirdSign
An iOS device sideloading tool ZSign ported to iOS using C++ and bridging headers.

I made this to prove how it was possible to exploit signing capibilities on iOs and install apps locally
with an http proxy.

![image](https://github.com/user-attachments/assets/0711023a-942c-4a88-bf31-71831e473c30)
![image](https://github.com/user-attachments/assets/27be89e8-f2c1-4ca0-924d-73e23db0eb43)


## Installation Instructions
1. Go to the releases tab and download the latest app zip file.

2. Extract the zip and open the .xcodeproj file.

3. In the Signing and Capabilities section in the main project change the signing team to your own developer account.

4. Build the app and run it. Using a simulator will not work to do both file importing apps and the package files being built for iOS.
