//
//  CheckInDetailView.swift
//  GYM APP
//

import SwiftUI
import SwiftData

struct CheckInDetailView: View {
    let checkIn: CheckIn
    @State private var viewModel = CheckInDetailViewModel()

    private var previousCheckIn: CheckIn? {
        checkIn.athlete?.checkIns
            .filter { $0.date < checkIn.date }
            .max(by: { $0.date < $1.date })
    }

    var body: some View {
        List {
            bodyWeightSection
            photosSection
            igcSection
            skinfoldSection
            circumferenceSection
            notesSection
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .navigationTitle(checkIn.date.formatted(.dateTime.day().month(.wide).year()))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { viewModel.isShowingEditSheet = true } label: {
                    Image(systemName: "square.and.pencil")
                }
            }
            ToolbarItem(placement: .secondaryAction) {
                Button {
                    viewModel.isShowingComparison = true
                } label: {
                    Image(systemName: "chart.bar.doc.horizontal")
                }
                .disabled(previousCheckIn == nil)
            }
        }
        .sheet(isPresented: $viewModel.isShowingEditSheet) {
            CheckInFormView(checkIn: checkIn)
        }
        .sheet(isPresented: $viewModel.isShowingComparison) {
            if let prev = previousCheckIn {
                NavigationStack {
                    ComparisonView(checkInA: checkIn, checkInB: prev, isModal: true)
                }
            }
        }
        .sheet(isPresented: $viewModel.isShowingBodyMetricsForm) {
            BodyMetricsFormView(checkIn: checkIn)
        }
        .sheet(isPresented: $viewModel.isShowingCircumferencesForm) {
            CircumferenceMeasurementsFormView(checkIn: checkIn)
        }
        .sheet(isPresented: $viewModel.isShowingSkinfoldForm) {
            SkinfoldMeasurementsFormView(checkIn: checkIn)
        }
    }

    // MARK: - Sections

    private var bodyWeightSection: some View {
        Section {
            if let metrics = checkIn.bodyMetrics {
                if let w = metrics.bodyWeight {
                    MetricRow(label: "Peso corporal",    value: String(format: "%.2f kg", w))
                }
                if let bmi = metrics.bmi {
                    MetricRow(label: "IMC",              value: String(format: "%.1f kg/m²", bmi))
                }
                if let f = metrics.bodyFatPercentage {
                    MetricRow(label: "% Grasa corporal", value: String(format: "%.1f%%", f))
                }
                if let m = metrics.muscleMass {
                    MetricRow(label: "Masa muscular",    value: String(format: "%.2f kg", m))
                }
                if let wt = metrics.waterPercentage {
                    MetricRow(label: "Agua corporal",    value: String(format: "%.1f%%", wt))
                }
                if let b = metrics.boneMass {
                    MetricRow(label: "Masa ósea",        value: String(format: "%.2f kg", b))
                }
                if let vf = metrics.visceralFatLevel {
                    MetricRow(label: "Grasa visceral",   value: String(format: "%.0f", vf))
                }
                if let bmr = metrics.basalMetabolicRate {
                    MetricRow(label: "TMB",              value: String(format: "%.0f kcal", bmr))
                }
                Button {
                    viewModel.isShowingBodyMetricsForm = true
                } label: {
                    Label("Editar métricas", systemImage: "pencil")
                }
                .foregroundStyle(Color.accentColor)
            } else {
                CheckInEmptyRow(label: "Sin datos de peso", icon: "scalemass")
                Button {
                    viewModel.isShowingBodyMetricsForm = true
                } label: {
                    Label("Registrar peso corporal", systemImage: "plus")
                }
                .foregroundStyle(Color.accentColor)
            }
        } header: {
            Label("Peso Corporal", systemImage: "scalemass.fill")
        }
    }

    private var photosSection: some View {
        Section {
            NavigationLink {
                ProgressPhotoGridView(checkIn: checkIn)
            } label: {
                if checkIn.photos.isEmpty {
                    CheckInEmptyRow(label: "Sin fotografías", icon: "camera")
                } else {
                    let count = checkIn.photos.count
                    HStack {
                        Label("Posing", systemImage: "camera")
                        Spacer()
                        Text("\(count) \(count == 1 ? "foto" : "fotos")")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        } header: {
            Label("Fotografías de Posing", systemImage: "camera.fill")
        }
    }

    private var igcSection: some View {
        Section {
            if let directFat = checkIn.bodyMetrics?.bodyFatPercentage {
                MetricRow(label: "% Grasa (bio-impedancia)", value: String(format: "%.1f%%", directFat))
            } else if let estimatedFat = checkIn.skinfolds?.estimatedBodyFatPercentage {
                MetricRow(label: "% Grasa (plicometría)", value: String(format: "%.1f%%", estimatedFat))
            } else {
                CheckInEmptyRow(label: "Sin datos de IGC", icon: "percent")
            }
        } header: {
            Label("IGC / % Grasa Corporal", systemImage: "flame.fill")
        }
    }

    private var skinfoldSection: some View {
        Section {
            if let sf = checkIn.skinfolds {
                MetricRow(label: "Método", value: sf.method.displayName)
                if let fat = sf.estimatedBodyFatPercentage {
                    MetricRow(label: "% Grasa estimado", value: String(format: "%.1f %%", fat))
                }
                if let bd = sf.bodyDensity {
                    MetricRow(label: "Densidad corporal", value: String(format: "%.4f g/mL", bd))
                }
                if let t = sf.tester, !t.isEmpty {
                    MetricRow(label: "Evaluador", value: t)
                }
                if let cb = sf.caliperBrand, !cb.isEmpty {
                    MetricRow(label: "Plicómetro", value: cb)
                }
                Button {
                    viewModel.isShowingSkinfoldForm = true
                } label: {
                    Label("Editar plicometría", systemImage: "pencil")
                }
                .foregroundStyle(Color.accentColor)
            } else {
                CheckInEmptyRow(label: "Sin plicometría", icon: "ruler")
                Button {
                    viewModel.isShowingSkinfoldForm = true
                } label: {
                    Label("Registrar plicometría", systemImage: "plus")
                }
                .foregroundStyle(Color.accentColor)
            }
        } header: {
            Label("Plicometría", systemImage: "ruler.fill")
        }
    }

    private var circumferenceSection: some View {
        Section {
            if let c = checkIn.circumferences {
                if let v = c.neck         { MetricRow(label: "Cuello",                value: String(format: "%.1f cm", v)) }
                if let v = c.shoulders    { MetricRow(label: "Hombros",               value: String(format: "%.1f cm", v)) }
                if let v = c.chest        { MetricRow(label: "Pecho",                 value: String(format: "%.1f cm", v)) }
                if let v = c.rightArm     { MetricRow(label: "Brazo derecho",         value: String(format: "%.1f cm", v)) }
                if let v = c.leftArm      { MetricRow(label: "Brazo izquierdo",       value: String(format: "%.1f cm", v)) }
                if let v = c.rightForearm { MetricRow(label: "Antebrazo derecho",     value: String(format: "%.1f cm", v)) }
                if let v = c.leftForearm  { MetricRow(label: "Antebrazo izquierdo",   value: String(format: "%.1f cm", v)) }
                if let v = c.waist        { MetricRow(label: "Cintura",               value: String(format: "%.1f cm", v)) }
                if let v = c.abdomen      { MetricRow(label: "Abdomen",               value: String(format: "%.1f cm", v)) }
                if let v = c.hips         { MetricRow(label: "Cadera / Glúteos",      value: String(format: "%.1f cm", v)) }
                if let v = c.rightThigh   { MetricRow(label: "Muslo derecho",         value: String(format: "%.1f cm", v)) }
                if let v = c.leftThigh    { MetricRow(label: "Muslo izquierdo",       value: String(format: "%.1f cm", v)) }
                if let v = c.rightCalf    { MetricRow(label: "Pantorrilla derecha",   value: String(format: "%.1f cm", v)) }
                if let v = c.leftCalf     { MetricRow(label: "Pantorrilla izquierda", value: String(format: "%.1f cm", v)) }
                Button {
                    viewModel.isShowingCircumferencesForm = true
                } label: {
                    Label("Editar medidas", systemImage: "pencil")
                }
                .foregroundStyle(Color.accentColor)
            } else {
                CheckInEmptyRow(label: "Sin medidas corporales", icon: "arrow.left.and.right")
                Button {
                    viewModel.isShowingCircumferencesForm = true
                } label: {
                    Label("Registrar medidas corporales", systemImage: "plus")
                }
                .foregroundStyle(Color.accentColor)
            }
        } header: {
            Label("Medidas Corporales", systemImage: "arrow.left.and.right.circle.fill")
        }
    }

    private var notesSection: some View {
        Section {
            let coachText   = checkIn.coachNote?.text.trimmingCharacters(in: .whitespaces) ?? ""
            let athleteText = checkIn.athleteNote?.text.trimmingCharacters(in: .whitespaces) ?? ""

            if coachText.isEmpty {
                CheckInEmptyRow(label: "Sin notas del coach", icon: "note.text")
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Coach")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(coachText)
                        .font(.body)
                }
                .padding(.vertical, 4)
            }

            if athleteText.isEmpty {
                CheckInEmptyRow(label: "Sin notas del atleta", icon: "person.text.rectangle")
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Atleta")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(athleteText)
                        .font(.body)
                }
                .padding(.vertical, 4)
            }
        } header: {
            Label("Notas", systemImage: "note.text")
        }
    }
}

// MARK: - Metric Row

private struct MetricRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Empty Row

private struct CheckInEmptyRow: View {
    let label: String
    let icon: String

    var body: some View {
        HStack {
            Spacer()
            Label(label, systemImage: icon)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.vertical, 8)
            Spacer()
        }
    }
}

#Preview("iPhone 16") {
    let checkIn = CheckIn(date: .now)
    NavigationStack {
        CheckInDetailView(checkIn: checkIn)
    }
    .modelContainer(for: [CheckIn.self], inMemory: true)
    .previewDevice(PreviewDevice(rawValue: "iPhone 16"))
}
