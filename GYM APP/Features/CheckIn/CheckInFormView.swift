//
//  CheckInFormView.swift
//  GYM APP
//

import SwiftUI
import SwiftData

struct CheckInFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    private let athlete: Athlete?
    private let checkIn: CheckIn?

    @State private var date: Date
    @State private var coachNoteText: String
    @State private var athleteNoteText: String

    // Create mode — only captures date; all other fields remain nil
    init(athlete: Athlete) {
        self.athlete  = athlete
        self.checkIn  = nil
        _date             = State(initialValue: Date())
        _coachNoteText    = State(initialValue: "")
        _athleteNoteText  = State(initialValue: "")
    }

    // Edit mode — date + notes
    init(checkIn: CheckIn) {
        self.athlete  = nil
        self.checkIn  = checkIn
        _date             = State(initialValue: checkIn.date)
        _coachNoteText    = State(initialValue: checkIn.coachNote?.text ?? "")
        _athleteNoteText  = State(initialValue: checkIn.athleteNote?.text ?? "")
    }

    private var isEditing: Bool { checkIn != nil }
    private var title: String   { isEditing ? "Editar Check In" : "Nuevo Check In" }

    var body: some View {
        NavigationStack {
            Form {
                Section("Fecha") {
                    DatePicker(
                        "Fecha del Check In",
                        selection: $date,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                }

                if isEditing {
                    Section {
                        TextEditor(text: $coachNoteText)
                            .frame(minHeight: 80)
                    } header: {
                        Text("Nota del Coach")
                    } footer: {
                        Text("Observaciones del entrenador sobre este check in.")
                    }

                    Section {
                        TextEditor(text: $athleteNoteText)
                            .frame(minHeight: 80)
                    } header: {
                        Text("Nota del Atleta")
                    } footer: {
                        Text("Comentarios o sensaciones del atleta.")
                    }
                }
            }
            .navigationTitle(title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        save()
                        dismiss()
                    }
                }
            }
        }
    }

    private func save() {
        let repository = CheckInRepository(context: context)
        if let checkIn {
            checkIn.date = date
            try? repository.saveNotes(
                coachText:   coachNoteText,
                athleteText: athleteNoteText,
                for:         checkIn
            )
        } else if let athlete {
            let newCheckIn = CheckIn(date: date)
            try? repository.add(newCheckIn, to: athlete)
        }
    }
}
