//
//  ComparisonView.swift
//  GYM APP
//

import SwiftUI

struct ComparisonView: View {
    let checkInA: CheckIn
    let checkInB: CheckIn
    var isModal: Bool = false

    @State private var viewModel = ComparisonViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if viewModel.isEmpty && viewModel.summary == nil {
                loadingState
            } else {
                content
            }
        }
        .navigationTitle("Comparación")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            if isModal {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
        .onAppear {
            viewModel.configure(checkInA: checkInA, checkInB: checkInB)
        }
    }

    // MARK: - Content

    private var content: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppSpacing.lg) {
                if let summary = viewModel.summary {
                    ComparisonSummaryView(summary: summary)
                }

                ForEach(viewModel.sections) { section in
                    sectionBlock(section)
                }

                if let photos = viewModel.photoComparison, photos.hasAny {
                    photoBlock(photos)
                }

                if viewModel.hasNotes {
                    notesBlock
                }
            }
            .padding(.horizontal, AppSpacing.base)
            .padding(.vertical, AppSpacing.base)
            .padding(.bottom, AppSpacing.xxxl)
        }
    }

    // MARK: - Section block

    private func sectionBlock(_ section: ComparisonSection) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Label(section.title, systemImage: section.systemImage)
                .font(.headline)
                .padding(.horizontal, AppSpacing.xs)

            VStack(spacing: AppSpacing.xs) {
                ForEach(section.rows) { row in
                    ComparisonMetricCard(row: row)
                }
            }
        }
    }

    // MARK: - Photo block

    private func photoBlock(_ photos: PhotoComparison) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Label("Fotografías de Posing", systemImage: "camera.fill")
                .font(.headline)
                .padding(.horizontal, AppSpacing.xs)

            PhotoComparisonSection(comparison: photos)
                .padding(AppSpacing.md)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    // MARK: - Notes block

    private var notesBlock: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Label("Notas", systemImage: "note.text")
                .font(.headline)
                .padding(.horizontal, AppSpacing.xs)

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                noteCard(
                    title: "Coach (Antes)",
                    text: viewModel.earlierCheckIn?.coachNote?.text,
                    icon: "note.text",
                    color: .indigo
                )
                noteCard(
                    title: "Coach (Después)",
                    text: viewModel.laterCheckIn?.coachNote?.text,
                    icon: "note.text",
                    color: .indigo
                )
                noteCard(
                    title: "Atleta (Antes)",
                    text: viewModel.earlierCheckIn?.athleteNote?.text,
                    icon: "person.text.rectangle.fill",
                    color: .mint
                )
                noteCard(
                    title: "Atleta (Después)",
                    text: viewModel.laterCheckIn?.athleteNote?.text,
                    icon: "person.text.rectangle.fill",
                    color: .mint
                )
            }
        }
    }

    @ViewBuilder
    private func noteCard(title: String, text: String?, icon: String, color: Color) -> some View {
        let trimmed = text?.trimmingCharacters(in: .whitespaces) ?? ""
        if !trimmed.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Label(title, systemImage: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(color)

                Text(trimmed)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(AppSpacing.sm)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
    }

    // MARK: - Loading state

    private var loadingState: some View {
        ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
