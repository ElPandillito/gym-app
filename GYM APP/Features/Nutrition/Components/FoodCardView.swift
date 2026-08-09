//
//  FoodCardView.swift
//  GYM APP
//

import SwiftUI

// MARK: - FoodCategory visual tokens

extension FoodCategory {
    var color: Color {
        switch rawValue {
        case "proteinas":     return .red
        case "carbohidratos": return .orange
        case "frutas":        return Color(red: 0.18, green: 0.75, blue: 0.25)
        case "verduras":      return .green
        case "grasas":        return .yellow
        case "lacteos":       return .blue
        case "cereales":      return Color(red: 0.72, green: 0.52, blue: 0.28)
        case "legumbres":     return Color(red: 0.55, green: 0.33, blue: 0.15)
        case "snacks":        return .purple
        case "bebidas":       return .cyan
        case "preparaciones": return .indigo
        default:              return .gray
        }
    }

    var systemImage: String {
        switch rawValue {
        case "proteinas":     return "flame.fill"
        case "carbohidratos": return "bolt.fill"
        case "frutas":        return "leaf.fill"
        case "verduras":      return "leaf.fill"
        case "grasas":        return "drop.fill"
        case "lacteos":       return "drop.fill"
        case "cereales":      return "rectangle.stack.fill"
        case "legumbres":     return "circle.fill"
        case "snacks":        return "star.fill"
        case "bebidas":       return "cup.and.saucer.fill"
        case "preparaciones": return "fork.knife"
        default:              return "tray.fill"
        }
    }
}

// MARK: - Category Placeholder

struct FoodCategoryPlaceholderView: View {
    let category: FoodCategory

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [category.color.opacity(0.35), category.color.opacity(0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: category.systemImage)
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(category.color.opacity(0.7))
        }
    }
}

// MARK: - Food Card

struct FoodCardView: View {
    let food: Food
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                imageArea
                    .frame(height: 130)
                infoArea
            }
            .background(AppColors.secondaryBg)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            .appShadow(AppShadows.card)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var imageArea: some View {
        ZStack(alignment: .topTrailing) {
            if let imgPath = food.image?.thumbnailPath ?? food.image?.originalPath {
                FoodAsyncImageView(relativePath: imgPath, contentMode: .fill)
                    .clipped()
            } else {
                FoodCategoryPlaceholderView(category: food.category)
            }

            if food.kind == .preparedFood {
                Image(systemName: "fork.knife")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(AppSpacing.xs)
                    .background(.indigo.opacity(0.85), in: Capsule())
                    .padding(AppSpacing.xs)
            }
        }
    }

    private var infoArea: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            Text(food.name)
                .font(.subheadline.weight(.medium))
                .lineLimit(2)
                .foregroundStyle(AppColors.primaryText)

            Text(summaryLine)
                .font(.caption)
                .foregroundStyle(AppColors.secondaryText)
        }
        .padding(AppSpacing.sm)
    }

    private var summaryLine: String {
        let n = food.nutritionPer100g
        if food.kind == .preparedFood {
            let kcal = Int(n.calories.rounded())
            return "\(kcal) kcal total"
        }
        return "\(Int(n.protein.rounded()))P · \(Int(n.carbohydrates.rounded()))C · \(Int(n.fat.rounded()))G"
    }
}
