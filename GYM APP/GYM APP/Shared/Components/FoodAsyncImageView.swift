//
//  FoodAsyncImageView.swift
//  GYM APP
//

import SwiftUI
import OSLog

/// Async disk image loader for food photographs.
/// Mirrors AsyncDiskImageView but uses FoodImageStorageService.
/// Shares PhotoImageCache.shared — no duplicate cache.
///
/// `imageID` is used as part of the task identity so that when a Food's image is
/// replaced (same path, new FoodImage UUID), the view reloads without relying on the
/// path changing. Pass `food.image?.id` at the call site for correct reactivity.
struct FoodAsyncImageView: View {
    let relativePath: String?
    var imageID: UUID? = nil
    var contentMode: ContentMode = .fill

    @State private var image: PlatformImage?
    @State private var isLoading = false

    private let storage = FoodImageStorageService()

    /// Combined task identity: path + imageID so replacement triggers a reload.
    private var taskID: String { "\(relativePath ?? "")_\(imageID?.uuidString ?? "")" }

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
        .task(id: taskID) {
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
