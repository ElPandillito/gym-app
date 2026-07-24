//
//  SectionHeader.swift
//  GYM APP
//

import SwiftUI

/// Styled section header for use inside List/Form or standalone VStack layouts.
struct AppSectionHeader: View {
    let title: String
    let icon: String?
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    init(_ title: String, icon: String? = nil, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.title       = title
        self.icon        = icon
        self.actionTitle = actionTitle
        self.action      = action
    }

    var body: some View {
        HStack {
            if let icon {
                Label(title, systemImage: icon)
            } else {
                Text(title)
            }
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(AppTypography.footnote)
            }
        }
        .font(AppTypography.sectionHeader)
        .foregroundStyle(AppColors.secondaryText)
        .textCase(nil)
    }
}
