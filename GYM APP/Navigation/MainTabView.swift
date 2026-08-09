//
//  MainTabView.swift
//  GYM APP
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                DashboardView()
            }
            .tabItem {
                Label("Dashboard", systemImage: "square.grid.2x2.fill")
            }
            .tag(0)

            NavigationStack {
                AthleteListView()
            }
            .tabItem {
                Label("Atletas", systemImage: "person.2.fill")
            }
            .tag(1)

            NavigationStack {
                NutritionView()
            }
            .tabItem {
                Label("Nutrición", systemImage: "fork.knife")
            }
            .tag(2)

            NavigationStack {
                CalendarView()
            }
            .tabItem {
                Label("Calendario", systemImage: "calendar")
            }
            .tag(3)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Configuración", systemImage: "gearshape.fill")
            }
            .tag(4)
        }
    }
}

#Preview("iPhone 16") {
    MainTabView()
        .previewDevice(PreviewDevice(rawValue: "iPhone 16"))
}
