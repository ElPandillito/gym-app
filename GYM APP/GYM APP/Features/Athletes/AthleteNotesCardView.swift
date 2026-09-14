//
//  AthleteNotesCardView.swift
//  GYM APP
//
//  Shows the coach/athlete notes from the most recent check-in.
//  NavigationLink leads directly to CheckInDetailView where notes can be edited.
//

import SwiftUI

struct AthleteNotesCardView: View {
    let latestCheckIn: CheckIn?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            AppSectionHeader("Notas del Último Check-In", icon: "note.text")

            if let checkIn = latestCheckIn {
                noteCard(for: checkIn)
            } else {
                EmptyStateView(
                    icon: "note.text",
                    title: "Sin check-ins",
                    message: "Registra el primer check-in para agregar notas al coach."
                )
            }
        }
    }

    // MARK: - Note card

    private func noteCard(for checkIn: CheckIn) -> some View {
        let coachText   = checkIn.coachNote?.text
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let athleteText = checkIn.athleteNote?.text
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let hasNotes    = !coachText.isEmpty || !athleteText.isEmpty

        return NavigationLink {
            CheckInDetailView(checkIn: checkIn)
        } label: {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                dateHeader(for: checkIn.date)

                if hasNotes {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        if !coachText.isEmpty {
                            noteRow(label: "Coach", text: coachText, icon: "note.text")
                        }
                        if !athleteText.isEmpty {
                            noteRow(label: "Atleta", text: athleteText,
                                    icon: "person.text.rectangle")
                        }
                    }
                } else {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "plus.circle")
                            .font(AppTypography.footnote)
                            .foregroundStyle(AppColors.accent)
                        Text("Agregar notas a este check-in")
                            .font(AppTypography.footnote)
                            .foregroundStyle(AppColors.accent)
                        Spacer()
                    }
                }

                HStack {
                    Spacer()
                    Label(
                        hasNotes ? "Editar notas" : "Ir al check-in",
                        systemImage: "chevron.right"
                    )
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.accent)
                }
            }
            .padding(AppSpacing.base)
            .background(AppColors.secondaryBg, in: RoundedRectangle(cornerRadius: AppRadius.lg))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func dateHeader(for date: Date) -> some View {
        Text(date.formatted(.dateTime.day().month(.abbreviated).year()))
            .font(AppTypography.caption)
            .foregroundStyle(AppColors.secondaryText)
    }

    private func noteRow(label: String, text: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(AppColors.secondaryText)
                .frame(width: 16)
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(label)
                    .font(AppTypography.caption2)
                    .foregroundStyle(AppColors.secondaryText)
                Text(text)
                    .font(AppTypography.footnote)
                    .foregroundStyle(AppColors.primaryText)
                    .lineLimit(3)
            }
        }
    }
}
