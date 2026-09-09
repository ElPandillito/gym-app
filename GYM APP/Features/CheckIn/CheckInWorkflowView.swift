//
//  CheckInWorkflowView.swift
//  GYM APP
//

import SwiftUI
import SwiftData

struct CheckInWorkflowView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss)      private var dismiss
    @Environment(CoachPreferencesStore.self) private var prefsStore

    private var fmt: AppUnitFormatter { AppUnitFormatter(preferences: prefsStore.preferences) }

    @State private var viewModel: CheckInWorkflowViewModel

    init(athlete: Athlete) {
        _viewModel = State(initialValue: CheckInWorkflowViewModel(athlete: athlete))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                stepNavigator
                Divider()
                stepContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                Divider()
                navigationFooter
            }
            .navigationTitle("Nuevo Check In")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        viewModel.cancel()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .principal) {
                    DatePicker(
                        "",
                        selection: $viewModel.date,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                    .labelsHidden()
                }
            }
            .alert(
                "Error al guardar",
                isPresented: Binding(
                    get: { viewModel.saveError != nil },
                    set: { if !$0 { viewModel.saveError = nil } }
                )
            ) {
                Button("OK") { viewModel.saveError = nil }
            } message: {
                if let err = viewModel.saveError { Text(err) }
            }
            .alert(
                "No se pudo agregar la foto",
                isPresented: Binding(
                    get: { viewModel.photoAddError != nil },
                    set: { if !$0 { viewModel.photoAddError = nil } }
                )
            ) {
                Button("OK") { viewModel.photoAddError = nil }
            } message: {
                if let err = viewModel.photoAddError { Text(err) }
            }
            .onChange(of: viewModel.savedCheckIn) { _, saved in
                if saved != nil { dismiss() }
            }
            .onAppear {
                viewModel.apply(preferences: prefsStore.preferences)
            }
            .onChange(of: prefsStore.preferences) { _, prefs in
                viewModel.apply(preferences: prefs)
            }
            .onChange(of: viewModel.bodyMetrics.weightText) { _, newText in
                viewModel.skinfolds.bodyWeightKg = newText.asPositiveDouble.map { fmt.toCanonicalWeight($0) }
            }
            .onChange(of: viewModel.anthropometryProfile) { _, _ in
                viewModel.profileDidChange()
            }
        }
        .sheet(isPresented: $viewModel.isShowingPhotoForm) {
            ProgressPhotoForm(storage: PhotoStorageService()) { data, poseType, capturedAt, notes in
                viewModel.addPhoto(data: data, poseType: poseType, capturedAt: capturedAt, notes: notes)
            }
        }
    }

    // MARK: - Step navigator

    private var stepNavigator: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.xs) {
                ForEach(viewModel.activeSteps) { step in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.currentStep = step
                        }
                    } label: {
                        stepPill(step)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppSpacing.base)
            .padding(.vertical, AppSpacing.sm)
        }
    }

    private func stepPill(_ step: CheckInWorkflowStep) -> some View {
        let isActive = viewModel.currentStep == step
        let filled   = viewModel.isFilled(step)

        return HStack(spacing: 4) {
            Image(systemName: filled ? "checkmark.circle.fill" : step.icon)
                .font(.caption2)
                .foregroundStyle(
                    filled  ? AppColors.success :
                    isActive ? Color.accentColor : AppColors.tertiaryText
                )
            Text(step.title)
                .font(.caption.weight(isActive ? .semibold : .regular))
                .foregroundStyle(isActive ? Color.accentColor : AppColors.secondaryText)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            isActive ? Color.accentColor.opacity(0.12) : Color.secondary.opacity(0.07),
            in: Capsule()
        )
    }

    // MARK: - Step content

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case .metricas:        metricasStep
        case .circunferencias: circunferenciasStep
        case .plicometria:     plicometriaStep
        case .diametros:       diametrosStep
        case .longitudes:      longitudesStep
        case .fotos:           fotosStep
        case .notas:           notasStep
        case .revision:        revisionStep
        }
    }

    // MARK: - Navigation footer

    private var navigationFooter: some View {
        HStack(spacing: AppSpacing.md) {
            if !viewModel.isFirstStep {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { viewModel.goPrevious() }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Anterior")
                    }
                }
                .buttonStyle(.bordered)
            }

            Spacer()

            if viewModel.isRevision {
                Button {
                    viewModel.save(context: context)
                } label: {
                    if viewModel.isSaving {
                        HStack(spacing: AppSpacing.sm) {
                            ProgressView().controlSize(.small)
                            Text("Guardando…")
                        }
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Guardar Check In")
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isSaving)
            } else {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { viewModel.goNext() }
                } label: {
                    HStack(spacing: 4) {
                        Text("Siguiente")
                        Image(systemName: "chevron.right")
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.horizontal, AppSpacing.base)
        .padding(.vertical, AppSpacing.md)
    }

    // MARK: - Métricas step

    private var metricasStep: some View {
        Form {
            // Profile selector — always shown at top of Métricas
            Section {
                ForEach(AnthropometryProfile.allCases, id: \.self) { profile in
                    Button {
                        viewModel.anthropometryProfile = profile
                    } label: {
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: profile.icon)
                                .frame(width: 24)
                                .foregroundStyle(Color.accentColor)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(profile.displayName)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.primary)
                                Text(profile.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if viewModel.anthropometryProfile == profile {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.accentColor)
                                    .font(.subheadline.weight(.semibold))
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Label("Perfil de Antropometría", systemImage: "person.crop.rectangle")
            }

            Section {
                WorkflowMetricRow(label: "Peso", text: $viewModel.bodyMetrics.weightText, unit: fmt.weightLabel)
                HStack {
                    Text("IMC")
                    Spacer()
                    Text(viewModel.bodyMetrics.bmiFormatted).foregroundStyle(.secondary)
                    if viewModel.bodyMetrics.bmi != nil {
                        Text("kg/m²").font(.caption).foregroundStyle(.secondary)
                    }
                }
                HStack {
                    Text("Estatura (referencia)")
                    Spacer()
                    Text(viewModel.bodyMetrics.heightFormatted).foregroundStyle(.secondary)
                }
            } header: {
                Text("Peso Corporal")
            } footer: {
                Text("El IMC se calcula automáticamente con la estatura registrada del atleta.")
            }

            if viewModel.anthropometryProfile.isISAK {
                Section {
                    WorkflowMetricRow(label: "Talla sentada", text: $viewModel.bodyMetrics.sittingHeightText, unit: "cm")
                    WorkflowMetricRow(label: "Envergadura",   text: $viewModel.bodyMetrics.armSpanText,       unit: "cm")
                } header: {
                    Label("Medidas Base ISAK", systemImage: "ruler")
                } footer: {
                    Text("Requeridas por el protocolo ISAK Nivel 1 y Nivel 2.")
                }
            }

            Section("Composición Corporal") {
                WorkflowMetricRow(label: "% Grasa corporal", text: $viewModel.bodyMetrics.fatPercentageText,    unit: "%")
                WorkflowMetricRow(label: "Masa muscular",    text: $viewModel.bodyMetrics.muscleMassText,        unit: fmt.weightLabel)
                WorkflowMetricRow(label: "Agua corporal",    text: $viewModel.bodyMetrics.waterPercentageText,   unit: "%")
                WorkflowMetricRow(label: "Masa ósea",        text: $viewModel.bodyMetrics.boneMassText,          unit: fmt.weightLabel)
            }

            Section("Otros") {
                WorkflowMetricRow(label: "Grasa visceral",    text: $viewModel.bodyMetrics.visceralFatText,        unit: "nivel")
                WorkflowMetricRow(label: "Metabolismo basal", text: $viewModel.bodyMetrics.basalMetabolicRateText, unit: "kcal")
            }
        }
    }

    // MARK: - Circunferencias step

    private var circunferenciasStep: some View {
        Form {
            Section("Torso") {
                WorkflowMetricRow(label: "Cuello",  text: $viewModel.circumferences.neckText,      unit: fmt.lengthLabel)
                WorkflowMetricRow(label: "Hombros", text: $viewModel.circumferences.shouldersText,  unit: fmt.lengthLabel)
                WorkflowMetricRow(label: "Pecho",   text: $viewModel.circumferences.chestText,      unit: fmt.lengthLabel)
            }
            Section("Brazos") {
                WorkflowMetricRow(label: "Brazo derecho",       text: $viewModel.circumferences.rightArmText,     unit: fmt.lengthLabel)
                WorkflowMetricRow(label: "Brazo izquierdo",     text: $viewModel.circumferences.leftArmText,      unit: fmt.lengthLabel)
                if viewModel.anthropometryProfile.isISAK {
                    WorkflowMetricRow(label: "Brazo contraído (máx.)", text: $viewModel.circumferences.armFlexedTensedText, unit: fmt.lengthLabel)
                }
                WorkflowMetricRow(label: "Antebrazo derecho",   text: $viewModel.circumferences.rightForearmText, unit: fmt.lengthLabel)
                WorkflowMetricRow(label: "Antebrazo izquierdo", text: $viewModel.circumferences.leftForearmText,  unit: fmt.lengthLabel)
            }
            Section("Tronco") {
                WorkflowMetricRow(label: "Cintura",          text: $viewModel.circumferences.waistText,   unit: fmt.lengthLabel)
                WorkflowMetricRow(label: "Abdomen",          text: $viewModel.circumferences.abdomenText, unit: fmt.lengthLabel)
                WorkflowMetricRow(label: "Cadera / Glúteos", text: $viewModel.circumferences.hipsText,    unit: fmt.lengthLabel)
            }
            Section("Piernas") {
                WorkflowMetricRow(label: "Muslo derecho",         text: $viewModel.circumferences.rightThighText, unit: fmt.lengthLabel)
                WorkflowMetricRow(label: "Muslo izquierdo",       text: $viewModel.circumferences.leftThighText,  unit: fmt.lengthLabel)
                WorkflowMetricRow(label: "Pantorrilla derecha",   text: $viewModel.circumferences.rightCalfText,  unit: fmt.lengthLabel)
                WorkflowMetricRow(label: "Pantorrilla izquierda", text: $viewModel.circumferences.leftCalfText,   unit: fmt.lengthLabel)
            }

            if viewModel.anthropometryProfile.isFullProfile {
                Section {
                    WorkflowMetricRow(label: "Perímetro cefálico", text: $viewModel.circumferences.headGirthText,     unit: fmt.lengthLabel)
                    WorkflowMetricRow(label: "Muñeca",             text: $viewModel.circumferences.wristGirthText,    unit: fmt.lengthLabel)
                    WorkflowMetricRow(label: "Tobillo",            text: $viewModel.circumferences.ankleGirthText,    unit: fmt.lengthLabel)
                    WorkflowMetricRow(label: "Muslo medio",        text: $viewModel.circumferences.midThighGirthText, unit: fmt.lengthLabel)
                } header: {
                    Label("Perímetros adicionales ISAK N2", systemImage: "plus.circle")
                } footer: {
                    Text("Requeridos por el Perfil Completo ISAK Nivel 2.")
                }
            }
        }
    }

    // MARK: - Plicometría step

    private var plicometriaStep: some View {
        Form {
            if viewModel.anthropometryProfile.isISAK {
                Section {
                    Label("Protocolo ISAK · 8 sitios estandarizados", systemImage: "info.circle")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } header: {
                    Label("Pliegues ISAK", systemImage: "ruler.fill")
                } footer: {
                    Text("Los 8 sitios ISAK son independientes del método de cálculo de composición corporal seleccionado abajo.")
                }

                Section("Sitios ISAK (mm)") {
                    ForEach(viewModel.skinfolds.requiredISAKSiteLabels, id: \.label) { site in
                        WorkflowSkinfoldRow(label: site.label, text: skinfoldBinding(site.binding))
                    }
                }

                if viewModel.skinfolds.filledISAKSiteCount > 0 {
                    Section {
                        HStack {
                            Text("Sitios completados")
                            Spacer()
                            Text("\(viewModel.skinfolds.filledISAKSiteCount) / 8")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    Toggle("Calcular % grasa con fórmula adicional", isOn: .constant(false))
                        .disabled(true)
                        .foregroundStyle(.secondary)
                } footer: {
                    Text("La selección de método de cálculo de composición corporal para perfiles ISAK estará disponible en una próxima fase.")
                        .font(.caption2)
                }
            } else {
                Section("Método") {
                    Picker("Protocolo", selection: $viewModel.skinfolds.method) {
                        ForEach(PlicometryMethod.allCases.filter { $0 != .custom }, id: \.self) { m in
                            Text(m.displayName).tag(m)
                        }
                    }
                    .pickerStyle(.menu)

                    if viewModel.skinfolds.method == .parrillo {
                        if let w = viewModel.bodyMetrics.weightText.asPositiveDouble {
                            Label(String(format: "Peso: %.2f \(fmt.weightLabel) (de Métricas)", w), systemImage: "info.circle")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        } else {
                            Label("Parrillo requiere peso corporal. Ingrésalo en Métricas.", systemImage: "exclamationmark.triangle.fill")
                                .font(.footnote)
                                .foregroundStyle(.orange)
                        }
                    }
                }

                Section("Pliegues cutáneos (mm)") {
                    ForEach(viewModel.skinfolds.requiredSiteLabels, id: \.label) { site in
                        WorkflowSkinfoldRow(label: site.label, text: skinfoldBinding(site.binding))
                    }
                }

                if let result = viewModel.skinfolds.calculationResult {
                    Section {
                        HStack {
                            Text("% Grasa corporal").fontWeight(.semibold)
                            Spacer()
                            Text(String(format: "%.1f %%", result.bodyFatPercentage))
                                .font(.title3.bold())
                                .foregroundStyle(fatColor(result.bodyFatPercentage))
                        }
                        HStack {
                            Text("Densidad corporal")
                            Spacer()
                            Text(String(format: "%.4f g/mL", result.bodyDensity))
                                .foregroundStyle(.secondary)
                        }
                    } header: {
                        Label("Resultado calculado", systemImage: "chart.bar.fill")
                    } footer: {
                        Text("Calculado con \(viewModel.skinfolds.method.displayName) · Fórmula de Siri (1956)")
                            .font(.caption2)
                    }
                }
            }

            Section("Datos del evaluador (opcional)") {
                HStack {
                    Text("Evaluador")
                    Spacer()
                    TextField("Nombre", text: $viewModel.skinfolds.testerText)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Plicómetro")
                    Spacer()
                    TextField("Marca / modelo", text: $viewModel.skinfolds.caliperBrandText)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Diámetros step (ISAK breadths/depths)

    private var diametrosStep: some View {
        Form {
            Section {
                Label("Valores en centímetros (cm)", systemImage: "info.circle")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } header: {
                Label("Diámetros ISAK Nivel 1", systemImage: "arrow.left.and.right")
            } footer: {
                Text("3 diámetros del Perfil Restringido ISAK.")
            }

            Section("Diámetros Nivel 1 (cm)") {
                WorkflowMetricRow(label: "Diám. biepicondilar húmero", text: $viewModel.extended.humerusText, unit: "cm")
                WorkflowMetricRow(label: "Diám. biepicondilar fémur",  text: $viewModel.extended.femurText,   unit: "cm")
                WorkflowMetricRow(label: "Anchura del pie",            text: $viewModel.extended.footText,    unit: "cm")
            }

            if viewModel.anthropometryProfile.isFullProfile {
                Section {
                    WorkflowMetricRow(label: "Diám. biacromial",             text: $viewModel.extended.biacromialText,      unit: "cm")
                    WorkflowMetricRow(label: "Diám. bicristal",               text: $viewModel.extended.bicristalText,       unit: "cm")
                    WorkflowMetricRow(label: "Diám. torácico transverso",     text: $viewModel.extended.chestTransverseText, unit: "cm")
                    WorkflowMetricRow(label: "Prof. torácica anteroposterior",text: $viewModel.extended.chestDepthText,      unit: "cm")
                    WorkflowMetricRow(label: "Diám. biepicondilar tobillo",   text: $viewModel.extended.ankleText,           unit: "cm")
                    WorkflowMetricRow(label: "Diám. biepicondilar muñeca",    text: $viewModel.extended.wristBreadthText,    unit: "cm")
                } header: {
                    Label("Diámetros adicionales Nivel 2", systemImage: "plus.circle")
                } footer: {
                    Text("6 diámetros/profundidades adicionales del Perfil Completo ISAK.")
                }
            }

            let l1Count = viewModel.extended.filledLevel1BreadthCount
            if l1Count > 0 {
                Section {
                    HStack {
                        Text("Diámetros N1 completados")
                        Spacer()
                        Text("\(l1Count) / 3").foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Longitudes step (ISAK Level 2 only)

    private var longitudesStep: some View {
        Form {
            Section {
                Label("Longitudes y alturas en cm · Perfil Completo ISAK Nivel 2", systemImage: "info.circle")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } header: {
                Label("Longitudes y Alturas ISAK N2", systemImage: "arrow.up.and.down.circle")
            }

            Section("Longitudes de segmentos (cm)") {
                WorkflowMetricRow(label: "Long. acromial-radial",           text: $viewModel.extended.acromialeRadialeText,    unit: "cm")
                WorkflowMetricRow(label: "Long. radial-estilión",           text: $viewModel.extended.radialeStylionText,      unit: "cm")
                WorkflowMetricRow(label: "Long. medioestilión-dactilión",   text: $viewModel.extended.midstylionDactylionText, unit: "cm")
                WorkflowMetricRow(label: "Long. trocánterea-tibial lat.",   text: $viewModel.extended.trochTibLatText,         unit: "cm")
                WorkflowMetricRow(label: "Long. tibial lat.-sfirión tibial",text: $viewModel.extended.tibSphyrionText,         unit: "cm")
                WorkflowMetricRow(label: "Longitud del pie",                text: $viewModel.extended.footLengthText,          unit: "cm")
            }

            Section("Alturas desde el suelo (cm)") {
                WorkflowMetricRow(label: "Altura ilioespinal",  text: $viewModel.extended.iliospinaleHeightText,     unit: "cm")
                WorkflowMetricRow(label: "Altura trocantérea",  text: $viewModel.extended.trochanterionHeightText,   unit: "cm")
                WorkflowMetricRow(label: "Altura tibial lateral",text: $viewModel.extended.tibialeLateraleHeightText,unit: "cm")
            }

            let lenCount = viewModel.extended.filledLengthCount
            if lenCount > 0 {
                Section {
                    HStack {
                        Text("Longitudes/alturas completadas")
                        Spacer()
                        Text("\(lenCount) / 9").foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Fotos step

    private var fotosStep: some View {
        Group {
            if viewModel.photoDrafts.isEmpty {
                ContentUnavailableView {
                    Label("Sin fotografías", systemImage: "camera")
                } description: {
                    Text("Añade fotos de posing para este check-in.")
                } actions: {
                    Button {
                        viewModel.isShowingPhotoForm = true
                    } label: {
                        Label("Añadir foto", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                ScrollView {
                    LazyVGrid(
                        columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                        spacing: AppSpacing.sm
                    ) {
                        ForEach(viewModel.photoDrafts) { draft in
                            photoDraftCell(draft)
                        }
                        if viewModel.canAddPhoto {
                            addPhotoCell
                        }
                    }
                    .padding(.horizontal, AppSpacing.base)
                    .padding(.vertical, AppSpacing.base)
                }
            }
        }
    }

    private var addPhotoCell: some View {
        Button {
            viewModel.isShowingPhotoForm = true
        } label: {
            RoundedRectangle(cornerRadius: AppRadius.md)
                .fill(Color.secondary.opacity(0.10))
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    VStack(spacing: AppSpacing.xs) {
                        Image(systemName: "plus").font(.title3)
                        Text("Añadir").font(.caption2)
                    }
                    .foregroundStyle(Color.accentColor)
                }
        }
        .buttonStyle(.plain)
    }

    private func photoDraftCell(_ draft: PhotoDraft) -> some View {
        ZStack(alignment: .topTrailing) {
            photoDraftImage(draft)
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                .overlay(alignment: .bottom) {
                    Text(draft.poseType.displayName)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(.black.opacity(0.55))
                        .clipShape(Capsule())
                        .padding(4)
                }

            Button {
                viewModel.removePhoto(id: draft.id)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.4), radius: 2)
            }
            .buttonStyle(.plain)
            .padding(4)
        }
    }

    @ViewBuilder
    private func photoDraftImage(_ draft: PhotoDraft) -> some View {
        #if os(iOS)
        if let img = UIImage(data: draft.data) {
            Image(uiImage: img).resizable().scaledToFill()
        } else {
            Color.secondary.opacity(0.2)
        }
        #elseif os(macOS)
        if let img = NSImage(data: draft.data) {
            Image(nsImage: img).resizable().scaledToFill()
        } else {
            Color.secondary.opacity(0.2)
        }
        #endif
    }

    // MARK: - Notas step

    private var notasStep: some View {
        Form {
            Section {
                TextEditor(text: $viewModel.coachNoteText)
                    .frame(minHeight: 100)
            } header: {
                Text("Nota del Coach")
            } footer: {
                Text("Observaciones del entrenador sobre este check-in.")
            }

            Section {
                TextEditor(text: $viewModel.athleteNoteText)
                    .frame(minHeight: 100)
            } header: {
                Text("Nota del Atleta")
            } footer: {
                Text("Comentarios o sensaciones del atleta.")
            }
        }
    }

    // MARK: - Revisión step

    private var revisionStep: some View {
        Form {
            Section("Check-In") {
                revisionInfoRow(label: "Atleta", value: viewModel.athlete.name)
                revisionInfoRow(
                    label: "Fecha",
                    value: viewModel.date.formatted(.dateTime.day().month(.abbreviated).year())
                )
                revisionInfoRow(label: "Perfil", value: viewModel.anthropometryProfile.displayName)
                if viewModel.anthropometryProfile.isISAK {
                    revisionInfoRow(label: "Protocolo", value: viewModel.anthropometryProfile.reviewLabel)
                }
            }

            Section("Datos registrados") {
                revisionCheckRow(
                    label: "Métricas corporales",
                    filled: viewModel.hasBodyMetrics,
                    detail: viewModel.hasBodyMetrics ? viewModel.bodyMetrics.weightText + " \(fmt.weightLabel)" : nil
                )
                if viewModel.anthropometryProfile.isISAK {
                    let hasSittingH = viewModel.bodyMetrics.sittingHeightText.asPositiveDouble != nil
                    revisionCheckRow(label: "Medidas base ISAK", filled: hasSittingH, detail: nil)
                }
                revisionCheckRow(label: "Circunferencias", filled: viewModel.hasCircumferences, detail: nil)
                revisionCheckRow(
                    label: viewModel.anthropometryProfile.isISAK ? "Pliegues ISAK" : "Plicometría",
                    filled: viewModel.anthropometryProfile.isISAK ? viewModel.hasISAKSkinfolds : viewModel.hasSkinfolds,
                    detail: viewModel.anthropometryProfile.isISAK
                        ? (viewModel.skinfolds.filledISAKSiteCount > 0 ? "\(viewModel.skinfolds.filledISAKSiteCount)/8 sitios" : nil)
                        : viewModel.skinfolds.calculationResult.map { String(format: "%.1f %%", $0.bodyFatPercentage) }
                )
                if viewModel.anthropometryProfile.isISAK {
                    revisionCheckRow(
                        label: "Diámetros",
                        filled: viewModel.extended.hasBreadths,
                        detail: viewModel.extended.hasBreadths
                            ? "\(viewModel.extended.filledLevel1BreadthCount)/3 N1" : nil
                    )
                }
                if viewModel.anthropometryProfile.isFullProfile {
                    revisionCheckRow(
                        label: "Longitudes",
                        filled: viewModel.extended.hasLengths,
                        detail: viewModel.extended.hasLengths
                            ? "\(viewModel.extended.filledLengthCount)/9 sitios" : nil
                    )
                }
                revisionCheckRow(
                    label: "Fotografías",
                    filled: viewModel.hasPhotos,
                    detail: viewModel.hasPhotos
                        ? "\(viewModel.photoDrafts.count) foto\(viewModel.photoDrafts.count == 1 ? "" : "s")"
                        : nil
                )
                revisionCheckRow(label: "Notas", filled: viewModel.hasNotes, detail: nil)
            }

            if viewModel.anthropometryProfile.isISAK {
                Section {
                    HStack {
                        Text("Medidas completadas")
                        Spacer()
                        Text(viewModel.isakCompletionSummary)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if !viewModel.hasBodyMetrics {
                Section {
                    Label(
                        "El peso corporal es el dato más importante de un check-in. Considera añadirlo antes de guardar.",
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .font(.footnote)
                    .foregroundStyle(.orange)
                }
            }
        }
    }

    // MARK: - Shared row components

    private func revisionInfoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value).foregroundStyle(.secondary)
        }
    }

    private func revisionCheckRow(label: String, filled: Bool, detail: String?) -> some View {
        HStack {
            Image(systemName: filled ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(filled ? AppColors.success : AppColors.tertiaryText)
            Text(label)
            Spacer()
            if let detail {
                Text(detail).foregroundStyle(.secondary).font(.subheadline)
            } else if !filled {
                Text("Sin datos").foregroundStyle(.tertiary).font(.caption)
            }
        }
    }

    // MARK: - Helpers

    private func skinfoldBinding(
        _ keyPath: WritableKeyPath<SkinfoldMeasurementsViewModel, String>
    ) -> Binding<String> {
        Binding(
            get: { viewModel.skinfolds[keyPath: keyPath] },
            set: { viewModel.skinfolds[keyPath: keyPath] = $0 }
        )
    }

    private func fatColor(_ fat: Double) -> Color {
        switch fat {
        case ..<10:   return .blue
        case 10..<18: return .green
        case 18..<25: return .yellow
        case 25..<32: return .orange
        default:      return .red
        }
    }
}

// MARK: - Reusable input rows

private struct WorkflowMetricRow: View {
    let label: String
    @Binding var text: String
    let unit: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            TextField("0", text: $text)
                #if os(iOS)
                .keyboardType(.decimalPad)
                #endif
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
            Text(unit)
                .foregroundStyle(.secondary)
                .frame(width: 42, alignment: .leading)
        }
    }
}

private struct WorkflowSkinfoldRow: View {
    let label: String
    @Binding var text: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            TextField("0.0", text: $text)
                #if os(iOS)
                .keyboardType(.decimalPad)
                #endif
                .multilineTextAlignment(.trailing)
                .frame(width: 64)
            Text("mm")
                .foregroundStyle(.secondary)
                .frame(width: 28, alignment: .leading)
        }
    }
}

// MARK: - Preview

#Preview("iPhone 16") {
    let athlete = Athlete(name: "Carlos Ramírez", gender: .male, birthDate: Calendar.current.date(byAdding: .year, value: -28, to: Date()), height: 178)
    CheckInWorkflowView(athlete: athlete)
        .modelContainer(for: [
            Athlete.self, CheckIn.self, BodyMetrics.self,
            CircumferenceMeasurements.self, SkinfoldMeasurements.self,
            ISAKBreadthsMeasurements.self, ISAKLengthsMeasurements.self,
            ProgressPhoto.self, CoachNote.self, AthleteNote.self
        ], inMemory: true)
}
