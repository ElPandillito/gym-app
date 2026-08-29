//
//  PreparedFoodFormView.swift
//  GYM APP
//

import SwiftUI
import SwiftData
import PhotosUI

#if os(macOS)
import UniformTypeIdentifiers
#endif

struct PreparedFoodFormView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: PreparedFoodFormViewModel
    @State private var selectedItem: PhotosPickerItem?
    @State private var isLoadingImage = false
    @State private var isDropTargeted = false
    @State private var isShowingPicker = false
    @State private var repositoryError: String?

    #if os(iOS)
    @State private var showCamera = false
    #endif

    init(mode: PreparedFoodFormViewModel.Mode, context: ModelContext) {
        _viewModel = State(initialValue: PreparedFoodFormViewModel(mode: mode, context: context))
    }

    var body: some View {
        NavigationStack {
            Form {
                imageSection
                infoSection
                ingredientsSection
                nutritionSummarySection
                servingsSection
            }
            .navigationTitle(viewModel.isEditing ? "Editar platillo" : "Nuevo platillo")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { handleSave() }
                        .disabled(!viewModel.canSave)
                        .fontWeight(.semibold)
                }
            }
            #if os(iOS)
            .sheet(isPresented: $showCamera) {
                RecipeCameraPickerView { image in
                    if let data = image.jpegData(compressionQuality: 0.85) {
                        viewModel.applyImageData(data)
                    }
                    showCamera = false
                }
                .ignoresSafeArea()
            }
            #endif
            .sheet(isPresented: $isShowingPicker) {
                RecipeIngredientPickerView { food, amountGrams in
                    viewModel.addIngredient(food, amountGrams: amountGrams)
                }
            }
            .alert("Error al guardar", isPresented: Binding(
                get: { repositoryError != nil },
                set: { if !$0 { repositoryError = nil } }
            )) {
                Button("Aceptar", role: .cancel) {}
            } message: {
                Text(repositoryError ?? "")
            }
        }
        .onChange(of: selectedItem) { _, newItem in
            loadPickerItem(newItem)
        }
    }

    // MARK: - Image Section

    private var imageSection: some View {
        Section {
            VStack(spacing: AppSpacing.md) {
                imagePreview
                imageSourceButtons

                if viewModel.hasExistingImage || viewModel.pendingImageData != nil {
                    Button(role: .destructive) {
                        viewModel.removeImage()
                    } label: {
                        Label("Eliminar imagen", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .listRowInsets(EdgeInsets(
                top: AppSpacing.md,
                leading: AppSpacing.base,
                bottom: AppSpacing.md,
                trailing: AppSpacing.base
            ))
        }
    }

    private var imagePreview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .fill(isDropTargeted
                      ? Color.accentColor.opacity(0.15)
                      : Color.secondary.opacity(0.10))
                .frame(height: 200)
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.lg)
                        .strokeBorder(
                            isDropTargeted ? Color.accentColor : Color.clear,
                            style: StrokeStyle(lineWidth: 2, dash: [6])
                        )
                }

            if let img = viewModel.previewImage {
                #if os(iOS)
                Image(uiImage: img)
                    .resizable().scaledToFill()
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                #elseif os(macOS)
                Image(nsImage: img)
                    .resizable().scaledToFill()
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                #endif
            } else if isLoadingImage {
                ProgressView().tint(.secondary)
            } else {
                VStack(spacing: AppSpacing.sm) {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(.tertiary)
                    Text("Foto del platillo (opcional)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    #if os(macOS)
                    Text("o arrastra aquí")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    #endif
                }
            }
        }
        #if os(macOS)
        .onDrop(of: ["public.image", "public.file-url"], isTargeted: $isDropTargeted) { providers in
            handleDrop(providers: providers)
        }
        #endif
    }

    private var imageSourceButtons: some View {
        HStack(spacing: AppSpacing.sm) {
            PhotosPicker(selection: $selectedItem, matching: .images) {
                Label("Galería", systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            #if os(iOS)
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button { showCamera = true } label: {
                    Label("Cámara", systemImage: "camera")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            #endif
        }
    }

    // MARK: - Info Section

    private var infoSection: some View {
        Section("Información") {
            TextField("Nombre del platillo *", text: $viewModel.name)

            Picker("Categoría", selection: $viewModel.category) {
                ForEach(FoodCategory.all, id: \.rawValue) { cat in
                    Text(cat.displayName).tag(cat)
                }
            }

            TextField("Marca (opcional)", text: $viewModel.brand)
            TextField("Etiquetas (separadas por coma)", text: $viewModel.tagsText)
        }
    }

    // MARK: - Ingredients Section

    private var ingredientsSection: some View {
        Section {
            if viewModel.pendingIngredients.isEmpty {
                Text("Ningún ingrediente todavía")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, AppSpacing.sm)
            } else {
                ForEach(viewModel.pendingIngredients) { entry in
                    IngredientFormRow(
                        entry: entry,
                        onAmountChange: { grams in
                            viewModel.updateAmount(for: entry.id, amountGrams: grams)
                        }
                    )
                }
                .onDelete { offsets in
                    viewModel.removeIngredients(at: offsets)
                }
                .onMove { from, to in
                    viewModel.move(fromOffsets: from, toOffset: to)
                }
            }

            Button {
                isShowingPicker = true
            } label: {
                Label("Agregar ingrediente", systemImage: "plus")
            }

            if !viewModel.validationErrors.isEmpty {
                ForEach(viewModel.validationErrors, id: \.self) { error in
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        } header: {
            HStack {
                Text("Ingredientes")
                Spacer()
                #if os(iOS)
                if !viewModel.pendingIngredients.isEmpty {
                    EditButton()
                        .font(.caption)
                }
                #endif
            }
        }
    }

    // MARK: - Nutrition Summary Section

    private var nutritionSummarySection: some View {
        Section("Total receta") {
            macroRow(label: "Calorías", value: viewModel.totalMacros.calories, unit: "kcal")
            macroRow(label: "Proteína", value: viewModel.totalMacros.protein, unit: "g")
            macroRow(label: "Carbohidratos", value: viewModel.totalMacros.carbohydrates, unit: "g")
            macroRow(label: "Grasa", value: viewModel.totalMacros.fat, unit: "g")
            macroRow(label: "Fibra", value: viewModel.totalMacros.fiber, unit: "g")
        }
    }

    private func macroRow(label: String, value: Double, unit: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(String(format: value.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f %@" : "%.1f %@", value, unit))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Servings Section

    private var servingsSection: some View {
        Section {
            Stepper(value: $viewModel.servings, in: 1...99) {
                HStack {
                    Text("Porciones")
                    Spacer()
                    Text("\(viewModel.servings)")
                        .foregroundStyle(.secondary)
                        .fontWeight(.medium)
                }
            }

            HStack {
                Text("Calorías / porción")
                Spacer()
                Text(String(format: "%.0f kcal", viewModel.perServingMacros.calories))
                    .foregroundStyle(.secondary)
                    .fontWeight(.medium)
            }

            macroRow(label: "Proteína / porción", value: viewModel.perServingMacros.protein, unit: "g")
            macroRow(label: "Carbohidratos / porción", value: viewModel.perServingMacros.carbohydrates, unit: "g")
            macroRow(label: "Grasa / porción", value: viewModel.perServingMacros.fat, unit: "g")
        } header: {
            Text("Porciones")
        }
    }

    // MARK: - Actions

    private func handleSave() {
        do {
            try viewModel.save()
            if viewModel.validationErrors.isEmpty {
                dismiss()
            }
        } catch {
            repositoryError = error.localizedDescription
        }
    }

    private func loadPickerItem(_ item: PhotosPickerItem?) {
        guard let item else { return }
        isLoadingImage = true
        Task {
            defer { isLoadingImage = false }
            guard let data = try? await item.loadTransferable(type: Data.self) else { return }
            await MainActor.run { viewModel.applyImageData(data) }
        }
    }

    #if os(macOS)
    @discardableResult
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        if provider.hasItemConformingToTypeIdentifier("public.image") {
            _ = provider.loadDataRepresentation(forTypeIdentifier: "public.image") { data, _ in
                guard let data else { return }
                DispatchQueue.main.async { viewModel.applyImageData(data) }
            }
        } else if provider.hasItemConformingToTypeIdentifier("public.file-url") {
            _ = provider.loadDataRepresentation(forTypeIdentifier: "public.file-url") { data, _ in
                guard let data,
                      let url = URL(dataRepresentation: data, relativeTo: nil, isAbsolute: true),
                      let imageData = try? Data(contentsOf: url) else { return }
                DispatchQueue.main.async { viewModel.applyImageData(imageData) }
            }
        }
        return true
    }
    #endif
}

// MARK: - Ingredient Row (form)

private struct IngredientFormRow: View {
    let entry: PreparedFoodFormViewModel.IngredientEntry
    let onAmountChange: (Double) -> Void

    @State private var amountText: String = ""

    init(entry: PreparedFoodFormViewModel.IngredientEntry, onAmountChange: @escaping (Double) -> Void) {
        self.entry = entry
        self.onAmountChange = onAmountChange
        let g = entry.amountGrams
        _amountText = State(initialValue: g.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", g)
            : String(format: "%.1f", g))
    }

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.sm)
                    .fill(entry.food.category.color.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: entry.food.category.systemImage)
                    .font(.caption)
                    .foregroundStyle(entry.food.category.color)
            }

            Text(entry.food.name)
                .font(.subheadline)
                .lineLimit(1)

            Spacer()

            TextField("0", text: $amountText)
                #if os(iOS)
                .keyboardType(.decimalPad)
                #endif
                .multilineTextAlignment(.trailing)
                .frame(width: 60)
                .onChange(of: amountText) { _, val in
                    if let g = Double(val), g > 0 { onAmountChange(g) }
                }

            Text("g")
                .foregroundStyle(.secondary)
                .font(.subheadline)
        }
    }
}

// MARK: - Camera (iOS only)

#if os(iOS)
import UIKit

private struct RecipeCameraPickerView: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate   = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: RecipeCameraPickerView
        init(_ parent: RecipeCameraPickerView) { self.parent = parent }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage { parent.onCapture(image) }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
#endif
