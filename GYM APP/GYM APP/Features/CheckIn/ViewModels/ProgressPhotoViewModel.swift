//
//  ProgressPhotoViewModel.swift
//  GYM APP
//

import SwiftUI
import SwiftData
import OSLog

@Observable
@MainActor
final class ProgressPhotoViewModel {

    // MARK: - State

    enum LoadState {
        case idle
        case loading
        case error(String)
    }

    var loadState: LoadState = .idle
    var isShowingAddForm  = false
    var isShowingViewer   = false
    var selectedPhoto: ProgressPhoto?

    // MARK: - Dependencies

    private var repository: ProgressPhotoRepository?
    private(set) var checkIn: CheckIn?

    // MARK: - Configuration

    func configure(checkIn: CheckIn, context: ModelContext) {
        self.checkIn    = checkIn
        self.repository = ProgressPhotoRepository.make(context: context)
    }

    // MARK: - Derived

    var photos: [ProgressPhoto] {
        (checkIn?.photos ?? []).sorted {
            if $0.poseType.rawValue != $1.poseType.rawValue {
                return $0.poseType.rawValue < $1.poseType.rawValue
            }
            return $0.sortOrder < $1.sortOrder
        }
    }

    var photosByPose: [(pose: PoseType, photos: [ProgressPhoto])] {
        let grouped = Dictionary(grouping: photos) { $0.poseType }
        return PoseType.allCases.compactMap { pose in
            guard let items = grouped[pose], !items.isEmpty else { return nil }
            return (pose, items.sorted { $0.sortOrder < $1.sortOrder })
        }
    }

    var allPhotos: [ProgressPhoto] {
        photosByPose.flatMap { $0.photos }
    }

    var hasPhotos: Bool { !photos.isEmpty }

    private var nextSortOrder: Int {
        ((checkIn?.photos ?? []).map { $0.sortOrder }.max() ?? -1) + 1
    }

    // MARK: - CRUD

    func add(data: Data, poseType: PoseType, capturedAt: Date, notes: String?) {
        guard let repo = repository, let checkIn = checkIn else { return }
        loadState = .loading
        do {
            let photo = try repo.add(
                data: data,
                poseType: poseType,
                sortOrder: nextSortOrder,
                capturedAt: capturedAt,
                notes: notes?.nilIfBlank,
                for: checkIn
            )
            loadState = .idle
            try? repo.generateThumbnailIfNeeded(for: photo)
        } catch {
            AppLogger.storage.error("ProgressPhotoViewModel.add: \(error.localizedDescription)")
            loadState = .error(error.localizedDescription)
        }
    }

    func update(_ photo: ProgressPhoto, data: Data?, poseType: PoseType, notes: String?) {
        guard let repo = repository else { return }
        PhotoImageCache.shared.remove(for: photo.originalPath)
        if let thumb = photo.thumbnailPath { PhotoImageCache.shared.remove(for: thumb) }
        do {
            try repo.update(photo, data: data, poseType: poseType, notes: notes?.nilIfBlank)
            if data != nil { try? repo.generateThumbnailIfNeeded(for: photo) }
        } catch {
            AppLogger.storage.error("ProgressPhotoViewModel.update: \(error.localizedDescription)")
            loadState = .error(error.localizedDescription)
        }
    }

    func delete(_ photo: ProgressPhoto) {
        guard let repo = repository, let checkIn = checkIn else { return }
        PhotoImageCache.shared.remove(for: photo.originalPath)
        if let thumb = photo.thumbnailPath { PhotoImageCache.shared.remove(for: thumb) }
        do {
            try repo.delete(photo, from: checkIn)
            if selectedPhoto?.id == photo.id { selectedPhoto = nil }
        } catch {
            AppLogger.storage.error("ProgressPhotoViewModel.delete: \(error.localizedDescription)")
            loadState = .error(error.localizedDescription)
        }
    }

    func openViewer(for photo: ProgressPhoto) {
        selectedPhoto   = photo
        isShowingViewer = true
    }
}
