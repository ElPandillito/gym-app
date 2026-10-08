//
//  BarcodeScannerView.swift
//  GYM APP
//

#if os(iOS)
import AVFoundation
import SwiftData
import SwiftUI
import UIKit

struct BarcodeScannerView: View {
    let onResult: (BarcodeScanResult) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: BarcodeScannerViewModel?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let viewModel {
                CameraPreviewView(session: viewModel.captureSession)
                    .ignoresSafeArea()
                scanGuide
            }
        }
        .overlay(alignment: .topTrailing) { closeButton }
        .overlay(alignment: .bottom) { torchButton }
        .onAppear { setUpIfNeeded() }
        .onDisappear { viewModel?.stop() }
    }

    // MARK: - Setup

    private func setUpIfNeeded() {
        guard viewModel == nil else { return }
        let vm = BarcodeScannerViewModel(context: modelContext)
        vm.onResult = { result in
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            onResult(result)
        }
        viewModel = vm
        vm.start()
    }

    // MARK: - Overlay

    private var scanGuide: some View {
        RoundedRectangle(cornerRadius: AppRadius.lg)
            .strokeBorder(Color.white.opacity(0.9), lineWidth: 2)
            .frame(width: 260, height: 160)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .fill(Color.white.opacity(0.03))
            )
    }

    private var closeButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "xmark")
                .font(AppTypography.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(AppSpacing.sm)
                .background(.black.opacity(0.35), in: Circle())
        }
        .padding(AppSpacing.base)
    }

    private var torchButton: some View {
        Group {
            if let viewModel, viewModel.isTorchAvailable {
                Button { viewModel.toggleTorch() } label: {
                    Image(systemName: viewModel.isTorchOn ? "bolt.fill" : "bolt.slash.fill")
                        .font(AppTypography.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(AppSpacing.md)
                        .background(.black.opacity(0.35), in: Circle())
                }
                .padding(.bottom, AppSpacing.xxl)
            }
        }
    }
}

// MARK: - Camera preview

private struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {}

    final class PreviewUIView: UIView {
        let previewLayer = AVCaptureVideoPreviewLayer()

        override init(frame: CGRect) {
            super.init(frame: frame)
            layer.addSublayer(previewLayer)
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        override func layoutSubviews() {
            super.layoutSubviews()
            previewLayer.frame = bounds
        }
    }
}
#endif
