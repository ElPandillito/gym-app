//
//  AthleteNutritionView.swift
//  GYM APP
//

import SwiftUI
import SwiftData

/// Top-level nutrition hub for a specific athlete, shown in AthleteDetailView.
/// Tabs: Planes (athlete's nutrition plans) · Biblioteca (global food library).
struct AthleteNutritionView: View {
    @Environment(\.modelContext) private var modelContext

    let athlete: Athlete

    enum Tab: String, CaseIterable {
        case plans   = "Planes"
        case library = "Biblioteca"
    }

    @State private var selectedTab: Tab = .plans

    var body: some View {
        VStack(spacing: 0) {
            tabBar
            Divider()
            tabContent
        }
    }

    // MARK: - Tab bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 0) {
                        Text(tab.rawValue)
                            .font(.subheadline)
                            .fontWeight(selectedTab == tab ? .semibold : .regular)
                            .foregroundStyle(selectedTab == tab ? Color.accentColor : .secondary)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)

                        Rectangle()
                            .fill(selectedTab == tab ? Color.accentColor : Color.clear)
                            .frame(height: 2)
                    }
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    // MARK: - Tab content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .plans:
            // No nested NavigationStack — relies on the parent NavigationStack from AthleteListView.
            NutritionPlanListView(athlete: athlete, context: modelContext)
        case .library:
            NutritionView(isEmbedded: true)
        }
    }
}
