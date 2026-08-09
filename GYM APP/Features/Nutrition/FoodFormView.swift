//
//  FoodFormView.swift
//  GYM APP
//

import SwiftUI
import SwiftData
import PhotosUI

#if os(macOS)
import UniformTypeIdentifiers
#endif

struct FoodFormView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: FoodFormViewModel
    @State private var selectedItem: PhotosPickerItem?
    @State private var isLoadingImage = false
    @State private var isDropTargeted = false
    @State private var repositoryError: String?

    #if os(iOS)
    @State private var showCamera = false
    #endif

    init(mode: FoodFormViewModel.Mode, context: ModelContext) {
        _viewModel = State(initialValue: FoodFormViewModel(mode: mode, context: context))
    }

    var body: some View {
        NavigationStack {
            Form {
                imageSection
                infoSection
                nutritionSection
                portionSection
            }
            .navigationTitle(viewModel.isEditing ? "Editar alimento" : "Nuevo alimento")
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
                FoodCameraPickerView { image in
                    if let data = image.jpegData(compressionQuality: 0.85) {
                        viewModel.applyImageData(data)
                    }
                    showCamera = false
                }
                .ignoresSafeArea()
            }
            #endif
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
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                #elseif os(macOS)
                Image(nsImage: img)
                    .resizable()
                    .scaledToFill()
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
                    Text("Imagen opcional")
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
            TextField("Nombre *", text: $viewModel.name)

            Picker("Tipo", selection: $viewModel.kind) {
                ForEach(FoodKind.allCases, id: \.self) { kind in
                    Text(kind.displayName).tag(kind)
                }
            }

            Picker("Categoría", selection: $viewModel.category) {
                ForEach(FoodCategory.all, id: \.rawValue) { cat in
                    Text(cat.displayName).tag(cat)
                }
            }

            TextField("Marca (opcional)", text: $viewModel.brand)

            TextField("Etiquetas (separadas por coma)", text: $viewModel.tagsText)
        }
    }

    // MARK: - Nutrition Section

    private var nutritionSection: some View {
        Section {
            macroRow(label: "Calorías (kcal)", text: $viewModel.caloriesText)
            macroRow(label: "Proteína (g)", text: $viewModel.proteinText)
            macroRow(label: "Carbohidratos (g)", text: $viewModel.carbsText)
            macroRow(label: "Grasa (g)", text: $viewModel.fatText)
            macroRow(label: "Fibra (g)", text: $viewModel.fiberText)

            if !viewModel.validationErrors.isEmpty {
                ForEach(viewModel.validationErrors, id: \.self) { error in
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        } header: {
            Text("Nutrición por 100 g")
        }
    }

    private func macroRow(label: String, text: Binding<String>) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 100)
        }
    }

    // MARK: - Portion Section

    private var portionSection: some View {
        Section("Porción de referencia") {
            Picker("Unidad", selection: $viewModel.servingUnit) {
                ForEach(FoodUnit.allCases, id: \.self) { unit in
                    Text(unit.displayName).tag(unit)
                }
            }

            if viewModel.servingUnit.requiresServingSize {
                HStack {
                    Text("Gramos por porción")
                    Spacer()
                    TextField("0", text: $viewModel.servingSizeText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 100)
                }
            }
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
            await MainActor.run {
                viewModel.applyImageData(data)
            }
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

// MARK: - Camera (iOS only)

#if os(iOS)
import UIKit

private struct FoodCameraPickerView: UIViewControllerRepresentable {
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
        let parent: FoodCameraPickerView
        init(_ parent: FoodCameraPickerView) { self.parent = parent }

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
