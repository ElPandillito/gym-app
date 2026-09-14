//
//  PhotoComparisonSection.swift
//  GYM APP
//

import SwiftUI

struct PhotoComparisonSection: View {
    let comparison: PhotoComparison
    var slideMode: Bool = false  // hook for future side-by-side slide interaction

    private let storage = PhotoStorageService()

    private var rowCount: Int {
        max(comparison.photosA.count, comparison.photosB.count)
    }

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            columnHeaders
            ForEach(0..<rowCount, id: \.self) { i in
                photoRow(index: i)
            }
        }
    }

    // MARK: - Column headers

    private var columnHeaders: some View {
        HStack(spacing: AppSpacing.sm) {
            Text(comparison.dateA.formatted(.dateTime.day().month(.abbreviated).year()))
                .frame(maxWidth: .infinity)
            Text(comparison.dateB.formatted(.dateTime.day().month(.abbreviated).year()))
                .frame(maxWidth: .infinity)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
    }

    // MARK: - Photo rows

    private func photoRow(index: Int) -> some View {
        HStack(spacing: AppSpacing.sm) {
            photoCell(photo: comparison.photosA.indices.contains(index) ? comparison.photosA[index] : nil)
            photoCell(photo: comparison.photosB.indices.contains(index) ? comparison.photosB[index] : nil)
        }
    }

    @ViewBuilder
    private func photoCell(photo: ProgressPhoto?) -> some View {
        if let photo = photo {
            AsyncDiskImageView(
                relativePath: photo.thumbnailPath ?? photo.originalPath,
                storage: storage,
                contentMode: .fill
            )
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.secondary.opacity(0.10))
                .frame(maxWidth: .infinity)
                .frame(height: 180)
                .overlay {
                    Image(systemName: "photo")
                        .font(.title3)
                        .foregroundStyle(.tertiary)
                }
        }
    }
}
