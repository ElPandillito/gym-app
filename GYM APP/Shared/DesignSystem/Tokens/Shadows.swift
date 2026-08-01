//
//  Shadows.swift
//  GYM APP
//

import SwiftUI

struct AppShadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

enum AppShadows {
    static let sm  = AppShadow(color: .black.opacity(0.06), radius: 4,  x: 0, y: 2)
    static let md  = AppShadow(color: .black.opacity(0.08), radius: 8,  x: 0, y: 4)
    static let lg  = AppShadow(color: .black.opacity(0.10), radius: 16, x: 0, y: 8)
    static let card = AppShadow(color: .black.opacity(0.07), radius: 6, x: 0, y: 3)
}

extension View {
    func appShadow(_ shadow: AppShadow) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
}
