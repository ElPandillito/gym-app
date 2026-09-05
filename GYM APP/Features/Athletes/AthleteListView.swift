//
//  AthleteListView.swift
//  GYM APP
//

import SwiftUI
import SwiftData

struct AthleteListView: View {
    @Environment(\.modelContext) private var context
    @Query private var athletes: [Athlete]
    @State private var viewModel = AthleteListViewModel()

    var body: some View {
        let displayed = viewModel.filtered(athletes)
        let repository = AthleteRepository(context: context)

        Group {
            if athletes.isEmpty {
                ContentUnavailableView {
                    Label("Sin atletas", systemImage: "person.3.fill")
                } description: {
                    Text("Agrega tu primer atleta con el botón +")
                }
            } else if displayed.isEmpty {
                ContentUnavailableView.search(text: viewModel.searchText)
            } else {
                List {
                    ForEach(displayed) { athlete in
                        NavigationLink(destination: AthleteDetailView(athlete: athlete)) {
                            AthleteRowView(athlete: athlete)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                viewModel.requestDelete(athlete)
                            } label: {
                                Label("Eliminar", systemImage: "trash")
                            }
                        }
                    }
                }
                #if os(iOS)
                .listStyle(.insetGrouped)
                #endif
            }
        }
        .navigationTitle("Atletas")
        .searchable(text: $viewModel.searchText, prompt: "Buscar atleta")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { viewModel.addAthlete() } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .secondaryAction) {
                Menu {
                    ForEach(AthleteSortOrder.allCases, id: \.self) { order in
                        Button {
                            viewModel.sortOrder = order
                        } label: {
                            HStack {
                                Text(order.rawValue)
                                if viewModel.sortOrder == order {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                }
            }
        }
        .sheet(isPresented: $viewModel.isShowingForm) {
            AthleteFormView(athlete: viewModel.athleteToEdit)
        }
        .alert("Eliminar atleta", isPresented: $viewModel.isShowingDeleteAlert) {
            Button("Eliminar", role: .destructive) {
                viewModel.confirmDelete(using: repository)
            }
            Button("Cancelar", role: .cancel) {
                viewModel.cancelDelete()
            }
        } message: {
            if let name = viewModel.athleteToDelete?.name {
                Text("¿Deseas eliminar a \(name)? Esta acción no se puede deshacer.")
            }
        }
    }
}

// MARK: - Row View

struct AthleteRowView: View {
    let athlete: Athlete

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.accentColor.opacity(0.15))
                .frame(width: 46, height: 46)
                .overlay {
                    Text(initials)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.accentColor)
                }
                .overlay(alignment: .topTrailing) {
                    if let dotColor = alertDotColor {
                        Circle()
                            .fill(dotColor)
                            .frame(width: 11, height: 11)
                            .overlay {
                                Circle().strokeBorder(.background, lineWidth: 1.5)
                            }
                    }
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(athlete.name)
                    .font(.body.weight(.medium))
                HStack(spacing: 6) {
                    Text(lastCheckInLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Label(athlete.phase.displayName, systemImage: athlete.phase.systemImage)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(Color.accentColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.10), in: Capsule())
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var initials: String {
        athlete.name.split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }
            .map(String.init)
            .joined()
            .uppercased()
    }

    // Returns the dot color for the highest-severity alert, nil if none.
    private var alertDotColor: Color? {
        let sorted    = athlete.checkIns.sorted { $0.date < $1.date }
        let snapshots = sorted.map(CheckInSnapshot.init)
        guard let top = AthleteAlertEvaluator.evaluate(
            athleteID:      athlete.id,
            athleteName:    athlete.name,
            sortedCheckIns: snapshots,
            preferences:    CoachPreferences.default,
            now:            Date()
        ).first else { return nil }
        switch top.severity {
        case 3...: return AppColors.error
        case 2:    return AppColors.warning
        default:   return AppColors.info
        }
    }

    private var lastCheckInLabel: String {
        guard let last = athlete.checkIns.max(by: { $0.date < $1.date }) else {
            return "Sin check ins recientes"
        }
        let date: Date = last.date
        return "Último: " + date.formatted(.dateTime.month(.abbreviated).day().year())
    }
}

#Preview("iPhone 16") {
    NavigationStack {
        AthleteListView()
    }
    .modelContainer(for: Athlete.self, inMemory: true)
    .previewDevice(PreviewDevice(rawValue: "iPhone 16"))
}
