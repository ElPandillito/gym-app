//
//  CheckInListView.swift
//  GYM APP
//

import SwiftUI
import SwiftData

struct CheckInListView: View {
    @Environment(\.modelContext) private var context
    let athlete: Athlete

    @State private var viewModel = CheckInListViewModel()

    var body: some View {
        let repository = CheckInRepository(context: context)
        let sorted     = viewModel.sorted(athlete.checkIns)

        Group {
            if athlete.checkIns.isEmpty {
                ContentUnavailableView {
                    Label("Sin Check Ins", systemImage: "calendar.badge.plus")
                } description: {
                    Text("Registra el primer check in de \(athlete.name).")
                } actions: {
                    Button { viewModel.requestCreate() } label: {
                        Label("Nuevo Check In", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                List {
                    ForEach(sorted) { checkIn in
                        NavigationLink(destination: CheckInDetailView(checkIn: checkIn)) {
                            CheckInRowView(checkIn: checkIn)
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button {
                                viewModel.requestEdit(checkIn)
                            } label: {
                                Label("Editar", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                viewModel.requestDelete(checkIn)
                            } label: {
                                Label("Eliminar", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { viewModel.requestCreate() } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $viewModel.isShowingCreateSheet) {
            CheckInFormView(athlete: athlete)
        }
        .sheet(isPresented: $viewModel.isShowingEditSheet) {
            if let checkIn = viewModel.checkInToEdit {
                CheckInFormView(checkIn: checkIn)
            }
        }
        .alert("Eliminar Check In", isPresented: $viewModel.isShowingDeleteAlert) {
            Button("Eliminar", role: .destructive) {
                viewModel.confirmDelete(using: repository)
            }
            Button("Cancelar", role: .cancel) {
                viewModel.cancelDelete()
            }
        } message: {
            if let checkIn = viewModel.checkInToDelete {
                let dateStr = checkIn.date.formatted(.dateTime.day().month(.wide).year())
                Text("¿Deseas eliminar el check in del \(dateStr)? Esta acción no se puede deshacer.")
            }
        }
    }
}

// MARK: - Row View

struct CheckInRowView: View {
    let checkIn: CheckIn

    var body: some View {
        HStack(spacing: 14) {
            dateBadge

            VStack(alignment: .leading, spacing: 4) {
                Text(checkIn.date.formatted(.dateTime.day().month(.wide).year()))
                    .font(.subheadline.weight(.medium))

                infoRow
            }

            Spacer()

            if hasNotes {
                Image(systemName: "note.text")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var dateBadge: some View {
        VStack(spacing: 1) {
            Text(checkIn.date.formatted(.dateTime.day()))
                .font(.title3.bold())
            Text(checkIn.date.formatted(.dateTime.month(.abbreviated)).uppercased())
                .font(.caption2.bold())
                .foregroundStyle(.secondary)
        }
        .frame(width: 46, height: 46)
        .background(Color.accentColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private var infoRow: some View {
        let weight    = checkIn.bodyMetrics?.bodyWeight
        let fatPct    = checkIn.bodyMetrics?.bodyFatPercentage
                        ?? checkIn.skinfolds?.estimatedBodyFatPercentage
        let photoCount = checkIn.photos.count

        if weight == nil && fatPct == nil && photoCount == 0 {
            Text("Sin datos registrados")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            HStack(spacing: 10) {
                if let w = weight {
                    Label(String(format: "%.1f kg", w), systemImage: "scalemass")
                }
                if let f = fatPct {
                    Label(String(format: "%.1f%%", f), systemImage: "flame")
                }
                if photoCount > 0 {
                    Label("\(photoCount)", systemImage: "camera")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private var hasNotes: Bool {
        let coachHasText   = !(checkIn.coachNote?.text.trimmingCharacters(in: .whitespaces).isEmpty ?? true)
        let athleteHasText = !(checkIn.athleteNote?.text.trimmingCharacters(in: .whitespaces).isEmpty ?? true)
        return coachHasText || athleteHasText
    }
}

#Preview("iPhone 16") {
    let athlete = Athlete(name: "Carlos Ramírez", gender: .male)
    NavigationStack {
        CheckInListView(athlete: athlete)
    }
    .modelContainer(for: [Athlete.self, CheckIn.self], inMemory: true)
    .previewDevice(PreviewDevice(rawValue: "iPhone 16"))
}
