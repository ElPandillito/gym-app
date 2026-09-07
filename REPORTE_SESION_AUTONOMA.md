# Reporte de Sesión Autónoma — GYM APP
**Sesión:** Claude Sonnet 4.6 (autoridad autónoma)
**Fases completadas:** 26 → 32
**Commits creados:** 6 nuevos commits sobre `main`

---

## Contexto previo (antes de esta sesión)
Las fases 1–25 ya existían. La app tenía:
- SwiftData con `GYMAppSchemaV1` (16 modelos)
- Repository pattern completo
- `CheckInSnapshot`, `AthleteSnapshot` (value types)
- `StatisticsEngine` (OLS trends), `CheckInComparisonEngine`, `AthleteAlertEvaluator`, `TimelineBuilder`
- `CoachPreferences` struct (value type, in-memory), `DashboardFilter`
- `AthleteReportBuilder` (fluent builder, sin UI todavía)
- UI completa: Dashboard, AthleteList, AthleteDetail, CheckIn workflow, Nutrition

---

## Phase 26 — Reporte de atleta con ShareLink
**Commit:** incluido en commit de fases 26-28

### Archivos creados
- `GYM APP/Core/ReportEngine/AthleteReportSerializer.swift`
- `GYM APP/Features/Athletes/AthleteReportSheet.swift`

### Archivos modificados
- `GYM APP/Features/Athletes/AthleteDetailView.swift`

### Qué hace
`AthleteReportSerializer` convierte un `AthleteReport` a texto plano compartible. Produce secciones: encabezado con nombre/check-ins/período, estadísticas generales (peso actual, % grasa, masa muscular, IMC), tendencias (peso, grasa, músculo con símbolo ↑↓→— y cambio mensual), marcas personales (máx/mín peso, mejor % grasa), y footer "GYM APP".

`AthleteReportSheet` es un `.sheet` con 4 secciones en tarjetas y un `ShareLink` en el toolbar que exporta el texto plano via la hoja nativa de iOS/macOS.

En `AthleteDetailView` se añadió un ítem al toolbar Menu "Generar Reporte" (deshabilitado si `statisticsReport == nil`, es decir si el atleta tiene < 2 check-ins). Al taparlo presenta `AthleteReportSheet`.

### Patrón de construcción del reporte
```swift
// En AthleteReportSheet:
private var report: AthleteReport? {
    guard let stats = statisticsReport else { return nil }
    return AthleteReportBuilder()
        .setAthlete(AthleteSnapshot(from: athlete))
        .setStatistics(stats)
        .build()
}
// ShareLink usa: AthleteReportSerializer.text(from: r)
```

### Conversión de tendencias
El `slope` en `Trend` es **por día**. Para mostrar cambio mensual se multiplica × 30:
```swift
private static func trendLine(_ trend: Trend, unit: String) -> String {
    let monthly = trend.slope * 30
    // .rising → "↑ Subiendo  (+X.XX kg/mes)"
    // .falling → "↓ Bajando   (-X.XX kg/mes)"
    // .flat    → "→ Estable"
    // .insufficient → "— Datos insuficientes"
}
```

---

## Phase 27 — Tests: DashboardFilter, AthleteReportSerializer, AthleteAlertEvaluator (ampliación)
**Commit:** incluido en commit de fases 26-28

### Archivos creados
- `GYM APPTests/EngineTests/DashboardFilterTests.swift`
- `GYM APPTests/EngineTests/AthleteReportSerializerTests.swift`

### Archivos modificados
- `GYM APPTests/EngineTests/AthleteAlertEvaluatorTests.swift`

### DashboardFilterTests (11 tests)
Usa `@MainActor`, `ModelContainer(for: Schema(GYMAppSchemaV1.models), configurations: ModelConfiguration(isStoredInMemoryOnly: true))`.

**Bug crítico encontrado y corregido:** `CheckIn.init` sólo acepta `date: Date` — no hay parámetro `athlete:`. La asignación correcta es:
```swift
let ci = CheckIn(date: date)
ctx.insert(ci)
ci.athlete = athlete   // ← asignar después de insert
```

Cubre: `.all` (retorna todos), `.competition` (contestPrep + peakWeek), `.bulk` (offSeason + leanBulk), `.cut` (miniCut + reverseDiet), `.active` (check-in dentro del umbral), `.inactive` (check-in pasado el umbral), `.custom` (passthrough).

