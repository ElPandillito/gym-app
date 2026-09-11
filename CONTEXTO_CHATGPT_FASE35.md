# Contexto para Claude — GYM APP (post Phase 35)

## Estado actual del proyecto

Aplicación SwiftUI/SwiftData para coaches de fitness (iOS + macOS).
Rama: `main` — **223 tests pasando.**
Último commit: `0d90a5b Phase 35: AI Body Fat Photo Assessment — protocol, stub, persistence, and UI`

---

## Lo que se implementó en Phase 35

### Objetivo: Infraestructura de estimación de grasa corporal por IA

El sistema permite a un coach obtener una estimación de % de grasa corporal a partir de los datos antropométricos disponibles en un check-in. Usa una cadena de prioridad determinística (stub) diseñada para ser reemplazada por visión computacional real (CoreML / FoundationModels) sin cambiar ningún call site.

### A — Protocolo y tipos

Archivo: `GYM APP/Core/AIEngine/Protocols/BodyFatAssessmentServiceProtocol.swift`

```swift
protocol BodyFatAssessmentServiceProtocol {
    func estimate(photos: [PhotoPathEntry], context: BodyFatAssessmentContext) async throws -> BodyFatAssessmentResult
}

struct PhotoPathEntry: Sendable { relativePath: String, poseType: PoseType }

struct BodyFatAssessmentContext: Sendable {
    bodyWeightKg, heightCm, bioimpedanceBodyFatPct, skinfoldBodyFatPct,
    waistCm, hipCm, neckCm: Double?
    gender: Gender?
    ageYears: Double?
}

struct BodyFatAssessmentResult: Sendable {
    estimatedBodyFatPct, confidenceScore: Double
    assessmentBasis: AssessmentBasis
    notes: [String]
    generatedAt: Date
}

enum AssessmentBasis: String, Sendable, Codable {
    case visionOnly, visionWithContext, stubDeterministic
}
```

### B — Stub determinístico

Archivo: `GYM APP/Core/AIEngine/Stubs/BodyFatAssessmentStub.swift`

Cadena de prioridad (mayor calidad primero):
1. **Plicometría** (`skinfoldBodyFatPct`) → valor directo, confianza base 0.55
2. **Bioimpedancia** (`bioimpedanceBodyFatPct`) → valor directo, confianza base 0.50
3. **Fórmula Marina EE.UU.** (waist + hip + neck? + height + gender) → confianza 0.32–0.40
4. **Fórmula Deurenberg** (BMI + género + edad) → confianza base 0.30

Bonus por fotos: 3 vistas (front/back/side) +0.05 | 2 vistas +0.03 | 1 foto +0.01
**Confianza máxima: 0.55** (el stub nunca simula precisión de visión real)

Validación:
- `skinfoldBodyFatPct` o `bioimpedanceBodyFatPct` fuera de `3.0...60.0` → `AIServiceError.invalidInput`
- Sin ninguna señal disponible → `AIServiceError.insufficientData`

### C — Modelo SwiftData

Archivo: `GYM APP/Core/Models/AIBodyFatAssessment.swift`

```swift
@Model final class AIBodyFatAssessment {
    @Attribute(.unique) var id: UUID
    var estimatedBodyFatPct: Double
    var confidenceScore: Double
    var assessmentBasisRaw: String    // String, no enum — evita migraciones al cambiar casos
    var notesJSON: String             // [String] codificado como JSON
    var photoCount: Int
    var generatedAt: Date
    var createdAt: Date
    var checkIn: CheckIn?
    // computed: var notes: [String], var assessmentBasis: AssessmentBasis
}
```

**Adiciones a modelos existentes:**
- `CheckIn.swift` → `@Relationship(deleteRule: .cascade) var aiBodyFatAssessment: AIBodyFatAssessment?`
- `AppSchema.swift` → `AIBodyFatAssessment.self` añadido a `GYMAppSchemaV1.models` (todos los campos Optional → migración ligera, sin MigrationStage)

### D — Repositorio

Archivo: `GYM APP/Core/Repositories/AIBodyFatAssessmentRepository.swift`

```swift
struct AIBodyFatAssessmentRepository {
    func save(_ assessment: AIBodyFatAssessment, for checkIn: CheckIn) throws
    // Elimina evaluación previa del check-in antes de guardar la nueva
}
```

### E — ViewModel

Archivo: `GYM APP/Features/CheckIn/ViewModels/BodyFatAssessmentViewModel.swift`

```swift
@MainActor @Observable final class BodyFatAssessmentViewModel {
    enum State { case idle, loading, result(AIBodyFatAssessment), error(String) }
    init(service: any BodyFatAssessmentServiceProtocol = BodyFatAssessmentStub())
    func loadExisting(from checkIn: CheckIn)   // carga resultado existente sin llamar al servicio
    func run(for checkIn: CheckIn, context: ModelContext)   // construye contexto, llama servicio, persiste
    func reset()   // vuelve a .idle para re-estimar
}
```

`run()` extrae datos del check-in (bodyMetrics, circumferences, skinfolds, athlete) y construye `BodyFatAssessmentContext` automáticamente.

### F — UI Card

Archivo: `GYM APP/Features/CheckIn/Components/AIBodyFatAssessmentCard.swift`

