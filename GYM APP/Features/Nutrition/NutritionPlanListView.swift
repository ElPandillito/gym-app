//
//  NutritionPlanListView.swift
//  GYM APP
//

import SwiftUI
import SwiftData

struct NutritionPlanListView: View {
    @Environment(\.modelContext) private var modelContext

    let athlete: Athlete

    /// @Query without predicate guarantees reactive refresh — optional-chaining predicates
    /// in #Predicate are unreliable at runtime in SwiftData; client-side filter is safer.
    @Query(sort: [SortDescriptor(\NutritionPlan.startDate, order: .reverse)])
    private var allPlans: [NutritionPlan]
    @State private var viewModel: NutritionPlanListViewModel
    @State private var isShowingCreateForm = false
    @State private var selectedPlan: NutritionPlan?

    private var plans: [NutritionPlan] {
        allPlans.filter { $0.athlete?.id == athlete.id }
    }

    init(athlete: Athlete, context: ModelContext) {
        self.athlete = athlete
        _viewModel = State(initialValue: NutritionPlanListViewModel(context: context))
    }

    var body: some View {
        Group {
            if plans.isEmpty {
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
            ForEach(plans) { plan in
                PlanRow(plan: plan)
                    .contentShape(Rectangle())
                    .onTapGesture { selectedPlan = plan }
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button {
                            viewModel.duplicate(plan, for: athlete)
                        } label: {
                            Label("Duplicar", systemImage: "doc.on.doc")
                        }
                        .tint(AppColors.info)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            viewModel.delete(plan)
                        } label: {
                            Label("Eliminar", systemImage: "trash")
                        }
                        Button {
                            if plan.isActive {
                                viewModel.deactivate(plan)
                            } else {
                                viewModel.activate(plan)
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
