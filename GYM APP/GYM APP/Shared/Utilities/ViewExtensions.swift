//
//  ViewExtensions.swift
//  GYM APP
//

import SwiftUI

extension View {
    /// Applies .keyboardType(.decimalPad) on iOS only — no-op on macOS.
    func decimalKeyboard() -> some View {
        #if os(iOS)
        self.keyboardType(.decimalPad)
        #else
        self
        #endif
    }
}
