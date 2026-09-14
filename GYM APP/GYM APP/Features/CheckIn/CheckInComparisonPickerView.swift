//
//  CheckInComparisonPickerView.swift
//  GYM APP
//

import SwiftUI

struct CheckInComparisonPickerView: View {
    let athlete: Athlete

    @Environment(\.dismiss) private var dismiss

    @State private var selectionA: CheckIn?
    @State private var selectionB: CheckIn?
    @State private var activePair: CheckInPair?

    private var sortedCheckIns: [CheckIn] {
        athlete.checkIns.sorted { $0.date > $1.date }
    }

    private var canCompare: Bool {
        guard let a = selectionA, let b = selectionB else { return false }
        return a.id != b.id
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(sortedCheckIns) { checkIn in
                        CheckInPickerRow(
                            checkIn: checkIn,
                            selectionA: $selectionA,
                            selectionB: $selectionB
                        )
                    }
                } header: {
                    Text("Selecciona dos check-ins para comparar")
                        .textCase(nil)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, AppSpacing.xs)
                }
            }
            #if os(iOS)
            .listStyle(.insetGrouped)
            #endif
            .navigationTitle("Comparar Check-Ins")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Comparar") {
                        if let a = selectionA, let b = selectionB {
                            activePair = CheckInPair(a: a, b: b)
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(!canCompare)
                }
            }
            .navigationDestination(item: $activePair) { pair in
                ComparisonView(checkInA: pair.a, checkInB: pair.b)
            }
        }
    }
}

// MARK: - CheckInPair (local navigation token)

private struct CheckInPair: Identifiable, Hashable {
    let id = UUID()
    let a: CheckIn
    let b: CheckIn

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: CheckInPair, rhs: CheckInPair) -> Bool { lhs.id == rhs.id }
}

// MARK: - Row

private struct CheckInPickerRow: View {
    let checkIn: CheckIn
    @Binding var selectionA: CheckIn?
    @Binding var selectionB: CheckIn?

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(checkIn.date.formatted(.dateTime.day().month(.wide).year()))
                    .font(.subheadline)

                if let w = checkIn.bodyMetrics?.bodyWeight {
                    Text(String(format: "%.1f kg", w))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Sin peso registrado")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            HStack(spacing: AppSpacing.sm) {
                selectionButton(label: "1", selection: $selectionA, other: $selectionB)
                selectionButton(label: "2", selection: $selectionB, other: $selectionA)
            }
        }
        .contentShape(Rectangle())
    }

    private func selectionButton(
        label: String,
        selection: Binding<CheckIn?>,
        other: Binding<CheckIn?>
    ) -> some View {
        let isSelected = selection.wrappedValue?.id == checkIn.id
        return Button {
            if isSelected {
                selection.wrappedValue = nil
            } else {
                // If this check-in was selected on the OTHER slot, clear it there first
                if other.wrappedValue?.id == checkIn.id {
                    other.wrappedValue = nil
                }
                selection.wrappedValue = checkIn
            }
        } label: {
            Text(label)
                .font(.caption.weight(.bold))
                .frame(width: 30, height: 30)
                .foregroundStyle(isSelected ? .white : Color.accentColor)
                .background(isSelected ? Color.accentColor : Color.accentColor.opacity(0.12))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}