### AthleteReportSerializerTests (10 tests)
Pure value type — sin SwiftData. Cubre: encabezado presente, nombre del atleta, conteo de check-ins, footer "GYM APP", símbolos ↑↓→— de tendencias, "Sin datos suficientes" cuando no hay records, valor del récord cuando se configura.

### AthleteAlertEvaluatorTests (5 tests añadidos, total 14)
Tests añadidos al archivo existente (tenía 9):
- `risingBfTrendAlert` — BF subiendo ~4pp en 35 días con 3 snapshots → genera `.negativeTrend`
- `insufficientBfPointsNoNegativeTrend` — solo 2 snapshots → no genera `.negativeTrend`
- `disabledInactiveAlertToggle` — `showInactiveAlerts = false` → suprime `.inactive`
- `disabledPhotoAlertToggle` — `showPhotoAlerts = false` → suprime `.noPhotos`
- `disabledMetricAlertToggle` — `showMetricAlerts = false` → suprime `.incompleteMetrics`

---

## Phase 28 — NotesEditSheet (UI para editar notas del check-in)
**Commit:** `Phase 28: NotesEditSheet — inline notes editing for CheckIn`

### Archivos creados
- `GYM APP/Features/CheckIn/NotesEditSheet.swift`

### Archivos modificados
- `GYM APP/Features/CheckIn/ViewModels/CheckInDetailViewModel.swift`
- `GYM APP/Features/CheckIn/CheckInDetailView.swift`

### Qué hace
`NotesEditSheet` es un sheet ligero para editar las notas de coach y atleta de un check-in. Se pre-popula con el texto existente (`loadExistingNotes()`), tiene dos `TextEditor` (uno por tipo de nota), botón Guardar que llama `CheckInRepository.saveNotes()` (ya existía completamente implementado), y alerta de error si el guardado falla.

En `CheckInDetailViewModel` se añadió `var isShowingNotesEdit: Bool = false`.

En `CheckInDetailView` en la sección `notesSection` el botón cambia dinámicamente:
- Sin notas → "Agregar notas" con icon `plus`
- Con notas → "Editar notas" con icon `pencil`

---

## Phase 29 — Protección FileProtection en SwiftData store (Deuda de seguridad D2)
**Commit:** incluido en el commit de Phase 30

### Archivos modificados
- `GYM APP/GYM_APPApp.swift`

### Qué hace
Aplica `FileProtectionType.completeUnlessOpen` + `isExcludedFromBackup = true` sobre los archivos del store de SwiftData inmediatamente después de crear el `ModelContainer`. Los archivos protegidos son:
- El archivo principal de la configuración
- `stem.sqlite`
- `stem.sqlite-shm` (shared memory WAL)
- `stem.sqlite-wal` (write-ahead log)

```swift
private static func applyStoreProtection(to url: URL) {
    // url viene de ModelConfiguration.url
    // Usa try? — best-effort, fallas no comprometen integridad de datos
    // NUNCA logs de la URL ni del error (seguridad)
}
```

**Restricciones de seguridad respetadas:**
- `try?` en todo — fallas silenciosas, los datos no se pierden
- Sin logs de rutas de filesystem
- Sin logs de NSError internals

---

## Phase 30 — CoachPreferences editor en SettingsView (persistencia real)
**Commit:** `Phase 30: CoachPreferences editor in SettingsView`

### Archivos creados
- `GYM APP/Core/Domain/CoachPreferencesStore.swift`

### Archivos modificados
- `GYM APP/GYM_APPApp.swift`
- `GYM APP/Features/Settings/SettingsView.swift`

### CoachPreferencesStore
`@MainActor @Observable final class` que persiste todas las preferencias del coach en `UserDefaults`. No usa `@AppStorage` porque no es compatible con `@Observable` (conflict de property wrappers con el macro `@Observable`). En su lugar, cada propiedad tiene un `didSet` que escribe a `UserDefaults.standard`, y el `init()` lee los valores guardados:

```swift
var inactivityThresholdDays: Int = 14 {
    didSet { UserDefaults.standard.set(inactivityThresholdDays, forKey: Keys.inactivityDays) }
}
// ... mismo patrón para todas las propiedades

init() {
    let d = UserDefaults.standard
    if let v = d.object(forKey: Keys.inactivityDays) as? Int { inactivityThresholdDays = v }
    // ...
}
```

