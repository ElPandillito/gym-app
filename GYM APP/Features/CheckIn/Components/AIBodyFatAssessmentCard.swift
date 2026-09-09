//
//  AIBodyFatAssessmentCard.swift
//  GYM APP
//

import SwiftUI
import SwiftData

struct AIBodyFatAssessmentCard: View {
    let checkIn: CheckIn
    @Environment(\.modelContext) private var context
    @State private var viewModel = BodyFatAssessmentViewModel()

    var body: some View {
        Section {
            switch viewModel.state {
            case .idle:
                idleView
            case .loading:
                loadingView
            case .result(let assessment):
                resultView(assessment)
            case .error(let message):
                errorView(message)
            }
        } header: {
            Label("Estimación IA de Grasa Corporal", systemImage: "sparkles")
        } footer: {
            Text("Estimación basada en datos antropométricos disponibles. No reemplaza la evaluación profesional.")
                .font(.caption2)
        }
        .onAppear { viewModel.loadExisting(from: checkIn) }
    }

    // MARK: - Idle

    private var idleView: some View {
        Button {
            viewModel.run(for: checkIn, context: context)
        } label: {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "brain")
                    .foregroundStyle(Color.accentColor)
                Text("Estimar grasa corporal con IA")
                    .foregroundStyle(Color.accentColor)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Loading

    private var loadingView: some View {
        HStack(spacing: AppSpacing.sm) {
            ProgressView().controlSize(.small)
            Text("Analizando datos…")
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Result

    private func resultView(_ a: AIBodyFatAssessment) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(format: "%.1f %%", a.estimatedBodyFatPct))
                        .font(.title2.bold())
                        .foregroundStyle(fatColor(a.estimatedBodyFatPct))
                    Text("Grasa corporal estimada")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    confidenceBadge(a.confidenceScore)
                    basisBadge(a.assessmentBasis)
                }
            }

            confidenceBar(a.confidenceScore)

            if !a.notes.isEmpty {
                Divider()
                ForEach(a.notes, id: \.self) { note in
                    Label(note, systemImage: "info.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Button("Volver a estimar") {
                viewModel.reset()
            }
            .font(.caption)
            .foregroundStyle(.tertiary)
        }
        .padding(.vertical, AppSpacing.xs)
    }

    // MARK: - Error

    private func errorView(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Label(message, systemImage: "exclamationmark.triangle")
                .font(.subheadline)
                .foregroundStyle(.orange)

            Button("Reintentar") {
                viewModel.reset()
            }
            .font(.caption)
            .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Subcomponents

    private func confidenceBar(_ score: Double) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(Color.secondary.opacity(0.15))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(confidenceColor(score))
                        .frame(width: geo.size.width * score)
                }
            }
            .frame(height: 6)

            Text(String(format: "Confianza: %.0f %%", score * 100))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func confidenceBadge(_ score: Double) -> some View {
        Text(confidenceLabel(score))
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(confidenceColor(score).opacity(0.15), in: Capsule())
            .foregroundStyle(confidenceColor(score))
    }

    @ViewBuilder
    private func basisBadge(_ basis: AssessmentBasis) -> some View {
        Text(basisLabel(basis))
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.secondary.opacity(0.12), in: Capsule())
            .foregroundStyle(.secondary)
    }

    // MARK: - Helpers

    private func fatColor(_ pct: Double) -> Color {
        switch pct {
        case ..<8:    return .blue
        case 8..<16:  return .green
        case 16..<24: return .yellow
        case 24..<32: return .orange
        default:      return .red
        }
    }

    private func confidenceColor(_ score: Double) -> Color {
        switch score {
        case 0.5...: return .green
        case 0.35...: return .yellow
        default:      return .orange
        }
    }

    private func confidenceLabel(_ score: Double) -> String {
        switch score {
        case 0.5...: return "Media"
        case 0.35...: return "Baja"
        default:      return "Muy baja"
        }
    }

    private func basisLabel(_ basis: AssessmentBasis) -> String {
        switch basis {
        case .visionOnly:        return "Visión"
        case .visionWithContext: return "Visión + datos"
        case .stubDeterministic: return "Datos antropométricos"
        }
    }
}
