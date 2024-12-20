import SwiftUI
import Foundation
//import Alamofire
import UIKit
import Foundation
//import ZSign
//#include "ZSign.h"
import ZIPFoundation
//import Zip
import Swifter
import UniformTypeIdentifiers
import NotificationBannerSwift

var totalTweaks = 0
var currentSignedTweaks = 0
var globalSideloadingPercentage = 0
var progress = 0
var deviceModel = ""
var globalSideloadingStatus: SideloadingViewModel?
var bannerQueueToDisplaySeveralBanners = NotificationBannerQueue(maxBannersOnScreenSimultaneously: 3)
var banner = FloatingNotificationBanner(title: "Sideloading Starting", subtitle: "Sideloading is currently starting up this wont take long.", style: .info)

class SideloadingViewModel: ObservableObject {
    @Published var sideloadingPercentage = 0

    var totalTweaks: Int = 0
    var currentSignedTweaks: Int = 0 {
        didSet {
            // Update sideloadingPercentage to reflect 10-70% range during signing
            if (currentSignedTweaks != 0) {
                progress = Int(currentSignedTweaks / totalTweaks * 70 + 15) // 70% range for signing + 15% initial offset
            }
            print("progress: \(progress)")
            sideloadingPercentage = Int(progress)
            globalSideloadingPercentage = sideloadingPercentage
        }
    }

    func incrementSignedTweaks() {
        currentSignedTweaks += 1
    }
    
    func resetSignedTweaks() {
        currentSignedTweaks = 0
    }
}

func fetchAndCompareText(from urlString: String, with localString: String) {
    guard let url = URL(string: urlString) else {
        print("Invalid URL")
        return
    }

    let task = URLSession.shared.dataTask(with: url) { data, response, error in
        DispatchQueue.main.async {
            if let error = error {
                print("Error fetching data: \(error.localizedDescription)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Error: Invalid HTTP response")
                return
            }

            guard let data = data, let onlineString = String(data: data, encoding: .utf8) else {
                print("Error: Could not decode data")
                return
            }

            // Compare the fetched string with the local string
            if onlineString != localString {
                DispatchQueue.main.async {
                    banner = FloatingNotificationBanner(title: "Notification", subtitle: "ThirdSign is currently out of date, please download the latest version from our discord.", style: .danger)
                    //banner.autoDismiss = false
                    //banner.dismissOnSwipeUp = true
                    banner.show()
                }
            }
        }
    }
    task.resume()
}

func swiftLogCallback(message: UnsafePointer<CChar>?) {
    guard let messageCStr = message else {
        print("Received a callback with a nil message. (LOG CALLBACK)")
        return
    }
    let messageStr = String(cString: messageCStr)
    print("Received callback message (LOG CALLBACK): \(messageStr)")
    
    // Correctly increment the signed tweaks count
    //DispatchQueue.main.async {
        globalSideloadingStatus?.incrementSignedTweaks()
    //}
        print("Total tweals: \(globalSideloadingStatus!.totalTweaks)")
        print("Incremented signed tweaks. New count: \(globalSideloadingStatus!.currentSignedTweaks)")
        print("Updated sideloading percentage: \(globalSideloadingStatus?.sideloadingPercentage)%")
}

class DeviceViewModel: ObservableObject {
    @Published var deviceModel: String?

    init() {
        fetchDeviceModel()
    }

    func fetchDeviceModel() {
        deviceModel = getDeviceModel()
    }
}

func getDeviceModel() -> String {
    var systemInfo = utsname()
    uname(&systemInfo)
    let machineMirror = Mirror(reflecting: systemInfo.machine)
    let identifier = machineMirror.children.reduce("") { identifier, element in
        guard let value = element.value as? Int8, value != 0 else { return identifier }
        return identifier + String(UnicodeScalar(UInt8(value)))
    }
    return identifier
}


//class SideloadingStatus: ObservableObject {
    //@Published var percentage: Int = 0
//}

/*class SideloadingStatus: ObservableObject {
    static let shared = SideloadingStatus()
    @Published var percentage: Int = 0
}*/

struct ContentView: SwiftUI.View {
    @StateObject private var viewModel = SideloadingViewModel()
    @State private var isFilePickerPresented = false
    @State private var fileImported = false
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedFileURL: URL?
    @State private var openAppURL: URL?
    @State private var isPresentingPopup: Bool = false
    @State private var isPresentingFinished: Bool = false
    @State private var presentingPopupTitle: String = ""
    @State private var observation: NSKeyValueObservation?
    @State private var bundleID: String = ""
    @State private var urlScheme: String = ""
    @State private var bundleIDPopup: Bool = false
    @State private var urlSchemePopup: Bool = false
    @State private var iconData: Data?
    @State private var showIconAlert = false
    
    @State private var extractedPath: String = ""
    @State private var extractedPathPopup: Bool = false
    @State private var customCertToggle: Bool = false
    @State private var tweakInjectToggle: Bool = false
    @State private var customAppToolsToggle: Bool = false
    
    @State private var mobileProvisionImported = false
    @State private var tweakImported = false
    @State private var p12Imported = false
    
    @State private var selectedMobileProvisionURL: URL?
    @State private var selectedTweakURL: URL?
    @State private var selectedP12URL: URL?
    
    @State private var isMobileProvisionFilePickerPresented = false
    @State private var isTweakFilePickerPresented = false
    @State private var isP12FilePickerPresented = false
    
    @State private var p12PasswordInput: String = ""
    @State private var bundleidInput: String = ""
    @State private var appNameInput: String = ""
    @State private var appVersionInput: String = ""
    
    @State private var sheet: Bool = false
    
    @State private var popupDelay: TimeInterval = 0
    
    @State private var server: HttpServer = HttpServer()
    
    @State private var fileSizeMB: Float = 0
    @State private var timer: Timer?
    @State private var startTime: Date?
    @State private var signingTime: Float = 0
    @State private var finalSigningTime: Float = 0
    
    @State private var visSigningPercent = 0
    
    @StateObject private var deviceViewModel = DeviceViewModel()
    
    @State private var customApp: Bool = false
    @State private var customAppLink: String = ""
    @State private var customAppName: String = ""
    @State private var ipaURL = false

    
    func LogToConsole(message: String) {
        print(message)
    }
    
    private var backgroundGradient: some View {
        let lightModeGradient = Gradient(colors: [Color(red: 226 / 255, green: 221 / 255, blue: 242 / 255), .white, .white, Color(red: 0, green: 212 / 255, blue: 1.0)])
        let darkModeGradient = Gradient(colors: [Color(red: 0.1, green: 0.1, blue: 0.15), .black, .black, Color(red: 0, green: 0.5, blue: 0.5)])
        
        return LinearGradient(
            gradient: colorScheme == .dark ? darkModeGradient : lightModeGradient,
            startPoint: .top,
            endPoint: .bottom
        )
        .edgesIgnoringSafeArea(.all)
    }
    
    private var titleSection: some View {
        HStack(alignment: .center, spacing: 10) {
            Image("ThirdStoreBlack") // Use a SF Symbol for demo purposes
                .resizable()
                .frame(width: 40, height: 40)
                .cornerRadius(10)
                .foregroundColor(colorScheme == .dark ? .white : .black) // Adjusts the icon color based on the color scheme
            
            Text("ThirdSign")
                .font(.system(size: 30))
                .foregroundColor(colorScheme == .dark ? .white : .black) // Adjusts the text color based on the color scheme
                //.onAppear {
                    //sideloadingStatus.setupCallback()
                //}
                .onAppear {
                    globalSideloadingStatus = viewModel
                    registerSwiftLogCallback(swiftLogCallback)
                }

        }
        .padding(.vertical, 20)
    }
    
    private var contentList: some View {
        List {
            // Your List content here
            // Make sure to adjust text and icon colors similar to the titleSection
        }
        .listStyle(PlainListStyle())
        .foregroundColor(colorScheme == .dark ? .white : .black)
    }
    