Propiedades persistidas:
| Propiedad | Tipo | Default |
|---|---|---|
| `inactivityThresholdDays` | Int | 14 |
| `trendWindowDays` | Int | 60 |
| `progressWindowDays` | Int | 30 |
| `maxAlertsShown` | Int | 10 |
| `showInactiveAlerts` | Bool | true |
| `showPhotoAlerts` | Bool | true |
| `showMetricAlerts` | Bool | true |
| `preferredWeightUnit` | WeightUnit | .kg |
| `preferredLengthUnit` | LengthUnit | .cm |

Expone `var preferences: CoachPreferences { ... }` que construye el snapshot de value type para pasarle a los domain engines.

### Inyección en el app root
```swift
// GYM_APPApp.swift
@State private var preferencesStore = CoachPreferencesStore()

// En body:
MainTabView()
    .modelContainer(container)
    .environment(preferencesStore)  // accesible desde cualquier child view
```

### SettingsView
Pantalla rediseñada con secciones:
1. **Profile header** (stub de perfil con initials circle)
2. **Umbrales de alertas** — Steppers: `inactivityThresholdDays` (7–90), `trendWindowDays` (14–180, step 7), `maxAlertsShown` (1–30)
3. **Tipos de alerta** — Toggles: `showInactiveAlerts`, `showPhotoAlerts`, `showMetricAlerts`
4. **Unidades** — Pickers: `preferredWeightUnit` (kg/lb), `preferredLengthUnit` (cm/in)
5. **Aplicación** — filas stub (Notificaciones, Sincronización, Privacidad)
6. **Soporte** — filas stub (Ayuda, Calificar, Contacto)
7. **Restablecer preferencias** — botón destructivo con alert de confirmación
8. **Versión** — "GYM APP v1.0.0"

Usa `@Bindable var prefs = prefs` (patrón `@Observable` + `@Environment`) para binding bidireccional sin `@Binding` explícito.

---

## Phase 31 — Wire CoachPreferencesStore a los motores de dominio
**Commit:** `Phase 31: Wire CoachPreferencesStore into domain engines`

### Archivos modificados
- `GYM APP/Features/Dashboard/DashboardViewModel.swift`
- `GYM APP/Features/Dashboard/DashboardView.swift`
- `GYM APP/Features/Athletes/ViewModels/AthleteOverviewViewModel.swift`
- `GYM APP/Features/Athletes/AthleteDetailView.swift`
- `GYM APP/Features/Athletes/AthleteListView.swift`

### El problema que resolvía
`CoachPreferencesStore` existía y sus cambios se guardaban, pero **ningún motor de dominio los leía**. Todos seguían usando `CoachPreferences.default` hardcodeado.

### DashboardViewModel
Se eliminaron las constantes hardcodeadas `inactivityDays = 14`, `trendWindowDays = 60`, `progressWindowDays = 30`, `maxAlerts = 10`. Se añadió:

```swift
private var preferences: CoachPreferences = .default

func load(athletes: [Athlete], checkIns: [CheckIn], preferences: CoachPreferences = .default) {
    self.preferences = preferences
    // ...
}
```

Los métodos privados ahora leen `preferences.inactivityThresholdDays`, `preferences.progressWindowDays`, `preferences.maxAlertsShown`, y `preferences.trendWindowDays` (pasado al evaluador). Se mantiene `maxProgressors = 5`, `maxRecent = 10`, `maxActions = 10` como constantes de UI (no configurables por el usuario).

### AthleteOverviewViewModel
```swift
func build(from athlete: Athlete, preferences: CoachPreferences = .default) {
    // ...
    alerts = AthleteAlertEvaluator.evaluate(
        athleteID:      athlete.id,
        athleteName:    athlete.name,
        sortedCheckIns: snapshots,
        preferences:    preferences,   // ← ya no es .default hardcodeado
        now:            now
    )
}
```

### DashboardView
```swift
@Environment(CoachPreferencesStore.self) private var prefsStore

// Reemplaza 4 llamadas directas con:
private func reload() {
    viewModel.load(athletes: athletes, checkIns: checkIns, preferences: prefsStore.preferences)
}

// Añade:
.onChange(of: prefsStore.preferences) { reload() }
```

### AthleteDetailView
```swift
@Environment(CoachPreferencesStore.self) private var prefsStore

// Las 3 llamadas a build() ahora pasan preferencias:
overviewViewModel.build(from: athlete, preferences: prefsStore.preferences)

// Nuevo onChange para reaccionar en vivo:
.onChange(of: prefsStore.preferences) { _, _ in
    overviewViewModel.build(from: athlete, preferences: prefsStore.preferences)
}
```

