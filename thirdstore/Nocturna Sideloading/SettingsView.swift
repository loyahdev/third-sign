//
//  SettingsView.swift
//  Nocturna Sideloading
//
//  Created by Jaxon Hensch on 2024-03-05.
//

import Foundation
import SwiftUI
import UIKit

struct SettingsView: View {
    // Define state variables for the toggles
    @State private var showSigningSpeeds: Bool = UserDefaults.standard.bool(forKey: "showSigningSpeeds")
    @State private var showZSignLogs: Bool = UserDefaults.standard.bool(forKey: "showZSignLogs")

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Debug"), footer: Text("These debugs will all be shown after signing before installing the app.")) {
                    Toggle(isOn: $showSigningSpeeds,
                           label: {
                        Text("Show Signing Speeds")
                    })
                    .onChange(of: showSigningSpeeds) { newValue in
                        // Save the toggle state to UserDefaults
                        UserDefaults.standard.set(newValue, forKey: "showSigningSpeeds")
                    }
                    
                    Toggle(isOn: $showZSignLogs,
                           label: {
                        Text("Show ZSign Logs")
                    })
                    .onChange(of: showZSignLogs) { newValue in
                        // Save the toggle state to UserDefaults
                        UserDefaults.standard.set(newValue, forKey: "showZSignLogs")
                    }
                }
                
                Section(header: Text("Tools"), footer: Text("These are all incomplete and cannot be changed.")) {
                    
                    Toggle(isOn: .constant(false),
                           label: {
                        Text("Save Certificate Settings")
                    })
                    .disabled(true)
                }
                
                Section(header: Text("Credits")) {
                    Label {
                        Text("loyahdev")
                    } icon: {
                        Image("loyahdev")
                            .resizable() // Make the image resizable.
                        //.scaledToFit() // Scale the image to fit while maintaining its aspect ratio.
                            .frame(width: 36, height: 36) // Specify the desired frame size for the icon.
                    }
                }
            }
            .navigationBarTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
