//
//  PlaceholderSectionView.swift
//  GYM APP
//

import SwiftUI

struct PlaceholderSectionView: View {
    let title: String
    let icon: String
    let description: String
    var actionLabel: String? = nil
    var onAction: (() -> Void)? = nil

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: icon)
        } description: {
            Text(description)
        } actions: {
            if let actionLabel, let onAction {
                Button(action: onAction) {
                    Label(actionLabel, systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}

#Preview {
    PlaceholderSectionView(
        title: "Nutrición",
        icon: "fork.knife",
        description: "El plan nutricional aparecerá aquí.",
        actionLabel: "Crear Plan",
        onAction: {}
    )
}
