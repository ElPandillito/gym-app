//
//  ProgressPhotoGridView.swift
//  GYM APP
//

import SwiftUI
import SwiftData

struct ProgressPhotoGridView: View {
    let checkIn: CheckIn
    @Environment(\.modelContext) private var context
    @State private var viewModel = ProgressPhotoViewModel()

    private let storage: PhotoStorageServiceProtocol = PhotoStorageService()
    private let columns = [
        GridItem(.adaptive(minimum: 110, maximum: 160), spacing: AppSpacing.xs)
    ]

    var body: some View {
        Group {
            if viewModel.hasPhotos {
                scrollContent
            } else {
                EmptyStateView(
                    icon: "camera.fill",
                    title: "Sin fotografías",
                    message: "Agrega la primera foto de posing de este check-in.",
                    actionTitle: "Agregar foto",
                    action: { viewModel.isShowingAddForm = true }
                )
            }
        }
        .navigationTitle("Fotografías")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.isShowingAddForm = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $viewModel.isShowingAddForm) {
            ProgressPhotoForm(storage: storage) { data, pose, date, notes in
                viewModel.add(data: data, poseType: pose, capturedAt: date, notes: notes)
            }
        }
        .fullScreenCover(isPresented: $viewModel.isShowingViewer) {
            if let selected = viewModel.selectedPhoto {
                ProgressPhotoViewer(
                    photos: viewModel.allPhotos,
                    initialPhoto: selected,
                    storage: storage,
                    onDelete: { viewModel.delete($0) }
                )
            }
        }
        .alert("Error", isPresented: errorBinding) {
            Button("OK") { viewModel.loadState = .idle }
        } message: {
            if case .error(let msg) = viewModel.loadState { Text(msg) }
        }
        .onAppear {
            viewModel.configure(checkIn: checkIn, context: context)
        }
    }

    // MARK: - Helpers

    private var errorBinding: Binding<Bool> {
        Binding(
            get: {
                if case .error = viewModel.loadState { return true }
                return false
            },
            set: { if !$0 { viewModel.loadState = .idle } }
        )
    }

    // MARK: - Scroll content

    private var scrollContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppSpacing.xl) {
                ForEach(viewModel.photosByPose, id: \.pose) { group in
                    poseSection(pose: group.pose, photos: group.photos)
                }
            }
            .padding(AppSpacing.base)
        }
    }

    private func poseSection(pose: PoseType, photos: [ProgressPhoto]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Label(pose.displayName, systemImage: pose.sfSymbol)
                .font(AppTypography.sectionHeader)
                .foregroundStyle(.secondary)
                .padding(.leading, AppSpacing.xxs)

            LazyVGrid(columns: columns, spacing: AppSpacing.xs) {
                ForEach(photos) { photo in
                    PhotoThumbnailCell(photo: photo, storage: storage)
                        .aspectRatio(3/4, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                        .onTapGesture { viewModel.openViewer(for: photo) }
                        .contextMenu {
                            Button(role: .destructive) {
                                viewModel.delete(photo)
                            } label: {
                                Label("Eliminar foto", systemImage: "trash")
                            }
                        }
                }
            }
        }
    }
}

// MARK: - Thumbnail Cell

private struct PhotoThumbnailCell: View {
    let photo: ProgressPhoto
    let storage: PhotoStorageServiceProtocol

    var body: some View {
        AsyncDiskImageView(
            relativePath: photo.thumbnailPath ?? photo.originalPath,
            storage: storage,
            contentMode: .fill
        )
        .clipped()
        .overlay(alignment: .bottomTrailing) {
            if !photo.isProcessed {
                Image(systemName: "clock.badge")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .shadow(radius: 3)
                    .padding(AppSpacing.xs)
            }
        }
    }
}
