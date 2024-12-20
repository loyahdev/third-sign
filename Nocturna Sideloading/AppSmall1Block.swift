// 2024.04.28 | AppStoreReplica - AppSmall2Block.swift |
import SwiftUI
import UIKit
import Foundation
import Combine

class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading = false // Add this line
    private var cancellables = Set<AnyCancellable>()

    func load(fromURLString urlString: String) {
        guard let url = URL(string: urlString) else {
            // Consider setting isLoading to false here if you want to indicate loading has failed
            return
        }

        isLoading = true // Indicate loading has started
        URLSession.shared.dataTaskPublisher(for: url)
            .map { UIImage(data: $0.data) }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false // Indicate loading has finished regardless of the outcome
                if case .failure = completion {
                    // Here you could set the image to a default one in case of failure
                    // self?.image = UIImage(named: "default-image192")
                }
            }, receiveValue: { [weak self] loadedImage in
                self?.image = loadedImage
            })
            .store(in: &cancellables)
    }
}

struct AsyncImageView: View {
    @StateObject private var loader = ImageLoader()
    var urlString: String
    
    var body: some View {
        Group {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
            } else if loader.isLoading {
                // Display a loading indicator while the image is loading
                ProgressView()
            } else {
                
            }
        }
        .onAppear {
            loader.load(fromURLString: urlString)
        }
        .onChange(of: urlString) { newURLString in
            loader.load(fromURLString: newURLString)
        }
    }
}

struct AppSmall1Block: View {
    var imageName: String
    var title: String
    var subtitle: String
    var developer: String
    var description: String
    var screenshotURLs: [String]
    var downloadURL: String
    var minus50padding: Bool

    var body: some View {
        HStack {
            AsyncImageView(urlString: imageName) // Assuming this is a custom view for async image loading
                .frame(width: 50, height: 50)
                .cornerRadius(12)
            
            VStack(alignment: .leading) {
                Text(title)
                    .bold()
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(/*@START_MENU_TOKEN@*/.tail/*@END_MENU_TOKEN@*/)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(/*@START_MENU_TOKEN@*/.tail/*@END_MENU_TOKEN@*/)
            }
            
            Spacer()
            Button(action:  {
                
            }) {
                Text("Get")
                    .font(Font.system(.caption).bold())
                    .padding(.horizontal, 24)
                    .padding(.vertical, 6)
                    .background(Color(UIColor.systemGray5))
                    .clipShape(Capsule())
            }
        }
    }
}
