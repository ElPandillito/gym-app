//
//  ProgressPhotoViewer.swift
//  GYM APP
//

import SwiftUI

struct ProgressPhotoViewer: View {
    let initialPhoto: ProgressPhoto
    let storage: PhotoStorageServiceProtocol
    let onDelete: (ProgressPhoto) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var currentPhotos: [ProgressPhoto]
    @State private var currentIndex: Int = 0
    @State private var showControls = true
    @State private var showDeleteConfirmation = false
    @State private var loadedImages: [UUID: PlatformImage] = [:]

    init(
        photos: [ProgressPhoto],
        initialPhoto: ProgressPhoto,
        storage: PhotoStorageServiceProtocol,
        onDelete: @escaping (ProgressPhoto) -> Void
    ) {
        self.initialPhoto = initialPhoto
        self.storage      = storage
        self.onDelete     = onDelete
        self._currentPhotos = State(initialValue: photos)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            #if os(iOS)
            TabView(selection: $currentIndex) {
                ForEach(Array(currentPhotos.enumerated()), id: \.element.id) { index, photo in
                    photoPage(for: photo)
                        .tag(index)
                        .onAppear { preloadAdjacent(to: index) }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
            #else
            if !currentPhotos.isEmpty {
                photoPage(for: currentPhotos[currentIndex])
                    .onAppear { preloadAdjacent(to: currentIndex) }
                    .onChange(of: currentIndex) { _, newIndex in
                        preloadAdjacent(to: newIndex)
                    }
            }
            #endif

            if showControls {
                controlsOverlay
                    .transition(.opacity)
            }
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                showControls.toggle()
            }
        }
        .onAppear {
            currentIndex = currentPhotos.firstIndex { $0.id == initialPhoto.id } ?? 0
            preloadAdjacent(to: currentIndex)
        }
        .preferredColorScheme(.dark)
        .confirmationDialog(
            "¿Eliminar esta foto?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Eliminar", role: .destructive) { deleteCurrentPhoto() }
            Button("Cancelar", role: .cancel) {}
        }
    }

    // MARK: - Photo page

    private func photoPage(for photo: ProgressPhoto) -> some View {
        GeometryReader { geo in
            Group {
                if let img = loadedImages[photo.id] {
                    ZoomableImageView(image: img)
                } else {
                    AsyncDiskImageView(
                        relativePath: photo.originalPath,
                        storage: storage,
                        contentMode: .fit
                    )
                    .onAppear { loadImage(for: photo) }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    // MARK: - Controls overlay

    private var controlsOverlay: some View {
        VStack {
            topBar
            Spacer()
            if !currentPhotos.isEmpty {
                bottomInfo
            }
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial, in: Circle())
            }

            Spacer()

            #if os(macOS)
            if currentPhotos.count > 1 {
                HStack(spacing: AppSpacing.sm) {
                    Button {
                        currentIndex = max(0, currentIndex - 1)
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .disabled(currentIndex == 0)

                    Button {
                        currentIndex = min(currentPhotos.count - 1, currentIndex + 1)
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .disabled(currentIndex == currentPhotos.count - 1)
                }
                Spacer()
            }
            #endif

            Button {
                showDeleteConfirmation = true
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial, in: Circle())
            }
        }
        .padding(.horizontal, AppSpacing.base)
        .padding(.top, AppSpacing.base)
    }

    private var bottomInfo: some View {
        let photo = currentPhotos[min(currentIndex, currentPhotos.count - 1)]
        return VStack(spacing: AppSpacing.xs) {
            Label(photo.poseType.displayName, systemImage: photo.poseType.sfSymbol)
                .font(AppTypography.headline)
                .foregroundStyle(.white)

            Text(photo.capturedAt.formatted(.dateTime.day().month(.wide).year()))
                .font(AppTypography.subheadline)
                .foregroundStyle(.white.opacity(0.75))

            if let notes = photo.notes, !notes.isEmpty {
                Text(notes)
                    .font(AppTypography.footnote)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xl)
            }

            if currentPhotos.count > 1 {
                HStack(spacing: AppSpacing.xs) {
                    ForEach(0..<currentPhotos.count, id: \.self) { i in
                        Circle()
                            .fill(i == currentIndex ? Color.white : Color.white.opacity(0.35))
                            .frame(width: 6, height: 6)
                            .animation(.easeInOut, value: currentIndex)
                    }
                }
                .padding(.top, AppSpacing.xxs)
            }
        }
        .padding(.horizontal, AppSpacing.base)
        .padding(.bottom, AppSpacing.xxxl)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [.clear, .black.opacity(0.72)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // MARK: - Deletion

    private func deleteCurrentPhoto() {
        guard !currentPhotos.isEmpty else { return }
        let photo = currentPhotos[currentIndex]
        onDelete(photo)
        currentPhotos.remove(at: currentIndex)
        loadedImages.removeValue(forKey: photo.id)
        if currentPhotos.isEmpty {
            dismiss()
        } else {
            currentIndex = min(currentIndex, currentPhotos.count - 1)
        }
    }

    // MARK: - Image loading

    private func loadImage(for photo: ProgressPhoto) {
        guard loadedImages[photo.id] == nil else { return }
        Task { @MainActor in
            if let cached = PhotoImageCache.shared.image(for: photo.originalPath) {
                loadedImages[photo.id] = cached
                return
            }
            guard let data = try? storage.loadData(for: photo.originalPath) else { return }
            #if os(iOS)
            if let img = UIImage(data: data) {
                PhotoImageCache.shared.store(img, for: photo.originalPath)
                loadedImages[photo.id] = img
            }
            #elseif os(macOS)
            if let img = NSImage(data: data) {
                PhotoImageCache.shared.store(img, for: photo.originalPath)
                loadedImages[photo.id] = img
            }
            #endif
        }
    }

    private func preloadAdjacent(to index: Int) {
        let indices = [index - 1, index, index + 1].filter { $0 >= 0 && $0 < currentPhotos.count }
        for i in indices { loadImage(for: currentPhotos[i]) }
    }
}
