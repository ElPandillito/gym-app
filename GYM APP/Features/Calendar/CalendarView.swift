//
//  CalendarView.swift
//  GYM APP
//

import SwiftUI

struct CalendarView: View {
    var body: some View {
        ContentUnavailableView {
            Label("Calendario", systemImage: "calendar")
        } description: {
            Text("El calendario de check ins y actividades de tus atletas aparecerá aquí.")
        }
        .navigationTitle("Calendario")
    }
}

#Preview {
    NavigationStack {
        CalendarView()
    }
}
