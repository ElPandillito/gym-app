//
//  ProgressPhotoForm.swift
//  GYM APP
//

import SwiftUI
import PhotosUI

#if os(macOS)
import UniformTypeIdentifiers
#endif

struct ProgressPhotoForm: View {
    let storage: PhotoStorageServiceProtocol
    let onSave: (Data, PoseType, Date, String?) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var poseType: PoseType = .frontRelaxed
    @State private var capturedAt: Date   = .now
    @State private var notes: String      = ""
    @State private var selectedData: Data?
    @State private var previewImage: PlatformImage?
    @State private var selectedItem: PhotosPickerItem?
    @State private var isLoadingImage = false
    @State private var isDropTargeted = false

    #if os(iOS)
    @State private var showCamera = false
    #endif

    private var canSave: Bool { selectedData != nil }

    var body: some View {
        NavigationStack {
            Form {
                imageSection
                detailsSection
            }
            .navigationTitle("Nueva Foto")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { save() }
                        .disabled(!canSave)
                        .fontWeight(.semibold)
                }
            }
            #if os(iOS)
            .sheet(isPresented: $showCamera) {
                CameraPickerView { image in
                    applyUIImage(image)
                    showCamera = false
                }
                .ignoresSafeArea()
            }
            #endif
        }
        .onChange(of: selectedItem) { _, newItem in
            loadPickerItem(newItem)
        }
    }

    // MARK: - Sections

    private var imageSection: some View {
        Section {
            VStack(spacing: AppSpacing.md) {
                imagePreview
                sourceButtons
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
                .frame(height: 240)
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.lg)
                        .strokeBorder(
                            isDropTargeted ? Color.accentColor : Color.clear,
                            style: StrokeStyle(lineWidth: 2, dash: [6])
                        )
                }

            if let img = previewImage {
                #if os(iOS)
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 240)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                #elseif os(macOS)
                Image(nsImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 240)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                #endif
            } else if isLoadingImage {
                ProgressView()
                    .tint(.secondary)
            } else {
                VStack(spacing: AppSpacing.sm) {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 44, weight: .light))
                        .foregroundStyle(.tertiary)
                    Text("Selecciona una imagen")
                        .font(AppTypography.subheadline)
                        .foregroundStyle(.secondary)
                    #if os(macOS)
                    Text("o arrastra aquí")
                        .font(AppTypography.caption)
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

    private var sourceButtons: some View {
        HStack(spacing: AppSpacing.sm) {
            PhotosPicker(selection: $selectedItem, matching: .images) {
                Label("Galería", systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            #if os(iOS)
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button {
                    showCamera = true
                } label: {
                    Label("Cámara", systemImage: "camera")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            #endif
        }
    }

    private var detailsSection: some View {
        Section("Detalles") {
            Picker("Pose", selection: $poseType) {
                ForEach(PoseType.allCases, id: \.self) { pose in
                    Label(pose.displayName, systemImage: pose.sfSymbol).tag(pose)
                }
            }

            DatePicker(
                "Fecha",
                selection: $capturedAt,
                in: ...Date.now,
                displayedComponents: [.date]
            )

            TextField("Notas (opcional)", text: $notes, axis: .vertical)
                .lineLimit(3...6)
        }
    }

    // MARK: - Actions

    private func save() {
        guard let data = selectedData else { return }
        onSave(data, poseType, capturedAt, notes.nilIfBlank)
        dismiss()
    }

    private func loadPickerItem(_ item: PhotosPickerItem?) {
        guard let item else { return }
        isLoadingImage = true
        Task {
            defer { isLoadingImage = false }
            guard let data = try? await item.loadTransferable(type: Data.self) else { return }
            await MainActor.run {
                selectedData = data
                #if os(iOS)
                previewImage = UIImage(data: data)
                #elseif os(macOS)
                previewImage = NSImage(data: data)
                #endif
            }
        }
    }

    #if os(iOS)
    private func applyUIImage(_ image: UIImage) {
        selectedData = image.jpegData(compressionQuality: 0.85)
        previewImage = image
    }
    #endif

    #if os(macOS)
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        if provider.hasItemConformingToTypeIdentifier("public.image") {
            _ = provider.loadDataRepresentation(forTypeIdentifier: "public.image") { data, _ in
                guard let data, let image = NSImage(data: data) else { return }
                DispatchQueue.main.async {
                    selectedData = data
                    previewImage = image
                }
            }
        } else if provider.hasItemConformingToTypeIdentifier("public.file-url") {
            _ = provider.loadDataRepresentation(forTypeIdentifier: "public.file-url") { data, _ in
                guard let data,
                      let url = URL(dataRepresentation: data, relativeTo: nil, isAbsolute: true),
                      let imageData = try? Data(contentsOf: url),
                      let image = NSImage(data: imageData) else { return }
                DispatchQueue.main.async {
                    selectedData = imageData
                    previewImage = image
                }
            }
        }
        return true
    }
    #endif
}

// MARK: - Camera (iOS only)

#if os(iOS)
import UIKit

private struct CameraPickerView: UIViewControllerRepresentable {
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
        let parent: CameraPickerView
        init(_ parent: CameraPickerView) { self.parent = parent }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.onCapture(image)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
#endif