    private var settingsButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gear")
                        .font(.system(size: 32))
                        .foregroundColor(colorScheme == .dark ? .white : .black) // Adjusts the icon color based on the color scheme
                        .padding()
                        .background(Circle().fill(colorScheme == .dark ? Color.black : Color.white))
                        .shadow(radius: 4)
                }
                .padding()
            }
        }
    }
    
    // ... (Other properties remain the same)
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient
                
                VStack(spacing: 0) {
                    //.padding(.bottom, 15) // Adjust padding as needed*/
                    
                    titleSection
                    
                    // The List
                    List {
                        //Text("Estimated signing time: \(signingTime) seconds")
                        Text("Final signing time: \(finalSigningTime) seconds")
                            .onAppear {
                                // Usage
                                deviceModel = getDeviceModel()
                                //print("Device model identifier: \(deviceModel)")
                                let localString = "1.0.1" // Local string to compare
                                let urlString = "https://sideloading.thirdstore.app/version.txt" // URL of the online text file
                                // Call the function
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    fetchAndCompareText(from: urlString, with: localString)
                                }
                            }
                        Text("Current signing percentage: \(globalSideloadingPercentage)%")//, specifier: "%.1f")%")
                        /*Button("Test Increase Percentage") {
                         DispatchQueue.main.async { // TODO: Figure out why I need both of these to update the percentage
                         globalSideloadingPercentage += 10
                         globalSideloadingStatus?.sideloadingPercentage += 10
                         }
                         }*/
                        /*Section(header: Text("Socials")) {
                            HStack {
                                Button(action:  {
                                    if let url = URL(string: "https://discord.gg/nocturna-team-1144047674614616135") {
                                        //DispatchQueue.main.async {
                                        UIApplication.shared.open(url)
                                        //}
                                    }
                                }) {
                                    HStack {
                                        AsyncImage(url: URL(string: "https://static-00.iconduck.com/assets.00/discord-icon-2048x2048-o5mluhz2.png")) { image in
                                            image.resizable()
                                        } placeholder: {
                                            ProgressView()
                                        }
                                        .frame(width: 35, height: 35)
                                        .cornerRadius(15.00)
                                        VStack(alignment: .leading) {
                                            Text("ThirdStore")
                                                .font(.system(size: 18, weight: .bold))
                                                .fontWeight(.semibold)
                                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                                .multilineTextAlignment(/*@START_MENU_TOKEN@*/.leading/*@END_MENU_TOKEN@*/)
                                            Text("Join our discord for new app updates and news!")
                                                .font(.system(size: 15, weight: .bold))
                                                .fontWeight(.semibold)
                                                .foregroundColor(.gray)
                                                .multilineTextAlignment(/*@START_MENU_TOKEN@*/.leading/*@END_MENU_TOKEN@*/)
                                        }
                                    }
                                }
                            }
                        }
                        .listRowBackground(Color.clear)
                        .foregroundColor(colorScheme == .dark ? .white : .black)*/
                        
                        Section(header: Text("Setup")) {
                            VStack(alignment: .leading, spacing: 0) {
                                Toggle("Switch to Direct IPA URL", isOn: $ipaURL)
                                    .padding(.bottom, 10)
                                
                                Divider()
                                    .padding(.bottom, 10)
                                
                                if ipaURL {
                                    // Text input field
                                    TextField("Enter your direct link here", text: $customAppName)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        //.onChange(of: ipaURL, selectedFileURL = true)
                                    //.padding()
                                } else {
                                    // File import button
                                    Button(action: {
                                        isFilePickerPresented = true
                                    }) {
                                        HStack {
                                            Image(systemName: "shippingbox.fill")
                                                .resizable()
                                                .frame(width: 20.0, height: 20.0)
                                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                            
                                            VStack(alignment: .leading) {
                                                Text("Import IPA")
                                                    .fontWeight(.bold)
                                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                                
                                                if fileImported == false {
                                                    Text("File Not Imported.")
                                                        .font(.caption)
                                                        .fontWeight(.semibold)
                                                        .foregroundColor(Color.red)
                                                        .multilineTextAlignment(.leading)
                                                } else {
                                                    if (customApp == false) {
                                                        Text("File Imported.")
                                                            .font(.caption)
                                                            .fontWeight(.semibold)
                                                            .foregroundColor(Color.green)
                                                            .multilineTextAlignment(.leading)
                                                        Text(selectedFileURL?.absoluteString ?? "No file selected.")
                                                            .font(.system(size: 8, weight: .semibold, design: .rounded))
                                                            .foregroundColor(.secondary)
                                                            .multilineTextAlignment(.leading)
                                                    } else {
                                                        Text("IPA Ready to Download.")
                                                            .font(.caption)
                                                            .fontWeight(.semibold)
                                                            .foregroundColor(Color.green)
                                                            .multilineTextAlignment(.leading)
                                                        Text(customAppName)
                                                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                                                            .foregroundColor(.secondary)
                                                            .multilineTextAlignment(.leading)
                                                        Text(customAppLink)
                                                            .font(.system(size: 8, weight: .semibold, design: .rounded))
                                                            .foregroundColor(.secondary)
                                                            .multilineTextAlignment(.leading)
                                                    }
                                                    
                                                }
                                            }
                                        }
                                    }
                                    /*.sheet(isPresented: $isFilePickerPresented) {
                                        IPAFileDocumentPicker(isPresented: $isFilePickerPresented, fileImported: $fileImported, selectedFileURL: $selectedFileURL, customApp: $customApp)
                                            .edgesIgnoringSafeArea(.bottom)
                                    }*/
                                }
                            }
                            .onChange(of: ipaURL) { newScenePhase in
                                print(newScenePhase)
                                if ipaURL == true {
                                    fileImported = true
                                }
                                else if (selectedFileURL == nil && ipaURL == false) {
                                    fileImported = false
                                }
                            }
                            .sheet(isPresented: $isFilePickerPresented) {
                                IPAFileDocumentPicker(isPresented: $isFilePickerPresented, fileImported: $fileImported, selectedFileURL: $selectedFileURL, customApp: $customApp)
                                    .edgesIgnoringSafeArea(.bottom)
                            }
                            /*.fileImporter(isPresented: $isFilePickerPresented, allowedContentTypes: [.item]) { result in
                             do {
                             selectedFileURL = try result.get()
                             
                             // Check if the selected file has a .ipa extension
                             if selectedFileURL?.pathExtension.lowercased() == "ipa" {
                             if let fileURL = selectedFileURL {
                             if fileURL.startAccessingSecurityScopedResource() {
                             defer { fileURL.stopAccessingSecurityScopedResource() }
                             fileImported = true
                             } else {
                             print("Could not access the security-scoped resource.")
                             }
                             }
                             } else {
                             // Handle the case where the file has an unsupported extension
                             print("Unsupported file extension. Please select a .ipa file.")
                             }
                             } catch {
                             print("File selection failed: \(error.localizedDescription)")
                             }
                             }*/
                        }
                        .listRowBackground(Color.clear)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        
                        
                        Section(header: Text("Sideloading")) {
                            /*
                             Button(action: {
                             if let url = URL(string: "https://flux.loyahdev.me/flux-dns") {
                             UIApplication.shared.open(url)
                             }
                             }) {
                             HStack {
                             Image(systemName: "firewall.fill")
                             .resizable()
                             .frame(width: 20.0, height: 25)
                             Text("Install DNS (Block Revokes, Etc)")
                             .font(.system(size: 17, weight: .bold))
                             .fontWeight(.semibold)
                             }
                             }
                             */
                            
                            HStack {
                                Image(systemName: "scroll.fill")
                                    .resizable()
                                    .frame(width: 20.0, height: 20)
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                Toggle(isOn: $customCertToggle) {
                                    Text("Custom Certificate")
                                        .font(.system(size: 17, weight: .bold))
                                        .fontWeight(.semibold)
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                    //.foregroundColor(Color.primary)
                                }
                                
                            }
                            if customCertToggle {
                                Button(action: {
                                    isMobileProvisionFilePickerPresented = true
                                }) {
                                    VStack(alignment: .leading) {
                                        HStack {
                                            Image(systemName: "filemenu.and.selection")
                                                .resizable()
                                                .frame(width: 15, height: 15)
                                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                            Text("Import .mobileprovision")
                                                .font(.system(size: 14, weight: .light))
                                                .fontWeight(.semibold)
                                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                        }
                                        if mobileProvisionImported == false {
                                            Text("File Not Imported.")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .foregroundColor(Color.red)
                                                .multilineTextAlignment(.leading)
                                        } else {
                                            Text("File Imported.")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .foregroundColor(Color.green)
                                                .multilineTextAlignment(.leading)
                                            
                                            //                                        Text(selectedFileURL?.absoluteString ?? "No file selected.")
                                            //                                                .font(.caption)
                                            //                                                .fontWeight(.semibold)
                                            //                                                .foregroundColor(.green)
                                            //                                                .multilineTextAlignment(.leading)
                                        }
                                    }
                                }
                                .sheet(isPresented: $isMobileProvisionFilePickerPresented) {
                                    MPFileDocumentPicker(isPresented: $isMobileProvisionFilePickerPresented, fileImported: $mobileProvisionImported, selectedFileURL: $selectedMobileProvisionURL)
                                        .edgesIgnoringSafeArea(.bottom)
                                }
                                /*.fileImporter(isPresented: $isMobileProvisionFilePickerPresented, allowedContentTypes: [.item]) { result in
                                 do {
                                 selectedMobileProvisionURL = try result.get()
                                 
                                 // Check if the selected file has a .p12 extension
                                 if selectedMobileProvisionURL?.pathExtension.lowercased() == "mobileprovision" {
                                 let fileManager = FileManager.default
                                 let documentsDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                                 
                                 // Create a destination URL in the app's document directory
                                 let destinationURL = documentsDirectory.appendingPathComponent(selectedMobileProvisionURL!.lastPathComponent)
                                 
                                 // Request access to the selected file
                                 if selectedMobileProvisionURL!.startAccessingSecurityScopedResource() {
                                 defer { selectedMobileProvisionURL!.stopAccessingSecurityScopedResource() }
                                 
                                 try? fileManager.removeItem(at: destinationURL)
                                 
                                 // Copy the file to the destination URL
                                 try fileManager.copyItem(at: selectedMobileProvisionURL!, to: destinationURL)
                                 
                                 // Now, you can use destinationURL for further processing if needed
                                 print("File copied to: \(destinationURL)")
                                 
                                 selectedMobileProvisionURL = destinationURL
                                 mobileProvisionImported = true
                                 clearOldFilesInDocuments()
                                 } else {
                                 print("Could not access the security-scoped resource.")
                                 }
                                 } else {
                                 // Handle the case where the file has an unsupported extension
                                 print("Unsupported file extension. Please select a .mobileprovision file.")
                                 }
                                 } catch {
                                 print("File selection failed: \(error.localizedDescription)")
                                 }
                                 }*/
                                Button(action: {
                                    isP12FilePickerPresented = true
                                }) {
                                    VStack(alignment: .leading) {
                                        HStack {
                                            Image(systemName: "filemenu.and.selection")
                                                .resizable()
                                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                                .frame(width: 15, height: 15)
                                            Text("Import .p12")
                                                .font(.system(size: 14, weight: .light))
                                                .fontWeight(.semibold)
                                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                        }
                                        if p12Imported == false {
                                            Text("File Not Imported.")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .foregroundColor(Color.red)
                                                .multilineTextAlignment(.leading)
                                        } else {
                                            Text("File Imported.")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .foregroundColor(Color.green)
                                                .multilineTextAlignment(.leading)
                                        }
                                    }
                                }
                                .sheet(isPresented: $isP12FilePickerPresented) {
                                    P12FileDocumentPicker(isPresented: $isP12FilePickerPresented, fileImported: $p12Imported, selectedFileURL: $selectedP12URL)
                                        .edgesIgnoringSafeArea(.bottom)
                                }
                                /*.fileImporter(isPresented: $isP12FilePickerPresented, allowedContentTypes: [.item]) { result in
                                 do {
                                 selectedP12URL = try result.get()
                                 
                                 // Check if the selected file has a .p12 extension
                                 if selectedP12URL?.pathExtension.lowercased() == "p12" {
                                 let fileManager = FileManager.default
                                 let documentsDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                                 
                                 // Create a destination URL in the app's document directory
                                 let destinationURL = documentsDirectory.appendingPathComponent(selectedP12URL!.lastPathComponent)
                                 
                                 // Request access to the selected file
                                 if selectedP12URL!.startAccessingSecurityScopedResource() {
                                 defer { selectedP12URL!.stopAccessingSecurityScopedResource() }
                                 
                                 // Attempt to remove the file at the destination URL (if it exists)
                                 try? fileManager.removeItem(at: destinationURL)
                                 
                                 // Copy the file to the destination URL
                                 try fileManager.copyItem(at: selectedP12URL!, to: destinationURL)
                                 
                                 // Now, you can use destinationURL for further processing if needed
                                 print("File copied to: \(destinationURL)")
                                 
                                 selectedP12URL = destinationURL
                                 p12Imported = true
                                 } else {
                                 print("Could not access the security-scoped resource.")
                                 }
                                 } else {
                                 // Handle the case where the file has an unsupported extension
                                 print("Unsupported file extension. Please select a .p12 file.")
                                 }
                                 } catch {
                                 print("File selection failed: \(error.localizedDescription)")
                                 }
                                 }*/
                                
                                TextField("Enter p12 Password", text: $p12PasswordInput) {
                                    Text("Enter p12 Password")
                                    //.font(.caption)
                                    //.fontWeight(.semibold)
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                        //.foregroundColor(.white)
                                        .multilineTextAlignment(.leading)
                                }
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            /*if customAppToolsToggle {
                                TextField(text: $appNameInput) {
                                    Text("Enter App Name")
                                    //.font(.caption)
                                    //.fontWeight(.semibold)
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                        //.foregroundColor(.white)
                                        .multilineTextAlignment(.leading)
                                }
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                
                                TextField(text: $appVersionInput) {
                                    Text("Enter App Version")
                                    //.font(.caption)
                                    //.fontWeight(.semibold)
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                        //.foregroundColor(.white)
                                        .multilineTextAlignment(.leading)
                                }
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                
                                TextField(text: $bundleidInput) {
                                    Text("Enter bundle ID")
                                    //.font(.caption)
                                    //.fontWeight(.semibold)
                                        .foregroundColor(.gray)
                                        //.foregroundColor(.white)
                                        .multilineTextAlignment(.leading)
                                }
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            */
                            
                            HStack {
                                Image(systemName: "doc.fill.badge.plus")
                                    .resizable()
                                    .frame(width: 20.0, height: 20)
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                Toggle(isOn: $tweakInjectToggle) {
                                    Text("Inject Tweak")
                                        .font(.system(size: 17, weight: .bold))
                                        .fontWeight(.semibold)
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                    //.foregroundColor(Color.primary)
                                }
                            }
                            if tweakInjectToggle {
                                Button(action: {
                                    isTweakFilePickerPresented = true
                                }) {
                                    VStack(alignment: .leading) {
                                        HStack {
                                            Image(systemName: "filemenu.and.selection")
                                                .resizable()
                                                .frame(width: 15, height: 15)
                                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                            Text("Import .dylib or .deb")
                                                .font(.system(size: 14, weight: .light))
                                                .fontWeight(.semibold)
                                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                        }
                                        if tweakImported == false {
                                            Text("File Not Imported.")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .foregroundColor(Color.red)
                                                .multilineTextAlignment(.leading)
                                        } else {
                                            Text("File Imported.")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .foregroundColor(Color.green)
                                                .multilineTextAlignment(.leading)
                                            
                                            //                                        Text(selectedFileURL?.absoluteString ?? "No file selected.")
                                            //                                                .font(.caption)
                                            //                                                .fontWeight(.semibold)
                                            //                                                .foregroundColor(.green)
                                            //                                                .multilineTextAlignment(.leading)
                                        }
                                    }
                                }
                                .sheet(isPresented: $isTweakFilePickerPresented) {
                                    TweakFileDocumentPicker(isPresented: $isTweakFilePickerPresented, fileImported: $tweakImported, selectedFileURL: $selectedTweakURL)
                                        .edgesIgnoringSafeArea(.bottom)
                                }
                                /*.fileImporter(isPresented: $isTweakFilePickerPresented, allowedContentTypes: [.item]) { result in
                                 do {
                                 selectedTweakURL = try result.get()
                                 
                                 // Check if the selected file has a .p12 extension
                                 if selectedTweakURL?.pathExtension.lowercased() == "dylib" || selectedTweakURL?.pathExtension.lowercased() == "deb" {
                                 let fileManager = FileManager.default
                                 let documentsDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                                 
                                 // Create a destination URL in the app's document directory
                                 let destinationURL = documentsDirectory.appendingPathComponent(selectedTweakURL!.lastPathComponent)
                                 
                                 // Request access to the selected file
                                 if selectedTweakURL!.startAccessingSecurityScopedResource() {
                                 defer { selectedTweakURL!.stopAccessingSecurityScopedResource() }
                                 
                                 try? fileManager.removeItem(at: destinationURL)
                                 
                                 // Copy the file to the destination URL
                                 try fileManager.copyItem(at: selectedTweakURL!, to: destinationURL)
                                 
                                 // Now, you can use destinationURL for further processing if needed
                                 print("File copied to: \(destinationURL)")
                                 
                                 selectedTweakURL = destinationURL
                                 FixSubstrate(destinationURL.path)
                                 tweakImported = true
                                 clearOldFilesInDocuments()
                                 } else {
                                 print("Could not access the security-scoped resource.")
                                 }
                                 } else {
                                 // Handle the case where the file has an unsupported extension
                                 print("Unsupported file extension. Please select a tweak file.")
                                 }
                                 } catch {
                                 print("File selection failed: \(error.localizedDescription)")
                                 }
                                 }*/
                            }
                            
                            Button(action: {
                                fileImported = false
                                clearOldFilesInDocuments()
                                //clearAllFilesInDocuments()
                                DispatchQueue.main.async {
                                    banner.dismiss()
                                    banner.autoDismiss = true
                                    banner = FloatingNotificationBanner(title: "Sideloading Starting", subtitle: "Sideloading is currently starting up this wont take long.", style: .info)
                                    banner.show()
                                }
                                
                                print("Custom app name: \(customAppName), IPAURL: \(ipaURL)")
                                if (customAppName != "" && customAppName.contains("https://") && ipaURL == true) {
                                    customAppLink = customAppName
                                    customApp = true
                                }
                                else if (!customAppName.contains("https://") && ipaURL == true) {
                                    DispatchQueue.main.async {
                                        banner.dismiss()
                                        banner.autoDismiss = true
                                        banner = FloatingNotificationBanner(title: "Sideloading Error", subtitle: "The direct IPA URL you input is invalid.", style: .danger)
                                        banner.show()
                                    }
                                    //self.selectedFileURL = nil
                                    fileImported = true
                                    return
                                }
                                
                                if (!customApp) {
                                    guard let fileURL = self.selectedFileURL else {
                                        print("No file selected.")
                                        return
                                    }
                                    
                                    /*if !fileURL.startAccessingSecurityScopedResource() {
                                     print("Could not access fileURL.")
                                     return
                                     }*/
                                    
                                    let p12KeyURL = URL(string: "https://raw.githubusercontent.com/loyahdev/certificates/main/Certificates.p12")!
                                    //let certURL = URL(string: "https://raw.githubusercontent.com/loyahdev/certificates/main/Certificates.p12")! // Assuming it's the same file as p12KeyURL
                                    let provisioningProfileURL = URL(string: "https://raw.githubusercontent.com/loyahdev/certificates/main/Certificates.mobileprovision")!
                                    
                                    // Call the downloadFiles function with the URLs and a completion handler.
                                    // Assuming this is within an async context
                                    if (!customCertToggle) {
                                        Task {
                                            let success = await downloadFiles(p12KeyURL: p12KeyURL, provisioningProfileURL: provisioningProfileURL)
                                            if !success {
                                                print("An error occurred during download.")
                                                DispatchQueue.main.async {
                                                    banner.dismiss()
                                                    banner = FloatingNotificationBanner(title: "Sideloading Failed", subtitle: "The certificate download was unable to be completed.", style: .danger)
                                                    banner.show()
                                                }
                                                
                                                /*DispatchQueue.main.async {
                                                 currentSignedTweaks = 0
                                                 totalTweaks = 0
                                                 globalSideloadingPercentage = 0
                                                 globalSideloadingStatus?.sideloadingPercentage = 0
                                                 progress = 0
                                                 }*/
                                                return
                                            }
                                            else {
                                                //}
                                                
                                                /*DispatchQueue.main.async {
                                                 currentSignedTweaks = 0
                                                 globalSideloadingPercentage = 0
                                                 globalSideloadingStatus?.sideloadingPercentage = 0
                                                 }*/
                                                fileSizeMB = 0
                                                signingTime = 0
                                                finalSigningTime = 0
                                                visSigningPercent = 0
                                                globalSideloadingStatus = viewModel
                                                currentSignedTweaks = 0
                                                totalTweaks = 1
                                                globalSideloadingPercentage = 0
                                                globalSideloadingStatus?.sideloadingPercentage = 0
                                                globalSideloadingStatus?.resetSignedTweaks()
                                                progress = 0
                                                
                                                DispatchQueue.main.async {
                                                    fileSizeMB = 0
                                                    signingTime = 0
                                                    finalSigningTime = 0
                                                    visSigningPercent = 0
                                                    globalSideloadingStatus = viewModel
                                                    currentSignedTweaks = 0
                                                    totalTweaks = 1
                                                    globalSideloadingPercentage = 0
                                                    globalSideloadingStatus?.resetSignedTweaks()
                                                    globalSideloadingStatus?.sideloadingPercentage = 0
                                                    progress = 0
                                                }
                                                
                                                //globalSideloadingPercentage = 7
                                                
                                                
                                                // Move the async operation into a Task to avoid blocking the main thread.
                                                //Task {
                                                DispatchQueue.global(qos: .utility).async {
                                                    let success = sideloading(ipaFilePath: fileURL, selectedTweakPath: (selectedTweakURL ?? fileURL))
                                                    //DispatchQueue.main.async {
                                                    fileURL.stopAccessingSecurityScopedResource()
                                                    
                                                    if success {
                                                        print("Sideloading success")
                                                        selectedFileURL = nil
                                                        // globalSideloadingPercentage = 100
                                                    } else {
                                                        print("Sideloading failed.")
                                                    }
                                                    //}
                                                }
                                            }
                                        }
                                    }
                                    else {
                                        fileSizeMB = 0
                                        signingTime = 0
                                        finalSigningTime = 0
                                        visSigningPercent = 0
                                        globalSideloadingStatus = viewModel
                                        currentSignedTweaks = 0
                                        totalTweaks = 1
                                        globalSideloadingPercentage = 0
                                        globalSideloadingStatus?.sideloadingPercentage = 0
                                        globalSideloadingStatus?.resetSignedTweaks()
                                        progress = 0
                                        
                                        DispatchQueue.main.async {
                                            fileSizeMB = 0
                                            signingTime = 0
                                            finalSigningTime = 0
                                            visSigningPercent = 0
                                            globalSideloadingStatus = viewModel
                                            currentSignedTweaks = 0
                                            totalTweaks = 1
                                            globalSideloadingPercentage = 0
                                            globalSideloadingStatus?.resetSignedTweaks()
                                            globalSideloadingStatus?.sideloadingPercentage = 0
                                            progress = 0
                                        }
                                        
                                        //globalSideloadingPercentage = 7
                                        
                                        
                                        // Move the async operation into a Task to avoid blocking the main thread.
                                        //Task {
                                        DispatchQueue.global(qos: .utility).async {
                                            let success = sideloading(ipaFilePath: fileURL, selectedTweakPath: (selectedTweakURL ?? fileURL))
                                            //DispatchQueue.main.async {
                                            fileURL.stopAccessingSecurityScopedResource()
                                            
                                            if success {
                                                print("Sideloading success")
                                                selectedFileURL = nil
                                                // globalSideloadingPercentage = 100
                                            } else {
                                                print("Sideloading failed.")
                                            }
                                            //}
                                        }
                                    }
                                } else {
                                    downloadFileAndSideload(from: customAppLink)
                                }
                            }) {
                                HStack {
                                    Image(systemName: "apps.iphone.badge.plus")
                                        .resizable()
                                        .frame(width: 20.0, height: 25)
                                    //.foregroundColor(.gray)
                                    Text("Sideload IPA")
                                        .font(.system(size: 17, weight: .bold))
                                        .fontWeight(.semibold)
                                    //.foregroundColor(.gray)
                                }
                            }
                            .disabled(!fileImported)
                            
                            
                            
                            //SideloadingLoading(popupTitle: presentingPopupTitle)
                            .alert(isPresented: $isPresentingPopup) {
                                // Define the alert
                                Alert(
                                    title: Text("Sideloading Notification"),
                                    message: Text(presentingPopupTitle),
                                    dismissButton: .default(Text("Close")) {
                                        // Action to perform when the "Close" button is tapped
                                        // For example, you could change some state here if needed
                                        print("Close button tapped")
                                    }
                                )
                            }
                            /*
                             .sheet(isPresented: $isPresentingFinished) {
                             // Content of the sheet
                             Text("Thank you for sideloading using Nocturna, your app should be installing now.")
                             }
                             */
                            /*.alert(isPresented: $isPresentingFinished) { // TODO: come back to this
                             // Define the alert
                             Alert(
                             title: Text("Sideloading Complete"),
                             message: Text("Thank you for sideloading using Nocturna, your app should be installing now."),
                             dismissButton: .default(Text("Close")) {
                             // Action to perform when the "Close" button is tapped
                             // For example, you could change some state here if needed
                             print("Close button tapped")
                             }
                             )
                             }*/
                        }
                        .listRowBackground(Color.clear)
                        //.foregroundColor(.black)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        
                        Section(header: Text("Advanced"))
                        {
                            Button(action:  {
                                if let fileURL = selectedFileURL {
                                    if fileURL.startAccessingSecurityScopedResource() {
                                        defer { fileURL.stopAccessingSecurityScopedResource() }
                                        let filePath = fileURL
                                        extractIPAPayload(ipaFilePath: filePath) { success, payloadPath in
                                            if success, let path = payloadPath {
                                                print("Payload folder path: \(path.path)")
                                                extractedPath = path.path
                                                //countDylibsAndFrameworks(inPayloadFolderPath: extractedPath)
                                                extractedPathPopup = true
                                            } else {
                                                print("Extraction failed.")
                                            }
                                        }
                                    }
                                }
                            }) {
                                HStack {
                                    Image(systemName: "filemenu.and.selection")
                                        .resizable()
                                        .frame(width: 20.0, height: 20)
                                        .foregroundColor(.gray)
                                    Text("View Extracted IPA Path")
                                        .font(.system(size: 17, weight: .bold))
                                        .fontWeight(.semibold)
                                        .foregroundColor(.gray)
                                }
                            }
                            .alert(isPresented: $extractedPathPopup) {
                                Alert(
                                    title: Text("Extracted IPA Path"),
                                    message: Text(extractedPath + "\n\nYour app is extracted in our apps private directory, if you would like to view it please use a jailbreak and go to this destination."),
                                    dismissButton: .default(Text("OK"))
                                )
                            }
                        }
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .listRowBackground(Color.clear)
                        .disabled(!fileImported)
                        
                        Section(header: Text("Tools")) {
                            //if customAppToolsToggle {
                                TextField(text: $appNameInput) {
                                    Text("Enter App Name")
                                    //.font(.caption)
                                    //.fontWeight(.semibold)
                                        .foregroundColor(.gray)
                                        //.foregroundColor(.white)
                                        .multilineTextAlignment(.leading)
                                }
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                
                                TextField(text: $appVersionInput) {
                                    Text("Enter App Version")
                                    //.font(.caption)
                                    //.fontWeight(.semibold)
                                        .foregroundColor(.gray)
                                        //.foregroundColor(.white)
                                        .multilineTextAlignment(.leading)
                                }
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                
                                TextField(text: $bundleidInput) {
                                    Text("Enter bundle ID")
                                    //.font(.caption)
                                    //.fontWeight(.semibold)
                                        .foregroundColor(.gray)
                                        //.foregroundColor(.white)
                                        .multilineTextAlignment(.leading)
                                }
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            //}
                        }
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .listRowBackground(Color.clear)
                        
                        Section(header: Text("Credits")) {
                            VStack(alignment: .leading) {
                                // Link for Loyahdev
                                //Link(destination: URL(string: "https://loyahdev.me/")!) {
                                    HStack {
                                        AsyncImage(url: URL(string: "https://avatars.githubusercontent.com/u/68242406?v=4")) { image in
                                            image.resizable()
                                        } placeholder: {
                                            ProgressView()
                                        }
                                        .frame(width: 50, height: 50)
                                        .cornerRadius(15.00)
                                        VStack(alignment: .leading) {
                                            Text("Loyahdev")
                                                .font(.system(size: 18, weight: .bold))
                                                .fontWeight(.semibold)
                                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                            Text("Developer")
                                                .font(.system(size: 15, weight: .bold))
                                                .fontWeight(.semibold)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                //}
                                Divider()
                                
                                // Link for AppInstaller iOS
                                //Link(destination: URL(string: "https://github.com/AppInstalleriOSGH")!) {
                                    HStack {
                                        AsyncImage(url: URL(string: "https://avatars.githubusercontent.com/u/98632439?v=4")) { image in
                                            image.resizable()
                                        } placeholder: {
                                            ProgressView()
                                        }
                                        .frame(width: 50, height: 50)
                                        .cornerRadius(15.00)
                                        VStack(alignment: .leading) {
                                            Text("AppInstaller iOS")
                                                .font(.system(size: 18, weight: .bold))
                                                .fontWeight(.semibold)
                                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                            Text("Sideloading Contributions")
                                                .font(.system(size: 15, weight: .bold))
                                                .fontWeight(.semibold)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                //}
                                Divider()
                                
                                // Link for DebianArch64
                                //Link(destination: URL(string: "https://github.com/DebianArch64")!) {
                                    HStack {
                                        AsyncImage(url: URL(string: "https://cdn.discordapp.com/avatars/367344736069222400/3b0845d262767830e41da81299fcbe60?size=1024")) { image in
                                            image.resizable()
                                        } placeholder: {
                                            ProgressView()
                                        }
                                        .frame(width: 50, height: 50)
                                        .cornerRadius(15.00)
                                        VStack(alignment: .leading) {
                                            Text("DebianArch")
                                                .font(.system(size: 18, weight: .bold))
                                                .fontWeight(.semibold)
                                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                            Text("Sideloading Guidance")
                                                .font(.system(size: 15, weight: .bold))
                                                .fontWeight(.semibold)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                //}
                            }
                        }
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .listRowBackground(Color.clear)
                        
                        HStack(alignment: .center) {
                            Spacer()
                            Text("hello daddy broco eat")
                                .font(.system(size: 15, weight: .bold))
                                .fontWeight(.semibold)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(/*@START_MENU_TOKEN@*/.leading/*@END_MENU_TOKEN@*/)
                            Divider()
                            if let model = deviceViewModel.deviceModel, !model.isEmpty {
                                Text(model)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.leading)
                            } else {
                                ProgressView()
                            }
                            Spacer()
                        }
                        .background(Color.clear)
                        .listRowBackground(Color.clear)
                        .foregroundColor(Color.clear)
                    }
                    .listStyle(PlainListStyle())
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                }
                    
                    //.background(LinearGradient(gradient: Gradient(colors: [Color(red: 193 / 255, green: 176 / 255, blue: 204 / 255), Color(red: 1.0, green:
                /*.background(
                 LinearGradient(
                 gradient: Gradient(stops: [
                 .init(color: Color(red: 226 / 255, green: 221 / 255, blue: 242 / 255), location: 0.0), // Start of gradient
                 .init(color: Color.white, location: 0.13), // Midpoint of gradient
                 .init(color: Color.white, location: 0.8), // Midpoint of gradient
                 .init(color: Color(red: 0, green: 212 / 255, blue: 1.0), location: 1.0) // End of gradient
                 ]),
                 startPoint: .top,
                 endPoint: .bottom
                 )
                 )*/
                //.edgesIgnoringSafeArea(.all)
                //.navigationBarHidden(true)
                
                // Settings button anchored to the bottom right
                VStack {
                    Spacer() // Pushes everything to the bottom
                    
                    HStack {
                        Spacer() // Pushes everything to the right
                        NavigationLink(destination: SettingsView()) {
                            /*Image(systemName: "gear")
                             .font(.system(size: 32))
                             .padding([.vertical, .horizontal], 8)
                             .background(Circle().fill(Color.black))
                             .foregroundColor(.white)
                             .shadow(radius: 4)*/
                        }
                        .padding() // Adjust padding to move the button inward from the screen edges as desired
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }
    
    func downloadFileAndSideload(from urlString: String) {
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        DispatchQueue.main.async {
            banner.dismiss()
            banner.autoDismiss = true
            banner = FloatingNotificationBanner(title: "Sideloading Starting", subtitle: "Your IPA file is currently being downloaded please be patient.", style: .info)
            banner.show()
            globalSideloadingPercentage = 7
            globalSideloadingStatus?.sideloadingPercentage = 7
        }
        globalSideloadingPercentage = 7
        globalSideloadingStatus?.sideloadingPercentage = 7
        
        let task = URLSession.shared.downloadTask(with: url) { localURL, response, error in
            guard let localURL = localURL else {
                print("Error downloading file: \(error?.localizedDescription ?? "Unknown error")")
                DispatchQueue.main.async {
                    banner.dismiss()
                    banner.autoDismiss = true
                    banner = FloatingNotificationBanner(title: "Sideloading Error", subtitle: "Error downloading file: \(error?.localizedDescription ?? "Unknown error")", style: .danger)
                    banner.show()
                    //globalSideloadingPercentage = 7
                    //globalSideloadingStatus?.sideloadingPercentage = 7
                    fileImported = true
                }
                return
            }
            
            do {
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let destinationURL = documentsPath.appendingPathComponent("downloaded-file.ipa")
                
                self.selectedFileURL = destinationURL
                
                // Check if file exists and remove it before copying a new file
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                
                try FileManager.default.moveItem(at: localURL, to: destinationURL)
                print("File saved to documents directory!")
        
        guard let fileURL = self.selectedFileURL else {
            print("No file selected.")
            return
        }
        
        /*if !fileURL.startAccessingSecurityScopedResource() {
         print("Could not access fileURL.")
         return
         }*/
        
        let p12KeyURL = URL(string: "https://raw.githubusercontent.com/loyahdev/certificates/main/Certificates.p12")!
        //let certURL = URL(string: "https://raw.githubusercontent.com/loyahdev/certificates/main/Certificates.p12")! // Assuming it's the same file as p12KeyURL
        let provisioningProfileURL = URL(string: "https://raw.githubusercontent.com/loyahdev/certificates/main/Certificates.mobileprovision")!
        
        // Call the downloadFiles function with the URLs and a completion handler.
        // Assuming this is within an async context
        if (!customCertToggle) {
            Task {
                let success = await downloadFiles(p12KeyURL: p12KeyURL, provisioningProfileURL: provisioningProfileURL)
                if !success {
                    print("An error occurred during download.")
                    DispatchQueue.main.async {
                        banner.dismiss()
                        banner = FloatingNotificationBanner(title: "Sideloading Failed", subtitle: "The certificate download was unable to be completed.", style: .danger)
                        banner.show()
                    }
                    
                    /*DispatchQueue.main.async {
                     currentSignedTweaks = 0
                     totalTweaks = 0
                     globalSideloadingPercentage = 0
                     globalSideloadingStatus?.sideloadingPercentage = 0
                     progress = 0
                     }*/
                    return
                }
                else {
                    //}
                    
                    /*DispatchQueue.main.async {
                     currentSignedTweaks = 0
                     globalSideloadingPercentage = 0
                     globalSideloadingStatus?.sideloadingPercentage = 0
                     }*/
                    fileSizeMB = 0
                    signingTime = 0
                    finalSigningTime = 0
                    visSigningPercent = 0
                    globalSideloadingStatus = viewModel
                    currentSignedTweaks = 0
                    totalTweaks = 1
                    globalSideloadingPercentage = 0
                    globalSideloadingStatus?.sideloadingPercentage = 0
                    globalSideloadingStatus?.resetSignedTweaks()
                    progress = 0
                    
                    DispatchQueue.main.async {
                        fileSizeMB = 0
                        signingTime = 0
                        finalSigningTime = 0
                        visSigningPercent = 0
                        globalSideloadingStatus = viewModel
                        currentSignedTweaks = 0
                        totalTweaks = 1
                        globalSideloadingPercentage = 0
                        globalSideloadingStatus?.resetSignedTweaks()
                        globalSideloadingStatus?.sideloadingPercentage = 0
                        progress = 0
                    }
                    
                    //globalSideloadingPercentage = 7
                    
                    
                    // Move the async operation into a Task to avoid blocking the main thread.
                    //Task {
                    DispatchQueue.global(qos: .utility).async {
                        let success = sideloading(ipaFilePath: fileURL, selectedTweakPath: (selectedTweakURL ?? fileURL))
                        //DispatchQueue.main.async {
                        fileURL.stopAccessingSecurityScopedResource()
                        
                        if success {
                            print("Sideloading success")
                            selectedFileURL = nil
                            // globalSideloadingPercentage = 100
                        } else {
                            print("Sideloading failed.")
                        }
                        //}
                    }
                }
            }
        }
                else {
                    fileSizeMB = 0
                    signingTime = 0
                    finalSigningTime = 0
                    visSigningPercent = 0
                    globalSideloadingStatus = viewModel
                    currentSignedTweaks = 0
                    totalTweaks = 1
                    globalSideloadingPercentage = 0
                    globalSideloadingStatus?.sideloadingPercentage = 0
                    globalSideloadingStatus?.resetSignedTweaks()
                    progress = 0
                    
                    DispatchQueue.main.async {
                        fileSizeMB = 0
                        signingTime = 0
                        finalSigningTime = 0
                        visSigningPercent = 0
                        globalSideloadingStatus = viewModel
                        currentSignedTweaks = 0
                        totalTweaks = 1
                        globalSideloadingPercentage = 0
                        globalSideloadingStatus?.resetSignedTweaks()
                        globalSideloadingStatus?.sideloadingPercentage = 0
                        progress = 0
                    }
                    
                    //globalSideloadingPercentage = 7
                    
                    
                    // Move the async operation into a Task to avoid blocking the main thread.
                    //Task {
                    DispatchQueue.global(qos: .utility).async {
                        let success = sideloading(ipaFilePath: fileURL, selectedTweakPath: (selectedTweakURL ?? fileURL))
                        //DispatchQueue.main.async {
                        fileURL.stopAccessingSecurityScopedResource()
                        
                        if success {
                            print("Sideloading success")
                            selectedFileURL = nil
                            // globalSideloadingPercentage = 100
                        } else {
                            print("Sideloading failed.")
                        }
                        //}
                    }
                }
            } catch {
                print("File move error: \(error.localizedDescription)")
            }
        }
        
        task.resume()
    }
    
    enum AppExtractionError: Error {
        case appFolderNotFound
    }
    
    func extractIPAPayload(ipaFilePath: URL, completion: @escaping (Bool, URL?) -> Void) {
        let ipaPath = ipaFilePath
        print("IPA path: \(ipaPath.path)")

        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Documents directory not found")
            completion(false, nil)
            return
        }

        let destinationPath = documentsDirectory
        let payloadPath = destinationPath.appendingPathComponent("Payload")

        // Check if the Payload folder already exists
        if fileManager.fileExists(atPath: payloadPath.path) {
            do {
                // Attempt to delete the existing Payload folder
                try fileManager.removeItem(at: payloadPath)
                print("Deleted existing Payload folder")
            } catch {
                print("Failed to delete existing Payload folder: \(error)")
                completion(false, nil)
                return
            }
        }

        print("Destination path for extraction: \(destinationPath.path)")

        do {
            try fileManager.unzipItem(at: ipaPath, to: destinationPath)
            print("Extraction successful at \(destinationPath.path)")
            completion(true, payloadPath)
        } catch {
            print("Extraction failed: \(error)")
            completion(false, nil)
        }
    }
    
    func createPlistFile(fromContent content: String) -> String? {
        // Getting the path to the Documents directory
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Documents directory not found")
            return nil
        }
        
        // Define the file path
        let plistFilePath = documentsDirectory.appendingPathComponent("install.plist")
        
        // Convert the string to Data
        guard let data = content.data(using: .utf8) else {
            print("Failed to convert string to Data")
            return nil
        }
        
        // Write the data to the file
        do {
            try data.write(to: plistFilePath, options: .atomic)
            print("Plist file created at: \(plistFilePath.path)")
            return plistFilePath.path
        } catch {
            print("Error writing plist file: \(error)")
            return nil
        }
    }
    
    func clearOldFilesInDocuments() {
        let fileManager = FileManager.default
        do {
            guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
                print("Documents directory not found")
                return
            }
            
            let filePaths = try fileManager.contentsOfDirectory(atPath: documentsDirectory.path)
            
            for filePath in filePaths {
                if filePath == "debugger.ipa" || filePath == "install.plist" || filePath == "nocturna-cert.p12" || filePath == "nocturna-cert.mobileprovision" || filePath == "Payload" || filePath == "._Payload" || filePath == "__MACOSX" || filePath == "downloaded-file.ipa" {
                    let fullFilePath = documentsDirectory.appendingPathComponent(filePath).path
                    do {
                        try fileManager.removeItem(atPath: fullFilePath)
                        print("(clearOldFilesInDocuments) File \(filePath) has been deleted.")
                    } catch {
                        print("Error deleting file \(filePath): \(error)")
                    }
                }
            }
        } catch {
            print("Error accessing documents directory: \(error)")
        }
    }
    
    func downloadFiles(p12KeyURL: URL, provisioningProfileURL: URL) async -> Bool {
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Documents directory not found")
            return false
        }

        // Helper function to download and store file
        func downloadAndStore(url: URL, to destinationUrl: URL) async -> Bool {
            do {
                let (tempLocalUrl, _) = try await URLSession.shared.download(from: url)
                try fileManager.copyItem(at: tempLocalUrl, to: destinationUrl)
                return true
            } catch {
                print("Download or save failed for \(url): \(error)")
                return false
            }
        }

        // Prepare file URLs
        let p12KeyLocalUrl = documentsDirectory.appendingPathComponent("nocturna-cert.p12")
        let provisioningProfileLocalUrl = documentsDirectory.appendingPathComponent("nocturna-cert.mobileprovision")

        // Perform downloads
        let downloadP12 = await downloadAndStore(url: p12KeyURL, to: p12KeyLocalUrl)
        let downloadProvisioningProfile = await downloadAndStore(url: provisioningProfileURL, to: provisioningProfileLocalUrl)
        
        // Return true if all downloads were successful
        return downloadP12 && downloadProvisioningProfile
    }
    
    func clearAllFilesInDocuments() {
        let fileManager = FileManager.default
        do {
            guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
                print("Documents directory not found")
                return
            }

            let filePaths = try fileManager.contentsOfDirectory(atPath: documentsDirectory.path)

            for filePath in filePaths {
                let fullFilePath = documentsDirectory.appendingPathComponent(filePath).path
                do {
                    try fileManager.removeItem(atPath: fullFilePath)
                    print("(clearAllFilesInDocuments) File \(filePath) has been deleted.")
                } catch {
                    print("Error deleting file \(filePath): \(error)")
                }
            }
        } catch {
            print("Error accessing documents directory: \(error)")
        }
    }

    
    func extractBundleId(fromPayloadFolder payloadFolderPath: String) -> String {
        let fileManager = FileManager.default
        let payloadURL = URL(fileURLWithPath: payloadFolderPath, isDirectory: true)
        
        //countDylibsAndFrameworks(inPayloadFolderPath: payloadFolderPath)
        
        // Assuming the app's .app folder will be directly inside the Payload folder
        guard let enumerator = fileManager.enumerator(at: payloadURL, includingPropertiesForKeys: nil, options: [], errorHandler: nil),
              let appFolderURL = enumerator.allObjects.first(where: { ($0 as? URL)?.pathExtension == "app" }) as? URL else {
            print("Failed to locate the .app folder within the payload.")
            return "Error: .app folder not found"
        }
        
        let infoPlistURL = appFolderURL.appendingPathComponent("Info.plist")
        
        // Check if Info.plist exists at the expected path
        guard fileManager.fileExists(atPath: infoPlistURL.path) else {
            print("Info.plist not found in the app bundle.")
            return "Error: Info.plist not found"
        }
        
        // Read the contents of Info.plist
        guard let infoPlistData = try? Data(contentsOf: infoPlistURL),
              let infoPlist = try? PropertyListSerialization.propertyList(from: infoPlistData, options: [], format: nil) as? [String: Any],
              let bundleID = infoPlist["CFBundleIdentifier"] as? String else {
            print("Failed to read the bundle identifier from Info.plist.")
            return "Error: Bundle ID not found"
        }
        
        // Return the bundle ID
        return bundleID
    }
    
    func extractBundleVersion(fromPayloadFolder payloadFolderPath: String) -> String {
        let fileManager = FileManager.default
        let payloadURL = URL(fileURLWithPath: payloadFolderPath, isDirectory: true)
        
        // Assuming the app's .app folder will be directly inside the Payload folder
        guard let enumerator = fileManager.enumerator(at: payloadURL, includingPropertiesForKeys: nil, options: [], errorHandler: nil),
              let appFolderURL = enumerator.allObjects.first(where: { ($0 as? URL)?.pathExtension == "app" }) as? URL else {
            print("Failed to locate the .app folder within the payload.")
            return "Error: .app folder not found"
        }
        
        let infoPlistURL = appFolderURL.appendingPathComponent("Info.plist")
        
        // Check if Info.plist exists at the expected path
        guard fileManager.fileExists(atPath: infoPlistURL.path) else {
            print("Info.plist not found in the app bundle.")
            return "Error: Info.plist not found"
        }
        
        // Read the contents of Info.plist
        guard let infoPlistData = try? Data(contentsOf: infoPlistURL),
              let infoPlist = try? PropertyListSerialization.propertyList(from: infoPlistData, options: [], format: nil) as? [String: Any],
              let bundleVersion = infoPlist["CFBundleVersion"] as? String else {
            print("Failed to read the bundle version from Info.plist.")
            return "Error: Bundle Version not found"
        }
        
        // Return the bundle version
        return bundleVersion
    }
    
    func extractUrlScheme(fromPayloadFolder payloadFolderPath: String) -> String {
        let fileManager = FileManager.default
        let payloadURL = URL(fileURLWithPath: payloadFolderPath, isDirectory: true)
        
        // Assuming the app's .app folder will be directly inside the Payload folder
        guard let enumerator = fileManager.enumerator(at: payloadURL, includingPropertiesForKeys: nil, options: [], errorHandler: nil),
              let appFolderURL = enumerator.allObjects.first(where: { ($0 as? URL)?.pathExtension == "app" }) as? URL else {
            print("Failed to locate the .app folder within the payload.")
            return "Error: .app folder not found"
            DispatchQueue.main.async {
                banner.dismiss()
                banner = FloatingNotificationBanner(title: "Sideloading Failed", subtitle: ".app folder not found", style: .danger)
                banner.show()
            }
        }
        
        let infoPlistURL = appFolderURL.appendingPathComponent("Info.plist")
        
        // Check if Info.plist exists at the expected path
        guard fileManager.fileExists(atPath: infoPlistURL.path) else {
            print("Info.plist not found in the app bundle.")
            DispatchQueue.main.async {
                banner.dismiss()
                banner = FloatingNotificationBanner(title: "Sideloading Failed", subtitle: "Info.plist not found in the app bundle.", style: .danger)
                banner.show()
            }
            return "Error: Info.plist not found"
        }
        
        // Read the contents of Info.plist
        guard let infoPlistData = try? Data(contentsOf: infoPlistURL),
              let infoPlist = try? PropertyListSerialization.propertyList(from: infoPlistData, options: [], format: nil) as? [String: Any],
              let urlSchemes = infoPlist["CFBundleURLTypes"] as? [[String: Any]],
              let firstUrlScheme = urlSchemes.first,
              let urlScheme = firstUrlScheme["CFBundleURLSchemes"] as? [String],
              let firstScheme = urlScheme.first else {
            print("Failed to read the URL scheme from Info.plist.")
            DispatchQueue.main.async {
                banner.dismiss()
                banner = FloatingNotificationBanner(title: "Sideloading Failed", subtitle: "Failed to read the URL scheme from Info.plist.", style: .danger)
                banner.show()
            }
            return "Error: URL scheme not found"
        }
        
        // Return the URL scheme
        return firstScheme
    }
    
    @discardableResult
    func extractAppIcon(fromPayloadFolder payloadFolderPath: String) -> String? {
        let fileManager = FileManager.default
        let payloadURL = URL(fileURLWithPath: payloadFolderPath, isDirectory: true)
        
        // Assuming the app's .app folder will be directly inside the Payload folder
        guard let enumerator = fileManager.enumerator(at: payloadURL, includingPropertiesForKeys: nil, options: [], errorHandler: nil),
              let appFolderURL = (enumerator.allObjects.first { ($0 as? URL)?.pathExtension == "app" }) as? URL else {
            print("Failed to locate the .app folder within the payload.")
            DispatchQueue.main.async {
                banner.dismiss()
                banner = FloatingNotificationBanner(title: "Sideloading Failed", subtitle: "Failed to locate the .app folder within the payload.", style: .danger)
                banner.show()
            }
            return nil
        }
        
        // Get the contents of the app bundle folder
        guard let appBundleContents = try? fileManager.contentsOfDirectory(at: appFolderURL, includingPropertiesForKeys: nil, options: []) else {
            print("Failed to get the contents of the app bundle.")
            DispatchQueue.main.async {
                banner.dismiss()
                banner = FloatingNotificationBanner(title: "Sideloading Failed", subtitle: "Failed to get the contents of the app bundle.", style: .danger)
                banner.show()
            }
            return nil
        }
        
        // Find all files with names starting with "AppIcon"
        let iconFiles = appBundleContents.filter { $0.lastPathComponent.hasPrefix("AppIcon") }
        
        // Sort the icon files by resolution (assuming file names contain resolution information)
        let sortedIconFiles = iconFiles.sorted { (url1, url2) -> Bool in
            // Extract resolution from file names (merge into the sorting logic)
            let resolution1 = url1.lastPathComponent.components(separatedBy: "-").last?.components(separatedBy: "x").first.flatMap { Int($0) } ?? 0
            let resolution2 = url2.lastPathComponent.components(separatedBy: "-").last?.components(separatedBy: "x").first.flatMap { Int($0) } ?? 0
            
            return resolution1 > resolution2
        }
        
        // Pick the icon file with the highest resolution
        guard let iconFileURL = sortedIconFiles.first,
              fileManager.fileExists(atPath: iconFileURL.path) else {
            print("App icon file not found.")
            DispatchQueue.main.async {
                banner.dismiss()
                banner = FloatingNotificationBanner(title: "Sideloading Failed", subtitle: "App icon file not found.", style: .danger)
                banner.show()
            }
            return nil
        }
        
        // Return the file path of the icon
        return iconFileURL.path
    }
    
    func sideloading(ipaFilePath: URL, selectedTweakPath: URL) -> Bool {
        DispatchQueue.main.async {
            globalSideloadingPercentage = 7
            globalSideloadingStatus?.sideloadingPercentage = 7
        }
        globalSideloadingPercentage = 7
        globalSideloadingStatus?.sideloadingPercentage = 7
        print(ipaFilePath.path)
        startTimer(fileURL: ipaFilePath)
        //clearOldFilesInDocuments()
        server.stop()
        
        let ipaPath = ipaFilePath
        print("IPA path: \(ipaPath.path)")
        
        let fileManager = FileManager.default
        
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Documents directory not found")
            DispatchQueue.main.async {
                banner.dismiss()
                banner = FloatingNotificationBanner(title: "Sideloading Failed", subtitle: "Apps document directory not found.", style: .danger)
                banner.show()
            }
            return false
        }
        
        let destinationPath = documentsDirectory
        print("Destination path for extraction: \(destinationPath.path)")
        
        // Perform potentially heavy I/O operation
        do {
            try FileManager.default.unzipItem(at: ipaPath, to: destinationPath)
            print("Extraction successful at \(destinationPath.path)")
            DispatchQueue.main.async {
                banner.dismiss()
                banner = FloatingNotificationBanner(title: "Sideloading Info", subtitle: "IPA Extraction Complete, now Signing...", style: .info)
                banner.show()
            }
            
            globalSideloadingPercentage = 15
            globalSideloadingStatus?.sideloadingPercentage = 15
            
            // Assuming the app's .app folder will be directly inside the Payload folder
            guard let enumerator = fileManager.enumerator(at: destinationPath, includingPropertiesForKeys: nil, options: [], errorHandler: nil),
                  let appFolderURL = enumerator.allObjects.first(where: { ($0 as? URL)?.pathExtension == "app" }) as? URL else {
                print("Failed to locate the .app folder within the payload.")
                DispatchQueue.main.async {
                    banner.dismiss()
                    banner = FloatingNotificationBanner(title: "Sideloading Failed", subtitle: "Failed to locate the .app folder within the payload.", style: .danger)
                    banner.show()
                }
                return false
            }
            //let appFolderURL = payloadPath.appendingPathComponent("YourApp.app", isDirectory: true) // Replace "YourApp.app" with the actual app directory name
            let infoPlistURL = appFolderURL.appendingPathComponent("Info.plist")
            
            // Check if Info.plist exists at the expected path
            guard fileManager.fileExists(atPath: infoPlistURL.path) else {
                print("Info.plist not found in the app bundle.")
                DispatchQueue.main.async {
                    banner.dismiss()
                    banner = FloatingNotificationBanner(title: "Sideloading Failed", subtitle: "Info.plist not found in the app bundle.", style: .danger)
                    banner.show()
                }
                return false
            }
            
            print(appNameInput)
            
            if (appNameInput != "") {
                // Read and modify the contents of Info.plist
                if var infoPlist = NSDictionary(contentsOf: infoPlistURL) as? [String: Any] {
                    if let appName = infoPlist["CFBundleName"] as? String {
                        print("app name: " + appName)
                    } else {
                        print("CFBundleName key not found or is not a string")
                        DispatchQueue.main.async {
                            banner.dismiss()
                            banner = FloatingNotificationBanner(title: "Sideloading Failed", subtitle: "CFBundleName key not found or is not a CString.", style: .danger)
                            banner.show()
                        }
                    }
                    if let appName = infoPlist["CFBundleDisplayName"] as? String {
                        print("app display name: " + appName)
                    } else {
                        print("CFBundleDisplayName key not found or is not a string")
                        DispatchQueue.main.async {
                            banner.dismiss()
                            banner = FloatingNotificationBanner(title: "Sideloading Failed", subtitle: "CFBundleDisplayName key not found or is not a CString.", style: .danger)
                            banner.show()
                        }
                    }
                    
                    infoPlist["CFBundleName"] = appNameInput
                    infoPlist["CFBundleDisplayName"] = appNameInput
                    (infoPlist as NSDictionary).write(to: infoPlistURL, atomically: true)

                } else {
                    print("Failed to read or modify Info.plist.")
                    DispatchQueue.main.async {
                        banner.dismiss()
                        banner = FloatingNotificationBanner(title: "Sideloading Failed", subtitle: "Failed to read or modify Info.plist.", style: .danger)
                        banner.show()
                    }
                    return false
                }
            }
            if (bundleidInput != "") {
                // Read and modify the contents of Info.plist
                if var infoPlist = NSDictionary(contentsOf: infoPlistURL) as? [String: Any] {
                    if let appName = infoPlist["CFBundleIdentifier"] as? String {
                        print("app bundleid: " + appName)
                        bundleidInput = appName
                    } else {
                        print("CFBundleIndentifier key not found or is not a string")
                        DispatchQueue.main.async {
                            banner.dismiss()
                            banner = FloatingNotificationBanner(title: "Sideloading Failed", subtitle: "CFBundleIdentifier key not found or is not a CString.", style: .danger)
                            banner.show()
                        }
                    }
                    
                    infoPlist["CFBundleIdentifier"] = bundleidInput
                    (infoPlist as NSDictionary).write(to: infoPlistURL, atomically: true)
                    print("App display name changed to \(bundleidInput)")
                } else {
                    print("Failed to read or modify Info.plist.")
                    DispatchQueue.main.async {
                        banner.dismiss()
                        banner = FloatingNotificationBanner(title: "Sideloading Failed", subtitle: "Failed to read or modify Info.plist.", style: .danger)
                        banner.show()
                    }
                    return false
                }
            }
            if (appVersionInput != "") {
                // Read and modify the contents of Info.plist
                if var infoPlist = NSDictionary(contentsOf: infoPlistURL) as? [String: Any] {
                    if let appName = infoPlist["CFBundleVersion"] as? String {
                        print("app version: " + appName)
                    } else {
                        print("CFBundleDisplayName key not found or is not a string")
                        DispatchQueue.main.async {
                            banner.dismiss()
                            banner = FloatingNotificationBanner(title: "Sideloading Failed", subtitle: "CFBundleDisplayName key not found or is not a CString.", style: .danger)
                            banner.show()
                        }
                    }
                    
                    infoPlist["CFBundleVersion"] = appVersionInput
                    (infoPlist as NSDictionary).write(to: infoPlistURL, atomically: true)
                    print("App display name changed to \(appVersionInput)")
                } else {
                    print("Failed to read or modify Info.plist.")
                    DispatchQueue.main.async {
                        banner.dismiss()
                        banner = FloatingNotificationBanner(title: "Sideloading Failed", subtitle: "Failed to read or modify Info.plist.", style: .danger)
                        banner.show()
                    }
                    return false
                }
            }
            
            //fixer
            
            let folderToSign = destinationPath.path
            print("Folder to sign: \(folderToSign)")
            countDylibsAndFrameworks(inPayloadFolderPath: destinationPath.path)
            
            if(!customCertToggle) {
                // If there was no error and all files are presumed to be downloaded successfully
                print("Downloaded files successfully.")
                
                // Proceed with using the downloaded files
                // Ensure file paths are known and directly accessible since downloadFiles no longer provides them.
                // You must manage these paths internally within downloadFiles or manage them globally if needed.
                let p12KeyPath = documentsDirectory.appendingPathComponent("nocturna-cert.p12").path  // Adjust paths according to your actual handling inside downloadFiles
                let provisioningProfilePath = documentsDirectory.appendingPathComponent("nocturna-cert.mobileprovision").path
                
                let provisioningProfileDirectory = documentsDirectory
                
                do {
                    // Retrieve the contents of the directory
                    let directoryContents = try FileManager.default.contentsOfDirectory(at: provisioningProfileDirectory, includingPropertiesForKeys: nil)
                    
                    // List all files in the directory
                    for file in directoryContents {
                        print("Found file: \(file.lastPathComponent)")
                    }
                } catch {
                    print("Error while listing files: \(error)")
                    DispatchQueue.main.async {
                        banner.dismiss()
                        banner = FloatingNotificationBanner(title: "Sideloading Failed", subtitle: "Could not load directory contents.", style: .danger)
                        banner.show()
                    }
                }
                
                // Example of checking file existence and proceeding
                if FileManager.default.fileExists(atPath: provisioningProfilePath) {
                 print("Provisioning profile exists at path: \(provisioningProfilePath)")
                 // Proceed with further processing like zsign...
                } else {
                    print("Provisioning profile does not exist at the expected path.")
                    DispatchQueue.main.async {
                        banner.dismiss()
                        banner = FloatingNotificationBanner(title: "Sideloading Failed", subtitle: "Provisioning profile does not exist at the expected path or there was an unexpected error with your IPA file while extracting.", style: .danger)
                        banner.show()
                    }
                    currentSignedTweaks = 0
                    totalTweaks = 0
                    globalSideloadingPercentage = 0
                    globalSideloadingStatus?.sideloadingPercentage = 0
                    progress = 0
                    
                    //DispatchQueue.main.async {
                    currentSignedTweaks = 0
                    totalTweaks = 0
                    globalSideloadingPercentage = 0
                    globalSideloadingStatus?.sideloadingPercentage = 0
                    progress = 0
                    return false
                 }
                
                // Here, you can continue with the rest of your operations
                // For example, handling the signing process:
                
                let tweakPath = selectedTweakPath == ipaFilePath ? "" : selectedTweakPath.path
                if (tweakPath != "") {
                    FixSubstrate(tweakPath)
                }
                let code = zsign(appFolderURL.path, p12KeyPath, provisioningProfilePath, "Hydrogen", bundleidInput, appNameInput, appVersionInput, tweakPath)
                if code == 0 {
                    print("Signing successful")
                    let signedIPAPath = documentsDirectory.appendingPathComponent("debugger.ipa")
                    
                    // Define the path of the Payload directory
                    let payloadPath = destinationPath.appendingPathComponent("Payload")
                    
                    // Check if the Payload directory exists
                    if !fileManager.fileExists(atPath: payloadPath.path) {
                        print("Payload directory not found.")
                        return false
                    }
                    
                    // Zip the Payload folder into the new IPA file
                    do {
                        try fileManager.zipItem(at: payloadPath, to: signedIPAPath)
                        print("Zipping Payload folder successful. Signed IPA path: \(signedIPAPath.path)")
                    } catch {
                        print("Failed to zip the Payload folder: \(error)")
                        return false
                    }
                    
                    //DispatchQueue.main.async {
                    //globalSideloadingStatus?.sideloadingPercentage = 85
                    //}
                    
                    globalSideloadingPercentage = 85
                    
                    do {
                        try server.start(8080)
                        print("HTTP server started")
                    } catch {
                        print("Failed to start server.")
                        return false
                    }
                    
                    print("/" + signedIPAPath.lastPathComponent)
                    server["/" + signedIPAPath.lastPathComponent] = shareFile(signedIPAPath.path)
                    
                    server["/" + "appIcon.png"] = shareFile(extractAppIcon(fromPayloadFolder: payloadPath.path) ?? "https://raw.githubusercontent.com/loyahdev/Hydrogen-Sign/main/hydrogen-bot-logo.png?token=GHSAT0AAAAAACJBE3G6PUWHVW3JNM6XEBTGZLKZJZA")
                    
                    let bundleId = extractBundleId(fromPayloadFolder: payloadPath.path)
                    print("bundleid: " + bundleId)
                    
                    let bundleVersion = extractBundleVersion(fromPayloadFolder: payloadPath.path)
                    print("bundleversion: " + bundleVersion)
                    
                    // Example usage
                    let plistContent = """
                <?xml version="1.0" encoding="UTF-8"?>
                    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
                    "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
                    <plist version="1.0">
                        <dict>
                            <key>items</key>
                            <array>
                                <dict>
                                    <key>assets</key>
                                    <array>
                                        <dict>
                                            <key>kind</key>
                                            <string>software-package</string>
                                            <key>url</key>
                                            <string>http://localhost:8080/\(signedIPAPath.lastPathComponent)</string>
                                        </dict>
                                        <dict>
                                            <key>kind</key>
                                            <string>display-image</string>
                                            <key>needs-shine</key>
                                            <false/>
                                            <key>url</key>
                                            <string>http://localhost:8080/appIcon.png</string>
                                        </dict>
                                        <dict>
                                            <key>kind</key>
                                            <string>full-size-image</string>
                                            <key>needs-shine</key>
                                            <false/>
                                            <key>url</key>
                                            <string>http://localhost:8080/appIcon.png</string>
                                        </dict>
                                    </array>
                                    <key>metadata</key>
                                    <dict>
                                        <key>bundle-identifier</key>
                                        <string>\(String(describing: bundleId))</string>
                                        <key>bundle-version</key>
                                        <string>\(String(describing: bundleVersion))</string>
                                        <key>kind</key>
                                        <string>software</string>
                                        <key>title</key>
                                        <string>Signed using, Thirdstore</string>
                                    </dict>
                                </dict>
                            </array>
                        </dict>
                    </plist>
                """
                    if let plistPath = createPlistFile(fromContent: plistContent) {
                        print("Plist file created at path: \(plistPath)")
                        /*DispatchQueue.main.async {
                         globalSideloadingStatus?.sideloadingPercentage = 100
                         globalSideloadingPercentage = 100
                         }*/
                        
                        //globalSideloadingStatus?.sideloadingPercentage = 100
                        globalSideloadingPercentage = 100
                        
                        stopTimer()
                        
                        // Convert plistPath to URL to extract the last path component
                        if URL(string: plistPath) != nil {
                            //let lastPathComponent = plistURL.lastPathComponent
                            server["/install.plist"] = shareFile(plistPath)
                            
                            if let url = URL(string: "itms-services://?action=download-manifest&url=https://loyah.dev/install") {
                                DispatchQueue.main.async {
                                    UIApplication.shared.open(url)
                                }
                            }
                        } else {
                            print("Invalid plist path")
                        }
                        //presentingPopupTitle = "Processing Sideload..."
                        //sharedData.SideloadingErrorMessage = "Processing Sideload..."
                        //DispatchQueue.main.asyncAfter(deadline: .now() + popupDelay) {
                        //isPresentingPopup = true
                        DispatchQueue.main.async {
                            banner.dismiss()
                            banner = FloatingNotificationBanner(title: "Sideloading Complete", subtitle: "Your app should install shortly.", style: .success)
                            banner.show()
                        }
                        return true
                        //}
                    }
                } else if (code == -1) {
                    //presentingPopupTitle = "There was an error when signing, your P12 file password may be incorrect..."
                    //sharedData.SideloadingErrorMessage = "Incorrect P12 file password..."
                    //DispatchQueue.main.asyncAfter(deadline: .now() + popupDelay) {
                    //isPresentingPopup = true
                    DispatchQueue.main.async {
                        banner.dismiss()
                        banner = FloatingNotificationBanner(title: "Sideloading Failed", subtitle: "There was an error when signing, this may be an issue on our end.", style: .danger)
                        banner.show()
                    }
                    currentSignedTweaks = 0
                    totalTweaks = 0
                    globalSideloadingPercentage = 0
                    globalSideloadingStatus?.sideloadingPercentage = 0
                    progress = 0
                    
                    DispatchQueue.main.async {
                        currentSignedTweaks = 0
                        totalTweaks = 0
                        globalSideloadingPercentage = 0
                        globalSideloadingStatus?.sideloadingPercentage = 0
                        progress = 0
                    }
                    return false
                    //}
                } else {
                    print("Signing failed with code \(code)")
                    presentingPopupTitle = "Signing failed with code \(code)"
                    //sharedData.SideloadingErrorMessage = "Signing failed with code \(code)"
                    //DispatchQueue.main.asyncAfter(deadline: .now() + popupDelay) {
                    isPresentingPopup = true
                    //}
                }
                //}
            } else {
                //try? await Task.sleep(nanoseconds: 2_000_000_000)
                print("Selected tweak:")
                print(selectedTweakPath)
                let tweakPath = selectedTweakPath == ipaFilePath ? "" : selectedTweakPath.path
                if (tweakPath != "") {
                    FixSubstrate(tweakPath)
                }
                let p12Password = "1"
                let displayName = "App"
                print("custom p12 file name is")
                print(selectedP12URL?.lastPathComponent)
                Task {
                    let code = zsign(appFolderURL.path, selectedP12URL?.path, selectedMobileProvisionURL?.path, p12PasswordInput, bundleidInput, appNameInput, appVersionInput, tweakPath)
                    //let code = zsign(folderToSign, selectedP12URL?.path, selectedP12URL?.path, selectedMobileProvisionURL?.path, p12PasswordInput)
                    if code == 0 {
                        print("Signing successful")
                        stopTimer()
                        let signedIPAPath = documentsDirectory.appendingPathComponent("debugger.ipa")
                        
                        // Define the path of the Payload directory
                        let payloadPath = destinationPath.appendingPathComponent("Payload")
                        
                        // Check if the Payload directory exists
                        if !fileManager.fileExists(atPath: payloadPath.path) {
                            print("Payload directory not found.")
                            return false
                        }
                        
                        // Zip the Payload folder into the new IPA file
                        do {
                            try fileManager.zipItem(at: payloadPath, to: signedIPAPath)
                            print("Zipping Payload folder successful. Signed IPA path: \(signedIPAPath.path)")
                        } catch {
                            print("Failed to zip the Payload folder: \(error)")
                            return false
                        }
                        
                        //DispatchQueue.main.async {
                        //Task {
                        /*DispatchQueue.main.async {
                         globalSideloadingStatus?.sideloadingPercentage = 85
                         }*/
                        //}
                        //}
                        
                        globalSideloadingPercentage = 85
                        
                        do {
                            try server.start(8080)
                            print("HTTP server started")
                        } catch {
                            print("Failed to start server.")
                            return false
                        }
                        
                        print("/" + signedIPAPath.lastPathComponent)
                        server["/" + signedIPAPath.lastPathComponent] = shareFile(signedIPAPath.path)
                        
                        server["/" + "appIcon.png"] = shareFile(extractAppIcon(fromPayloadFolder: payloadPath.path) ?? "https://raw.githubusercontent.com/loyahdev/Hydrogen-Sign/main/hydrogen-bot-logo.png?token=GHSAT0AAAAAACJBE3G6PUWHVW3JNM6XEBTGZLKZJZA")
                        
                        let bundleId = extractBundleId(fromPayloadFolder: payloadPath.path)
                        print("bundleid: " + bundleId)
                        
                        let bundleVersion = extractBundleVersion(fromPayloadFolder: payloadPath.path)
                        print("bundleversion: " + bundleVersion)
                        
                        // Example usage
                        let plistContent = """
            <?xml version="1.0" encoding="UTF-8"?>
                <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
                "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
                <plist version="1.0">
                    <dict>
                        <key>items</key>
                        <array>
                            <dict>
                                <key>assets</key>
                                <array>
                                    <dict>
                                        <key>kind</key>
                                        <string>software-package</string>
                                        <key>url</key>
                                        <string>http://localhost:8080/\(signedIPAPath.lastPathComponent)</string>
                                    </dict>
                                    <dict>
                                        <key>kind</key>
                                        <string>display-image</string>
                                        <key>needs-shine</key>
                                        <false/>
                                        <key>url</key>
                                        <string>http://localhost:8080/appIcon.png</string>
                                    </dict>
                                    <dict>
                                        <key>kind</key>
                                        <string>full-size-image</string>
                                        <key>needs-shine</key>
                                        <false/>
                                        <key>url</key>
                                        <string>http://localhost:8080/appIcon.png</string>
                                    </dict>
                                </array>
                                <key>metadata</key>
                                <dict>
                                    <key>bundle-identifier</key>
                                    <string>\(String(describing: bundleId))</string>
                                    <key>bundle-version</key>
                                    <string>\(String(describing: bundleVersion))</string>
                                    <key>kind</key>
                                    <string>software</string>
                                    <key>title</key>
                                    <string>Signed using, Thirdstore</string>
                                </dict>
                            </dict>
                        </array>
                    </dict>
                </plist>
            """
                        if let plistPath = createPlistFile(fromContent: plistContent) {
                            print("Plist file created at path: \(plistPath)")
                            //DispatchQueue.global(qos: .default).async {
                            /*DispatchQueue.main.async {
                             globalSideloadingStatus?.sideloadingPercentage = 100
                             globalSideloadingPercentage = 100
                             }*/
                            //}
                            
                            globalSideloadingPercentage = 100
                            // Convert plistPath to URL to extract the last path component
                            // Call stopTimer without passing a closure.
                            stopTimer()
                            
                            // Code to execute after stopTimer completes
                            if let plistURL = URL(string: plistPath) {//, UIApplication.shared.canOpenURL(plistURL) {
                                // Your existing logic here
                                server["/install.plist"] = shareFile(plistPath)
                                if let url = URL(string: "itms-services://?action=download-manifest&url=https://loyah.dev/install") {
                                    //DispatchQueue.main.async {
                                    UIApplication.shared.open(url)
                                    //}
                                }
                            } else {
                                print("Invalid plist path")
                            }
                            //presentingPopupTitle = "Processing Sideload..."
                            //DispatchQueue.main.asyncAfter(deadline: .now() + popupDelay) {
                            DispatchQueue.main.async {
                                banner.dismiss()
                                banner = FloatingNotificationBanner(title: "Sideloading Complete", subtitle: "Your app should install shortly.", style: .success)
                                banner.show()
                            }
                            //isPresentingFinished = true
                            LogToConsole(message: "Sideloading complete showing alert")
                            //isPresentingPopup = true
                            
                            return true
                            //}
                        }
                    } else if (code == -1) {
                        //presentingPopupTitle = "There was an error when signing, your P12 file password may be incorrect..."
                        //sharedData.SideloadingErrorMessage = "Incorrect P12 file password..."
                        //DispatchQueue.main.asyncAfter(deadline: .now() + popupDelay) {
                        DispatchQueue.main.async {
                            banner.dismiss()
                            banner = FloatingNotificationBanner(title: "Sideloading Failed", subtitle: "There was an error when signing, this may be an issue on our end.", style: .danger)
                            banner.show()
                        }
                        currentSignedTweaks = 0
                        totalTweaks = 0
                        globalSideloadingPercentage = 0
                        globalSideloadingStatus?.sideloadingPercentage = 0
                        progress = 0
                        
                        DispatchQueue.main.async {
                            currentSignedTweaks = 0
                            totalTweaks = 0
                            globalSideloadingPercentage = 0
                            globalSideloadingStatus?.sideloadingPercentage = 0
                            progress = 0
                        }
                        //isPresentingPopup = true
                        return false
                        //}
                    } else {
                        print("Signing failed with code \(code)")
                        presentingPopupTitle = "Signing failed with code \(code)"
                        //sharedData.SideloadingErrorMessage = "Signing failed with code \(code)"
                        //DispatchQueue.main.asyncAfter(deadline: .now() + popupDelay) {
                        isPresentingPopup = true
                        return false
                        //}
                    }
                    return true
                }
            }
            return false
        } catch {
            print("Extraction failed: \(error)")
            DispatchQueue.main.async {
                banner.dismiss()
                banner = FloatingNotificationBanner(title: "Sideloading Failed", subtitle: "IPA extraction failed: \(error).", style: .danger)
                banner.show()
            }
            return false
        }
    }
    
    func startTimer(fileURL: URL) {
        startTime = Date() // Capture the start time when the timer starts0
        
        // Attempt to calculate the file size and signing =time immediately
        if let fileSize = try? fileSizeForURL(fileURL) {
            fileSizeMB = fileSize
            signingTime = calculateSigningTime(fileSize: fileSize) + 0.5 // just for general estimation
            print("Starting timer. File URL: \(fileURL), initial file size: \(fileSizeMB)MB, estimated signing time: \(signingTime) seconds.")
        }
        
        // Setup the timer after calculating initial signing time
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.fileSizeMB = (try? self.fileSizeForURL(fileURL)) ?? 0
        }
    }
    
    func stopTimer() {
        if let startTime = startTime {
            let duration = Date().timeIntervalSince(startTime)
            print("Timer stopped. Duration: \(duration) seconds.")
            finalSigningTime = Float(duration)
        }
        timer?.invalidate()
        timer = nil
        startTime = nil // Reset the start time
    }
    
    func fileSizeForURL(_ url: URL) throws -> Float {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        if let fileSize = attributes[.size] as? NSNumber {
            return fileSize.floatValue / 1_000_000.0 // Convert bytes to megabytes
        } else {
            throw NSError(domain: "FileSizeError", code: 0, userInfo: nil)
        }
    }
    
    func calculateSigningTime(fileSize: Float) -> Float {
        let averageTime = Float(0.0126) //Float(0.0390) //Float(0.06349095966620306)
        return averageTime * fileSize
    }
    
    func countDylibsAndFrameworks(inPayloadFolderPath path: String) {
        let fileManager = FileManager.default
        // Assume the script is being run from the root directory of the Xcode project
        let projectRootURL = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        let appFolderPath = URL(fileURLWithPath: path).appendingPathComponent("Payload")
        
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: appFolderPath.path)
            guard let appPath = contents.first(where: { $0.hasSuffix(".app") }) else {
                print("No .app folder found in the Payload folder")
                return
            }
            let fullAppPath = appFolderPath.appendingPathComponent(appPath)
            if (tweakImported == true) {
                let frameworksFolderPath = fullAppPath.appendingPathComponent("Frameworks")
                
                // Create the Frameworks directory if it does not exist
                if !fileManager.fileExists(atPath: frameworksFolderPath.path) {
                    try fileManager.createDirectory(at: frameworksFolderPath, withIntermediateDirectories: true)
                    print("Frameworks directory created at: \(frameworksFolderPath.path)")
                }
                
                // Define the source URL for the framework, assuming it's located in the project directory
                if let fileURL = Bundle.main.url(forResource: "CydiaSubstrate", withExtension: "framework") {
                    let destinationFrameworkURL = frameworksFolderPath.appendingPathComponent("CydiaSubstrate.framework")
                    
                    // Copy the framework if it doesn't already exist at the destination
                    if !fileManager.fileExists(atPath: destinationFrameworkURL.path) {
                        try fileManager.copyItem(at: fileURL, to: destinationFrameworkURL)
                        print("Cydia Substrate copied to the destination at: \(destinationFrameworkURL.path)")
                    } else {
                        print("CydiaSubstrate.framework already exists in the destination at: \(destinationFrameworkURL.path)")
                    }
                }
                
                // Define the source URL for the framework, assuming it's located in the project directory
                if let fileURL = Bundle.main.url(forResource: "libsubstrate", withExtension: "dylib") {
                    let destinationFrameworkURL = frameworksFolderPath.appendingPathComponent("libsubstrate.dylib")
                    
                    // Copy the framework if it doesn't already exist at the destination
                    if !fileManager.fileExists(atPath: destinationFrameworkURL.path) {
                        try fileManager.copyItem(at: fileURL, to: destinationFrameworkURL)
                        print("lib Substrate copied to the destination at: \(destinationFrameworkURL.path)")
                    } else {
                        print("libsubstrate.dylib already exists in the destination at: \(destinationFrameworkURL.path)")
                    }
                }
            }
            
            /*// Enumerate and print all files in the Frameworks directory
            let frameworkContents = try fileManager.contentsOfDirectory(atPath: frameworksFolderPath.path)
            print("Contents of Frameworks directory:")
            for fileName in frameworkContents {
                print(fileName)
            }*/
            
            var dylibCount = 0
            var frameworkCount = 0
            
            // Enumerate the contents of the app folder to count .dylib and .framework files
            let enumerator = fileManager.enumerator(at: fullAppPath, includingPropertiesForKeys: nil)
            while let element = enumerator?.nextObject() as? URL {
                if element.pathExtension == "dylib" {
                    dylibCount += 1
                } else if element.pathExtension == "framework" {
                    frameworkCount += 1
                }
            }
            
            print("Total .dylib files: \(dylibCount)")
            print("Total .framework folders: \(frameworkCount)")
            print("Total Items being Signed: \(dylibCount + frameworkCount + 1)")
            globalSideloadingStatus?.totalTweaks = (dylibCount + frameworkCount + 1)
        } catch {
            print("Error while copying the framework or counting files: \(error)")
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