### AthleteListView — AthleteRowView
```swift
struct AthleteRowView: View {
    @Environment(CoachPreferencesStore.self) private var prefsStore

    private var alertDotColor: Color? {
        // ...
        AthleteAlertEvaluator.evaluate(
            preferences: prefsStore.preferences,   // ← ya no es .default
            // ...
        )
    }
}
```

---

## Phase 32 — AIEngine: contratos, stubs y tests
**Commit:** `Phase 32: AIEngine contracts, stubs, and tests (155/155 passing)`

### Archivos creados
- `GYM APP/Core/AIEngine/Models/AIServiceError.swift`
- `GYM APP/Core/AIEngine/Protocols/AutoRecommendationServiceProtocol.swift`
- `GYM APP/Core/AIEngine/Protocols/ProgressPredictionServiceProtocol.swift`
- `GYM APP/Core/AIEngine/Protocols/PosingAnalysisServiceProtocol.swift`
- `GYM APP/Core/AIEngine/Protocols/BodySymmetryServiceProtocol.swift`
- `GYM APP/Core/AIEngine/Protocols/PhotoComparisonServiceProtocol.swift`
- `GYM APP/Core/AIEngine/Stubs/AutoRecommendationStub.swift`
- `GYM APP/Core/AIEngine/Stubs/ProgressPredictionStub.swift`
- `GYM APP/Core/AIEngine/Stubs/PosingAnalysisStub.swift`
- `GYM APP/Core/AIEngine/Stubs/BodySymmetryStub.swift`
- `GYM APP/Core/AIEngine/Stubs/PhotoComparisonStub.swift`
- `GYM APPTests/EngineTests/AutoRecommendationStubTests.swift`
- `GYM APPTests/EngineTests/ProgressPredictionStubTests.swift`

### AIServiceError
Tipo de error de dominio para todos los servicios de AI:
```swift
enum AIServiceError: Error, Sendable, Equatable {
    case insufficientData
    case unavailable
    case invalidInput(String)
    case serviceFailure
}
```

### Protocolos
Todos con `async throws` — sin Combine, sin callbacks.

| Protocolo | Input | Output |
|---|---|---|
| `AutoRecommendationServiceProtocol` | `AthleteSnapshot`, `AthleteStatisticsReport` | `[AIRecommendation]` |
| `ProgressPredictionServiceProtocol` | `MetricKey`, `[CheckInSnapshot]`, `daysAhead: Int` | `PredictionResult` |
| `PosingAnalysisServiceProtocol` | `UIImage` | `PoseAnalysisResult` |
| `BodySymmetryServiceProtocol` | `UIImage` | `SymmetryAnalysisResult` |
| `PhotoComparisonServiceProtocol` | `UIImage`, `UIImage` | `PhotoComparisonResult` |

Tipos de datos relevantes definidos en los protocolos:
- `AIRecommendation` — `id: UUID`, `category: RecommendationCategory`, `title`, `detail`, `priority: RecommendationPriority`, `generatedAt: Date`
- `RecommendationCategory` — `.bodyComposition`, `.checkInFrequency`, `.photography`, `.nutrition`, `.training`
- `RecommendationPriority: Int, Comparable` — `.low = 0`, `.medium = 1`, `.high = 2`
- `PredictionResult` — `metric: MetricKey`, `predictedValue: Double`, `confidenceInterval: ClosedRange<Double>`, `targetDate: Date`, `modelConfidence: Double`

### AutoRecommendationStub
Stub completamente determinístico basado en reglas (NO es ML). Evalúa señales de los trends del `AthleteStatisticsReport`:

| Señal | Condición | Categoría | Prioridad |
|---|---|---|---|
| Grasa corporal subiendo | `bodyFatTrend.slope * 30 > 0.3` | `.bodyComposition` | `.high` |
| Masa muscular bajando | `muscleMassTrend.slope * 30 < -0.2` | `.bodyComposition` | `.high` |
| Frecuencia baja | `averageDaysBetweenCheckIns > 21` | `.checkInFrequency` | `.medium` |

IDs de recomendaciones son UUIDs estables (hardcodeados) para garantizar determinismo. Clock es injectable para tests.

```swift
struct AutoRecommendationStub: AutoRecommendationServiceProtocol {
    let clock: @Sendable () -> Date
    init(clock: @Sendable @escaping () -> Date = { Date() }) { ... }
    func generateRecommendations(athlete: AthleteSnapshot, statistics: AthleteStatisticsReport) async throws -> [AIRecommendation]
}
```