SwiftUI `Section` con 4 estados:
- **idle** — botón "Estimar grasa corporal con IA"
- **loading** — ProgressView + "Analizando datos…"
- **result** — % estimado, barra de confianza, badge de base, notas, botón "Volver a estimar"
- **error** — mensaje localizado + "Reintentar"

Integrado en `CheckInDetailView.swift` después de `igcSection`.

### G — Tests

Archivo: `GYM APPTests/EngineTests/BodyFatAssessmentStubTests.swift` — 16 tests:

| Test | Qué verifica |
|---|---|
| `conformsToProtocol` | Tipo conforma al protocolo |
| `emptyContextThrowsInsufficientData` | Sin señal → `.insufficientData` |
| `skinfoldPath_returnsValue` | Usa valor de plicometría exacto |
| `skinfoldPath_confidence` | Confianza 0.55 sin fotos |
| `skinfoldPath_basis` | Basis `.stubDeterministic` |
| `bioimpedancePath_returnsValue` | Usa valor de bioimpedancia |
| `bioimpedancePath_confidence` | Confianza 0.50 sin fotos |
| `navyPath_fullData` | Resultado fisiológico, confianza 0.40 con cuello |
| `navyPath_reducedConfidenceWithoutNeck` | Confianza 0.32 sin cuello |
| `deurenbergPath_basicData` | Resultado fisiológico, confianza 0.30 |
| `outOfRangeSkinfold_throwsInvalidInput` | 100.0 % → `.invalidInput` |
| `belowRangeBioimpedance_throwsInvalidInput` | 1.0 % → `.invalidInput` |
| `photoBonus_threePhotosRaisesConfidence` | 3 poses > baseline |
| `photoBonus_singlePhotoAdds0_01` | 1 foto agrega +0.01 exacto |
| `confidenceNeverExceeds0_55` | Cap verificado |
| `determinism_sameInputSameOutput` | Mismo input → mismo resultado |

---

## Conteo de tests (post Phase 35)

| Suite | Tests |
|---|---|
| AppUnitFormatterTests | 29 |
| AthleteAlertEvaluatorTests | 15 |
| AthleteReportSerializerTests | 10 |
| AutoRecommendationStubTests | 12 |
| BodyFatAssessmentStubTests | 16 *(nuevo)* |
| CheckInComparisonEngineTests | 8 |
| CheckInWorkflowIntegrationTests | 6 |
| ComparisonViewModelUnitTests | 7 |
| DashboardFilterTests | 11 |
| FoodMacrosCalculatorTests | 9 |
| InputConversionTests | 16 |
| ProgressPredictionStubTests | ~10 |
| SkinfoldCalculatorTests | ~10 |
| StatisticsEngineTests | ~20 |
| TimelineBuilderTests | ~10 |
| GYM APPUITest | 4 |
| **TOTAL** | **223** |

---

## Historial de fases

| Phase | Descripción |
|---|---|
| 27 | Tests DashboardFilter, AthleteAlertEvaluator, AthleteReportSerializer |
| 28 | CoachNote y AthleteNote editables en CheckInDetailView |
| 29 | FileProtection.completeUnlessOpen en SwiftData store |
| 30 | CoachPreferences editor en SettingsView |
| 31 | CoachPreferencesStore conectado a domain engines |
| 32 | AIEngine contratos, stubs y tests (155 passing) |
| 33 | AppUnitFormatter + unidades preferidas en capa de presentación |
| 34 | Unit boundary completo + input conversion (207 passing) ✅ |
| 35 | AI Body Fat Photo Assessment — protocol, stub, persistence, UI (223 passing) ✅ |

---

## Deuda técnica conocida

1. **AIEngine real** — `BodyFatAssessmentStub`, `AutoRecommendationStub`, `ProgressPredictionStub` listos para conectarse a CoreML / FoundationModels / Vision framework.
2. **Visión computacional** — `assessmentBasis: .visionOnly` y `.visionWithContext` son plazas vacías para una implementación real de Phase 36+.
3. **macOS** — La card `AIBodyFatAssessmentCard` usa condicionales `#if os(iOS)` heredados; revisar que la UI se vea bien en macOS también.

---

## Reglas críticas del proyecto

- **Swift 6 concurrency**: `@Suite` structs → `@MainActor`; defaults de params no pueden referenciar tipos `@MainActor`
- **Seguridad**: FileProtection en SwiftData, Keychain para datos sensibles, sin logs de métricas biométricas, on-device AI preferido
- **Auditar antes de escribir**: no crear Engines/ViewModels/modelos innecesarios; reutilizar infraestructura existente
- **Build iOS + macOS** siempre antes de commit
- **No saltar fases** — cada fase debe tener tests pasando antes de avanzar
- **Unit boundary**: dominio siempre kg/cm → `AppUnitFormatter` es la ÚNICA capa de conversión
- **assessmentBasisRaw como String**: nunca exponer enums directamente en `@Model` para evitar migraciones
- **PBXFileSystemSynchronizedRootGroup**: Xcode 16 auto-descubre archivos `.swift` — no editar `project.pbxproj` manualmente

---

*Generado post-Phase 35 — 223 tests (223 pass, 0 fail) — rama: main — commit: 0d90a5b*
