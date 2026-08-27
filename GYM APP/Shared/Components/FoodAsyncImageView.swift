//
//  FoodAsyncImageView.swift
//  GYM APP
//

import SwiftUI
import OSLog

/// Async disk image loader for food photographs.
/// Mirrors AsyncDiskImageView but uses FoodImageStorageService.
/// Shares PhotoImageCache.shared — no duplicate cache.
struct FoodAsyncImageView: View {
    let relativePath: String?
    var contentMode: ContentMode = .fill

    @State private var image: PlatformImage?
    @State private var isLoading = false

    private let storage = FoodImageStorageService()

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
                    .overlay { ProgressView().tint(.secondary) }
            } else {
                Rectangle()
                    .fill(Color.secondary.opacity(0.10))
                    .overlay {
                        Image(systemName: "fork.knife")
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
        guard let path = relativePath else { image = nil; return }

        if let cached = PhotoImageCache.shared.image(for: path) {
            image = cached
            return
        }

        // asset:// paths load from the Asset Catalog — no disk I/O needed.
        if path.hasPrefix("asset://") {
            let assetName = String(path.dropFirst("asset://".count))
            #if os(iOS)
            if let loaded = UIImage(named: assetName) {
                PhotoImageCache.shared.store(loaded, for: path)
                image = loaded
            }
            #elseif os(macOS)
            if let loaded = NSImage(named: assetName) {
                PhotoImageCache.shared.store(loaded, for: path)
                image = loaded
            }
            #endif
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
            AppLogger.storage.error("FoodAsyncImageView load failed: \(error.localizedDescription)")
        }
    }
}
