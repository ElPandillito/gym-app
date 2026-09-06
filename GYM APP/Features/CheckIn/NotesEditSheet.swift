//
//  NotesEditSheet.swift
//  GYM APP
//
//  Lightweight sheet for editing CoachNote and AthleteNote on an existing CheckIn.
//  Saves via CheckInRepository.saveNotes() which handles create/update/delete logic.
//

import SwiftUI
import SwiftData

struct NotesEditSheet: View {
    let checkIn: CheckIn

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss)      private var dismiss

    @State private var coachText:   String = ""
    @State private var athleteText: String = ""
    @State private var saveError:   String? = nil
    @State private var isSaving:    Bool = false

    var body: some View {
        NavigationStack {
            Form {
                coachSection
                athleteSection
            }
            #if os(iOS)
            .listStyle(.insetGrouped)
            #endif
            .navigationTitle("Notas del Check-In")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { save() }
                        .disabled(isSaving)
                }
            }
            .alert("Error al guardar", isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("Aceptar", role: .cancel) {}
            } message: {
                Text(saveError ?? "")
            }
        }
        .onAppear { loadExistingNotes() }
    }

    // MARK: - Sections

    private var coachSection: some View {
        Section {
            TextEditor(text: $coachText)
                .frame(minHeight: 100)
        } header: {
            Label("Nota del Coach", systemImage: "note.text")
        } footer: {
            Text("Dejar vacío para eliminar la nota del coach.")
                .font(.caption)
        }
    }

    private var athleteSection: some View {
        Section {
            TextEditor(text: $athleteText)
                .frame(minHeight: 100)
        } header: {
            Label("Nota del Atleta", systemImage: "person.text.rectangle")
        } footer: {
            Text("Dejar vacío para eliminar la nota del atleta.")
                .font(.caption)
        }
    }

    // MARK: - Logic

    private func loadExistingNotes() {
        coachText   = checkIn.coachNote?.text   ?? ""
        athleteText = checkIn.athleteNote?.text ?? ""
    }

    private func save() {
        isSaving = true
        let repo = CheckInRepository(context: context)
        do {
            try repo.saveNotes(coachText: coachText, athleteText: athleteText, for: checkIn)
            dismiss()
        } catch {
            saveError = "No se pudieron guardar las notas. Inténtalo de nuevo."
        }
        isSaving = false
    }
}
