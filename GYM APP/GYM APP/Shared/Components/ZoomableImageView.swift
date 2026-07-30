//
//  ZoomableImageView.swift
//  GYM APP
//

import SwiftUI

struct ZoomableImageView: View {
    let image: PlatformImage

    @State private var scale: CGFloat     = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize     = .zero
    @State private var lastOffset: CGSize = .zero

    private let minScale: CGFloat = 1.0
    private let maxScale: CGFloat = 5.0

    var body: some View {
        GeometryReader { geo in
            makeImage()
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(scale)
                .offset(offset)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .gesture(magnifyGesture)
                .simultaneousGesture(dragGesture(in: geo.size))
                .onTapGesture(count: 2) { handleDoubleTap() }
        }
    }

    private func makeImage() -> Image {
        #if os(iOS)
        Image(uiImage: image)
        #elseif os(macOS)
        Image(nsImage: image)
        #endif
    }

    private var magnifyGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let delta = value / lastScale
                lastScale = value
                scale = clamp(scale * delta, lower: minScale, upper: maxScale)
            }
            .onEnded { _ in
                lastScale = 1.0
                if scale < minScale {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        scale = minScale
                        offset = .zero
                        lastOffset = .zero
                    }
                }
            }
    }

    private func dragGesture(in containerSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                guard scale > minScale else { return }
                offset = CGSize(
                    width:  lastOffset.width  + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                guard scale > minScale else { return }
                lastOffset = offset
                snapOffset(in: containerSize)
            }
    }

    private func handleDoubleTap() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            if scale > minScale {
                scale = minScale
                offset = .zero
                lastOffset = .zero
            } else {
                scale = 2.5
            }
        }
    }

    private func snapOffset(in size: CGSize) {
        let maxX = Swift.max(0, (size.width  * (scale - 1)) / 2)
        let maxY = Swift.max(0, (size.height * (scale - 1)) / 2)
        let snapped = CGSize(
            width:  clamp(offset.width,  lower: -maxX, upper: maxX),
            height: clamp(offset.height, lower: -maxY, upper: maxY)
        )
        guard snapped != offset else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            offset = snapped
            lastOffset = snapped
        }
    }

    private func clamp(_ value: CGFloat, lower: CGFloat, upper: CGFloat) -> CGFloat {
        Swift.min(Swift.max(value, lower), upper)
    }
}
