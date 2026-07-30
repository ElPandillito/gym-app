//
//  AsyncDiskImageView.swift
//  GYM APP
//

import SwiftUI
import OSLog

struct AsyncDiskImageView: View {
    let relativePath: String?
    let storage: PhotoStorageServiceProtocol
    var contentMode: ContentMode = .fill

    @State private var image: PlatformImage?
    @State private var isLoading = false

    var body: some View {
        Group {
            if let img = image {
                #if os(iOS)
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                #elseif os(macOS)
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                #endif
            } else if isLoading {
                Rectangle()
                    .fill(Color.secondary.opacity(0.15))
                    .overlay {
                        ProgressView()
                            .tint(.secondary)
                    }
            } else {
                Rectangle()
                    .fill(Color.secondary.opacity(0.10))
                    .overlay {
                        Image(systemName: "photo")
                            .font(.title2)
                            .foregroundStyle(.tertiary)
                    }
            }
        }
        .task(id: relativePath) {
            await loadImage()
        }
    }

    private func loadImage() async {
        guard let path = relativePath else {
            image = nil
            return
        }

        if let cached = PhotoImageCache.shared.image(for: path) {
            image = cached
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let data = try storage.loadData(for: path)
            #if os(iOS)
            if let loaded = UIImage(data: data) {
                PhotoImageCache.shared.store(loaded, for: path)
                image = loaded
            }
            #elseif os(macOS)
            if let loaded = NSImage(data: data) {
                PhotoImageCache.shared.store(loaded, for: path)
                image = loaded
            }
            #endif
        } catch {
            AppLogger.storage.error("AsyncDiskImageView load failed: \(error.localizedDescription)")
        }
    }
}
