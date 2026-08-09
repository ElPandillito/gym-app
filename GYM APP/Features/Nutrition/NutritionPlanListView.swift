//
//  NutritionPlanListView.swift
//  GYM APP
//

import SwiftUI
import SwiftData

struct NutritionPlanListView: View {
    @Environment(\.modelContext) private var modelContext

    let athlete: Athlete

    @State private var viewModel: NutritionPlanListViewModel
    @State private var isShowingCreateForm = false
    @State private var selectedPlan: NutritionPlan?

    init(athlete: Athlete, context: ModelContext) {
        self.athlete = athlete
        _viewModel = State(initialValue: NutritionPlanListViewModel(context: context))
    }

    /// Live from SwiftData relationship — auto-updates when plans change.
    private var sortedPlans: [NutritionPlan] {
        athlete.nutritionPlans.sorted { $0.startDate > $1.startDate }
    }

    var body: some View {
        Group {
            if sortedPlans.isEmpty {
                emptyState
            } else {
                planList
            }
        }
        .navigationTitle("Planes de nutrición")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { isShowingCreateForm = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $isShowingCreateForm) {
            NutritionPlanFormView(mode: .create(athlete), context: modelContext)
        }
        .navigationDestination(item: $selectedPlan) { plan in
            NutritionPlanDetailView(plan: plan, athlete: athlete, context: modelContext)
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Plan list

    private var planList: some View {
        List {
            ForEach(sortedPlans) { plan in
                PlanRow(plan: plan)
                    .contentShape(Rectangle())
                    .onTapGesture { selectedPlan = plan }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            viewModel.delete(plan, for: athlete)
                        } label: {
                            Label("Eliminar", systemImage: "trash")
                        }
                        Button {
                            if plan.isActive {
                                viewModel.deactivate(plan, for: athlete)
                            } else {
                                viewModel.activate(plan, for: athlete)
                            }
                        } label: {
                            Label(
                                plan.isActive ? "Desactivar" : "Activar",
                                systemImage: plan.isActive ? "pause.circle" : "checkmark.circle"
                            )
                        }
                        .tint(plan.isActive ? .orange : .green)
                    }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #endif
    }

    // MARK: - Empty state

    private var emptyState: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                EmptyStateView(
                    icon: "fork.knife.circle",
                    title: "Sin planes de nutrición",
                    message: "Crea el primer plan de nutrición para \(athlete.name)."
                )
                Button {
                    isShowingCreateForm = true
                } label: {
                    Label("Crear plan", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .padding(.horizontal, AppSpacing.xl)
                        .padding(.vertical, AppSpacing.sm)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.top, AppSpacing.xxxl)
            .padding(.horizontal, AppSpacing.base)
        }
    }
}

// MARK: - PlanRow

private struct PlanRow: View {
    let plan: NutritionPlan

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: AppSpacing.xs) {
                    Text(plan.name)
                        .font(.subheadline.weight(.semibold))
                    if plan.isActive {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                    }
                }
                Text(plan.dateRangeText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                let macros = plan.totalMacros
                if macros.calories > 0 {
                    Text(String(format: "%.0f kcal · P%.0fg · C%.0fg · G%.0fg",
                                macros.calories, macros.protein,
                                macros.carbohydrates, macros.fat))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, AppSpacing.xs)
    }
}