### ProgressPredictionStub
Extrapolación lineal OLS usando la misma infraestructura `Trend.compute()` + `Trend.projected()` del `StatisticsEngine`:

```swift
struct ProgressPredictionStub: ProgressPredictionServiceProtocol {
    func predict(metric: MetricKey, snapshots: [CheckInSnapshot], daysAhead: Int) async throws -> PredictionResult
}
```

- Error residual crece con el horizonte de predicción: `stdErr = sqrt(mse) * (1 + daysAhead/30)`
- Confianza cap: `min(0.80, count/10)` — nunca implica certeza alta
- `extractPoints()` reimplementa el switch de métricas de `StatisticsEngine` (ese método es `private`)

### CV Stubs (infraestructura futura)
`PosingAnalysisStub`, `BodySymmetryStub`, `PhotoComparisonStub` devuelven resultados neutros/vacíos. No hay infraestructura de Vision/CoreML aún — son placeholders para las fases de Computer Vision.

### Tests (25 nuevos, 155/155 total)
**Fix crítico de Swift 6:** Todos los test suites deben ser `@MainActor`. Sin él, las conformancias `async throws` de los stubs son vistas como main-actor-isolated en contexto nonisolated, lo que causa un crash del test runner (Mach error -308). Además, los valores default de parámetros tipo `Trend = .insufficient` se evalúan en contexto nonisolated — se cambiaron a `Trend? = nil` con `?? .insufficient` dentro del cuerpo `@MainActor`.

| Suite | Tests |
|---|---|
| `AutoRecommendationStubTests` | 12 |
| `ProgressPredictionStubTests` | 13 |

**AutoRecommendationStubTests** cubre: conformance, checkInCount 0/1/<2, rising fat signal, small fat no-signal, falling muscle signal, avgDays>21 signal, avgDays≤21 no-signal, priority sort descending, determinism (IDs estables), generatedAt matches clock.

**ProgressPredictionStubTests** cubre: conformance, zeroDaysAhead throws, empty snapshots throws, single snapshot throws, no data for metric throws, rising/falling/flat trend, CI contains prediction, confidence in [0, 0.80], metric correct en result, targetDate correcto, determinism.

---

## Estado del proyecto al finalizar la sesión

### Commits en main (más recientes primero)
```
470efb1 Phase 32: AIEngine contracts, stubs, and tests (155/155 passing)
8740357 Phase 31: Wire CoachPreferencesStore into domain engines
37533d9 Phase 30: CoachPreferences editor in SettingsView
[prev]  Phase 28: NotesEditSheet — inline notes editing for CheckIn
[prev]  Phase 27: Tests — DashboardFilter, ReportSerializer, AlertEvaluator extensions
[prev]  Phase 26: AthleteReportSheet + AthleteReportSerializer
```

### Arquitectura vigente

```
GYM_APPApp
├── @State CoachPreferencesStore          ← Phase 30 (nuevo)
│   └── .environment(preferencesStore)   ← inyectado en todo el árbol
│
├── ModelContainer (GYMAppSchemaV1, 16 modelos)
│   └── applyStoreProtection()           ← Phase 29 (seguridad D2)
│
├── MainTabView
│   ├── DashboardView
│   │   ├── DashboardViewModel.load(athletes:checkIns:preferences:)   ← Phase 31
│   │   └── onChange(prefsStore.preferences) → reload()               ← Phase 31
│   │
│   ├── AthleteListView
│   │   └── AthleteRowView [@Environment CoachPreferencesStore]        ← Phase 31
│   │       └── AthleteAlertEvaluator.evaluate(preferences: live)
│   │
│   ├── AthleteDetailView [@Environment CoachPreferencesStore]         ← Phase 31
│   │   ├── overviewViewModel.build(from:preferences:)                 ← Phase 31
│   │   ├── AthleteOverviewSectionView
│   │   └── toolbar Menu
│   │       └── "Generar Reporte" → AthleteReportSheet                 ← Phase 26
│   │           └── ShareLink(AthleteReportSerializer.text(from:))
│   │
│   ├── CheckInDetailView
│   │   └── notesSection
│   │       └── "Editar/Agregar notas" → NotesEditSheet               ← Phase 28
│   │
│   └── SettingsView [@Environment CoachPreferencesStore]             ← Phase 30
│       ├── Steppers (inactividad, tendencias, máx alertas)
│       ├── Toggles (tipos de alerta)
│       ├── Pickers (unidades)
│       └── "Restablecer preferencias"
```

