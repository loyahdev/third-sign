//
//  DocumentPicker.swift
//  Custom File Explorer
//
//  Created by Jaxon Hensch on 2024-04-22.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct IPAFileDocumentPicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    @Binding var fileImported: Bool
    @Binding var selectedFileURL: URL?
    @Binding var customApp: Bool

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let zipUTI = UTType(filenameExtension: "zip") ?? .archive
        let ipaUTI = UTType(filenameExtension: "ipa") ?? .archive

        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [zipUTI, ipaUTI], asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: IPAFileDocumentPicker

        init(_ parent: IPAFileDocumentPicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first, url.pathExtension.lowercased() == "ipa" else {
                print("Unsupported file extension. Please select a .ipa file.")
                return
            }
            
            /*let fileManager = FileManager.default
                let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
                let destinationURL = documentDirectory.appendingPathComponent("importedIPA.ipa")

                do {
                    // If the file already exists at the destination, remove it first.
                    if fileManager.fileExists(atPath: destinationURL.path) {
                        try fileManager.removeItem(at: destinationURL)
                    }
                    
                    // Copy the file to the destination URL.
                    try fileManager.copyItem(at: url, to: destinationURL)
                    
                    // Update the parent's state to reflect the successful import.
                    print(destinationURL.path)
                    self.parent.selectedFileURL = destinationURL
                    self.parent.fileImported = true
                    
                } catch {
                    print("Could not copy file to destination: \(error)")
                    self.parent.fileImported = false
                }*/
            
            self.parent.selectedFileURL = url
            self.parent.fileImported = true
            self.parent.isPresented = false
            self.parent.customApp = false
            
            print(self.parent.fileImported)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.isPresented = false
        }
    }
}

struct P12FileDocumentPicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    @Binding var fileImported: Bool
    @Binding var selectedFileURL: URL?

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let p12UTI = UTType(filenameExtension: "p12") ?? .x509Certificate

        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [p12UTI], asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: P12FileDocumentPicker

        init(_ parent: P12FileDocumentPicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first, url.pathExtension.lowercased() == "p12" else {
                print("Unsupported file extension. Please select a .p12 file.")
                return
            }
            
            /*let fileManager = FileManager.default
                let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
                let destinationURL = documentDirectory.appendingPathComponent("importedIPA.ipa")

                do {
                    // If the file already exists at the destination, remove it first.
                    if fileManager.fileExists(atPath: destinationURL.path) {
                        try fileManager.removeItem(at: destinationURL)
                    }
                    
                    // Copy the file to the destination URL.
                    try fileManager.copyItem(at: url, to: destinationURL)
                    
                    // Update the parent's state to reflect the successful import.
                    print(destinationURL.path)
                    self.parent.selectedFileURL = destinationURL
                    self.parent.fileImported = true
                    
                } catch {
                    print("Could not copy file to destination: \(error)")
                    self.parent.fileImported = false
                }*/
            
            self.parent.selectedFileURL = url
            self.parent.fileImported = true
            self.parent.isPresented = false
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.isPresented = false
        }
    }
}

struct MPFileDocumentPicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    @Binding var fileImported: Bool
    @Binding var selectedFileURL: URL?

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let MPUTI = UTType(filenameExtension: "mobileprovision") ?? .aiff

        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [MPUTI], asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: MPFileDocumentPicker

        init(_ parent: MPFileDocumentPicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first, url.pathExtension.lowercased() == "mobileprovision" else {
                print("Unsupported file extension. Please select a .mobileprovision file.")
                return
            }
            
            /*let fileManager = FileManager.default
                let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
                let destinationURL = documentDirectory.appendingPathComponent("importedIPA.ipa")

                do {
                    // If the file already exists at the destination, remove it first.
                    if fileManager.fileExists(atPath: destinationURL.path) {
                        try fileManager.removeItem(at: destinationURL)
                    }
                    
                    // Copy the file to the destination URL.
                    try fileManager.copyItem(at: url, to: destinationURL)
                    
                    // Update the parent's state to reflect the successful import.
                    print(destinationURL.path)
                    self.parent.selectedFileURL = destinationURL
                    self.parent.fileImported = true
                    
                } catch {
                    print("Could not copy file to destination: \(error)")
                    self.parent.fileImported = false
                }*/
            
            self.parent.selectedFileURL = url
            self.parent.fileImported = true
            self.parent.isPresented = false
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.isPresented = false
        }
    }
}

struct TweakFileDocumentPicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    @Binding var fileImported: Bool
    @Binding var selectedFileURL: URL?

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let DylibUTI = UTType(filenameExtension: "dylib") ?? .aiff
        let DebUTI = UTType(filenameExtension: "deb") ?? .aiff

        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [DylibUTI, DebUTI], asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: TweakFileDocumentPicker

        init(_ parent: TweakFileDocumentPicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first, (url.pathExtension.lowercased() == "dylib" || url.pathExtension.lowercased() == "deb") else {
                print("Unsupported file extension. Please select a .dylib or .deb file.")
                return
            }
            
            /*let fileManager = FileManager.default
                let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
                let destinationURL = documentDirectory.appendingPathComponent("importedIPA.ipa")

                do {
                    // If the file already exists at the destination, remove it first.
                    if fileManager.fileExists(atPath: destinationURL.path) {
                        try fileManager.removeItem(at: destinationURL)
                    }
                    
                    // Copy the file to the destination URL.
                    try fileManager.copyItem(at: url, to: destinationURL)
                    
                    // Update the parent's state to reflect the successful import.
                    print(destinationURL.path)
                    self.parent.selectedFileURL = destinationURL
                    self.parent.fileImported = true
                    
                } catch {
                    print("Could not copy file to destination: \(error)")
                    self.parent.fileImported = false
                }*/
            
            self.parent.selectedFileURL = url
            self.parent.fileImported = true
            self.parent.isPresented = false
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.isPresented = false
        }
    }
}
