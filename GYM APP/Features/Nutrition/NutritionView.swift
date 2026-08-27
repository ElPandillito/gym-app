//
//  NutritionView.swift
//  GYM APP
//

import SwiftUI
import SwiftData

struct NutritionView: View {
    /// True when this view is embedded inside another view (e.g. AthleteDetailView).
    /// Skips .navigationTitle and .searchable; shows an inline search bar instead.
    var isEmbedded: Bool = false

    @Query(sort: \Food.name) private var foods: [Food]
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = NutritionFoodLibraryViewModel()
    @State private var selectedFood: Food?
    @State private var isShowingCreateForm = false
    @State private var isShowingPreparedForm = false

    private let columns = [
        GridItem(.flexible(), spacing: AppSpacing.md),
        GridItem(.flexible(), spacing: AppSpacing.md),
    ]

    var body: some View {
        Group {
            if isEmbedded {
                embeddedLayout
            } else {
                standaloneLayout
            }
        }
        .sheet(item: $selectedFood) { food in
            FoodDetailView(food: food)
        }
        .sheet(isPresented: $isShowingCreateForm) {
            FoodFormView(mode: .create, context: modelContext)
        }
        .sheet(isPresented: $isShowingPreparedForm) {
            PreparedFoodFormView(mode: .create, context: modelContext)
        }
        .onChange(of: foods) { _, newFoods in
            viewModel.update(foods: newFoods)
        }
        .onAppear {
            viewModel.update(foods: foods)
        }
    }

    // MARK: - Layouts

    private var standaloneLayout: some View {
        VStack(spacing: 0) {
            kindFilterBar
            if viewModel.selectedKind != .preparedFood {
                FoodCategoryFilterView(selectedCategory: $viewModel.selectedCategory)
            }
            Divider()
            libraryContent
        }
        .navigationTitle("Nutrición")
        .searchable(text: $viewModel.searchText, prompt: "Buscar alimento...")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        isShowingCreateForm = true
                    } label: {
                        Label("Nuevo alimento", systemImage: "plus.circle")
                    }
                    Button {
                        isShowingPreparedForm = true
                    } label: {
                        Label("Nuevo platillo", systemImage: "fork.knife")
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }

    private var embeddedLayout: some View {
        VStack(spacing: 0) {
            inlineSearchBar
            kindFilterBar
            if viewModel.selectedKind != .preparedFood {
                FoodCategoryFilterView(selectedCategory: $viewModel.selectedCategory)
            }
            Divider()
            libraryContent
        }
    }

    // MARK: - Kind filter bar

    private var kindFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                KindChip(title: "Todos", isSelected: viewModel.selectedKind == nil) {
                    viewModel.selectedKind = nil
                    viewModel.selectedCategory = nil
                }
                KindChip(title: "Ingredientes", isSelected: viewModel.selectedKind == .ingredient) {
                    viewModel.selectedKind = viewModel.selectedKind == .ingredient ? nil : .ingredient
                    viewModel.selectedCategory = nil
                }
                KindChip(title: "Platillos", isSelected: viewModel.selectedKind == .preparedFood) {
                    viewModel.selectedKind = viewModel.selectedKind == .preparedFood ? nil : .preparedFood
                    viewModel.selectedCategory = nil
                }
            }
            .padding(.horizontal, AppSpacing.base)
            .padding(.vertical, AppSpacing.xs)
        }
    }

    // MARK: - Inline search bar (embedded mode only)

    private var inlineSearchBar: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Buscar alimento...", text: $viewModel.searchText)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(AppColors.secondaryBg, in: RoundedRectangle(cornerRadius: AppRadius.md))
        .padding(.horizontal, AppSpacing.base)
        .padding(.top, AppSpacing.sm)
        .padding(.bottom, AppSpacing.xs)
    }

    // MARK: - Library content

    @ViewBuilder
    private var libraryContent: some View {
        if viewModel.filteredFoods.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: AppSpacing.md) {
                    ForEach(viewModel.filteredFoods) { food in
                        FoodCardView(food: food) {
                            selectedFood = food
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.base)
                .padding(.vertical, AppSpacing.base)
                .padding(.bottom, AppSpacing.xxxl)
            }
        }
    }

    private var emptyState: some View {
        ScrollView {
            EmptyStateView(
                icon: "fork.knife",
                title: "Sin alimentos",
                message: viewModel.searchText.isEmpty && viewModel.selectedCategory == nil
                    ? "La biblioteca visual aparecerá aquí."
                    : "No hay alimentos que coincidan con tu búsqueda."
            )
            .padding(.top, AppSpacing.xxxl)
        }
    }
}

// MARK: - Kind Chip

private struct KindChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xs)
                .background(
                    isSelected ? Color.accentColor : Color.accentColor.opacity(0.12),
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

#Preview("iPhone 16 — Standalone") {
    NavigationStack {
        NutritionView()
    }
    .modelContainer(for: Food.self, inMemory: true)
}

#Preview("iPhone 16 — Embedded") {
    NavigationStack {
        NutritionView(isEmbedded: true)
    }
    .modelContainer(for: Food.self, inMemory: true)
}