### Domain engines y sus inputs de preferencias
| Engine | Preference keys usados |
|---|---|
| `AthleteAlertEvaluator` | `inactivityThresholdDays`, `trendWindowDays`, `showInactiveAlerts`, `showPhotoAlerts`, `showMetricAlerts` |
| `DashboardFilter.apply()` | `inactivityThresholdDays` |
| `DashboardViewModel.buildAlerts` | `maxAlertsShown` (cap de alertas mostradas) |
| `DashboardViewModel.buildProgressors` | `progressWindowDays` |
| `DashboardViewModel.buildPendingActions` | `inactivityThresholdDays` |

### Tests — estado actual (155/155 pasan)
| Suite | Tests | Estado |
|---|---|---|
| `AutoRecommendationStubTests` | 12 | ✅ pasan (Phase 32) |
| `ProgressPredictionStubTests` | 13 | ✅ pasan (Phase 32) |
| `AthleteAlertEvaluatorTests` | 14 | ✅ pasan |
| `DashboardFilterTests` | 11 | ✅ pasan |
| `AthleteReportSerializerTests` | 10 | ✅ pasan |
| `CheckInComparisonEngineTests` | ~15 | ✅ pasan (sin cambios) |
| `CheckInWorkflowIntegrationTests` | 6 | ✅ pasan (sin cambios) |
| `PhotoLimitsTests` | 10 | ✅ pasan (sin cambios) |
| `OrphanSweepTests` | 5 | ✅ pasan (sin cambios) |
| `FoodMacrosCalculatorTests` | 11 | ✅ pasan (sin cambios) |
| `TimelineBuilderTests` | ~10 | ✅ pasan (sin cambios) |
| `StatisticsEngineTests` | ~20 | ✅ pasan (sin cambios) |

---

## Reglas de arquitectura vigentes (para fases futuras)

1. **ViewModels:** siempre `@MainActor @Observable final class` — sin `ObservableObject`, sin `Combine`, sin `DispatchQueue`
2. **Preferencias:** leer del `CoachPreferencesStore` via `@Environment`, nunca `CoachPreferences.default` en producción
3. **Snapshots:** todo acceso a datos para domain engines pasa por `CheckInSnapshot`, `AthleteSnapshot`, `BodyMetricsSnapshot`
4. **Seguridad:** sin logs de nombres de atletas, datos biométricos, rutas de filesystem, ni internals de NSError
5. **FileProtection:** `completeUnlessOpen` + `isExcludedFromBackup` en cualquier archivo escrito a disco
6. **Tests:** usar `ModelContainer(for: Schema(GYMAppSchemaV1.models), configurations: ModelConfiguration(isStoredInMemoryOnly: true))` para tests con SwiftData
7. **CheckIn init:** `CheckIn(date:)` — sin parámetro `athlete:`. Asignar `ci.athlete = athlete` después de `ctx.insert(ci)`

---

## Regla crítica de Swift 6 descubierta en Phase 32

**Todo `@Suite` struct debe ser `@MainActor` en este proyecto.**

Sin `@MainActor`, llamar `await stub.asyncMethod()` desde un test nonisolated falla con Mach error -308 porque Swift 6 ve las conformancias async como main-actor-isolated (la mayoría de tipos del app module son `@MainActor @Observable`).

**Además:** Los valores default de parámetros se evalúan en contexto nonisolated. Si un default es `Trend = .insufficient` (donde `Trend.insufficient` puede ser inferred como main-actor), cambiarlo a `Trend? = nil` con `?? .insufficient` dentro del cuerpo `@MainActor` corrige el warning.

---

## Próximas fases sugeridas (no implementadas)

- **Phase 33:** `preferredWeightUnit` / `preferredLengthUnit` del store aplicado a la UI — formatear pesos y medidas según la preferencia del coach en todas las vistas
- **Phase 34:** Conectar `AutoRecommendationStub` al `AthleteOverviewViewModel` — mostrar recomendaciones en `AthleteDetailView` bajo la sección Overview
- **Phase 35:** Cobertura de tests para `AthleteReportBuilder` + edge cases de `CheckInComparisonEngine`
- **Phase 36:** `ProgressPredictionStub` expuesto en la UI — sección "Proyecciones" en AthleteDetailView con gráfica de tendencia + predicción
- **Phase 37:** Notification center para alertas críticas (atletas con severidad 3+)
