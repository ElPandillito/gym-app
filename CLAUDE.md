# GYM APP — CLAUDE.md
## Contexto maestro para Claude Code (CLI, Desktop, Xcode Extension)

---

## 1. IDENTIDAD DEL PROYECTO

**Nombre:** GYM APP  
**Plataforma:** iOS + macOS (SwiftUI multi-platform)  
**Idioma de UI:** Español (México). Todo texto visible para el usuario va en español.  
**Idioma de código:** Inglés (nombres de variables, funciones, tipos, comentarios técnicos).  
**Propósito:** Herramienta profesional para coaches de fitness. Gestión de atletas, seguimiento de composición corporal, nutrición (alimentos y planes), progreso fotográfico, y reportes analíticos. NO es una app para el atleta final — es para el coach que gestiona múltiples atletas.  
**Estado actual:** Funcional y en producción activa. Cada phase agrega funcionalidad incremental sin romper lo existente.

---

## 2. STACK TÉCNICO

| Componente | Versión / Tecnología |
|------------|----------------------|
| Lenguaje | Swift 6 (modo estricto de concurrencia activo) |
| UI | SwiftUI |
| Persistencia | SwiftData (GYMAppSchemaV1, v1.0.2) |
| Observabilidad | `@Observable` macro (NO `ObservableObject`) |
| Concurrencia | `async/await`, `@MainActor`, `Task` |
| Testing | Swift Testing framework (`@Test`, `@Suite`, `#expect`) |
| Proxy backend | Cloudflare Worker (TypeScript, Wrangler 4.148.0) — INACTIVO |
| Deployment target | iOS 27.0 / macOS (multi-platform) |
| Xcode project | `GYM APP/GYM APP.xcodeproj` |
| Test scheme | `GYM APP` — target `GYM APPTests` |
| Simulator activo | iPhone 18 Pro (id: `314D39D6-4D80-4EF8-83EE-756E6E62FF9D`, iOS 27.0) |

### Swift 6 — Reglas de concurrencia activas
- Todos los ViewModels son `@Observable @MainActor final class`.
- Los servicios puros sin estado son `struct: Sendable`.
- Los protocolos de servicio deben ser conformes a `Sendable` cuando se inyectan en contextos `@MainActor`.
- Los closures capturados en `Task {}` deben ser `@Sendable`.
- `@Attribute(.unique)` en SwiftData para IDs.

---

## 3. ESTRUCTURA DE DIRECTORIOS

```
GYM APP/
├── GYM APP.xcodeproj
├── GYM APP/                          ← Fuentes principales
│   ├── Core/
│   │   ├── AIEngine/                 ← Servicios de IA (ver sección 9 — SUSPENDIDO)
│   │   │   ├── Configuration/        ← AppConfiguration.swift, AIServiceConfiguration.swift
│   │   │   ├── Models/               ← AIServiceError.swift
│   │   │   ├── PromptBuilders/       ← FoodImagePromptBuilder.swift
│   │   │   ├── Protocols/            ← ImageGenerationServiceProtocol.swift
│   │   │   ├── Providers/            ← OpenAIImageProvider.swift (INACTIVO)
│   │   │   └── Stubs/                ← ImageGenerationStub.swift
│   │   ├── CalculationEngine/        ← FoodMacrosCalculator, SkinfoldCalculator
│   │   ├── ComparisonEngine/         ← CheckInComparisonEngine, modelos de comparación
│   │   ├── Domain/                   ← Value types, snapshots (FoodSnapshot, etc.)
│   │   ├── Enums/                    ← Todos los enums del dominio (ver sección 6)
│   │   ├── Models/                   ← SwiftData @Model classes (ver sección 5)
│   │   ├── Persistence/              ← AppSchema.swift (GYMAppSchemaV1)
│   │   ├── ReportEngine/             ← AthleteReportPDFRenderer, serializers JSON/CSV
│   │   ├── Repositories/             ← FoodRepository, + protocolos
│   │   ├── Services/                 ← FoodImageStorageService, + protocolos
│   │   ├── StatisticsEngine/         ← StatisticsEngine, modelos estadísticos
│   │   ├── Timeline/                 ← TimelineBuilder, AthleteTimelineEvent
│   │   └── ValidationEngine/        ← ValidationEngine, Rules, Validators
│   ├── Features/
│   │   ├── Athletes/                 ← Lista, detalle, form, timeline, reportes, predicción
│   │   ├── Calendar/                 ← Calendario de check-ins
│   │   ├── CheckIn/                  ← Workflow completo: métricas, pliegues, circunferencias, fotos, comparación
│   │   ├── Dashboard/                ← Vista resumen con KPIs
│   │   ├── Nutrition/                ← Alimentos, recetas, imágenes, planes, comidas
│   │   └── Settings/                 ← Configuración de la app
│   ├── Infrastructure/
│   │   └── Security/                 ← Secrets.swift (gitignored, openAIAPIKey = nil)
│   ├── Navigation/                   ← MainTabView, router
│   └── Shared/
│       ├── Components/               ← Componentes reutilizables (AsyncImageView, etc.)
│       ├── DesignSystem/
│       │   ├── Components/           ← EmptyStateView, MetricCard, SectionHeader
│       │   └── Tokens/               ← AppSpacing, AppRadius, AppTypography, AppColors, Shadows
│       ├── Extensions/               ← Extensions de tipos stdlib y SwiftUI
│       ├── Helpers/                  ← Utilidades puras
│       ├── Utilities/
│       └── Views/                    ← Views compartidas
├── GYM APPTests/                     ← Suite de tests (Swift Testing)
│   ├── EngineTests/                  ← Tests unitarios de engines y servicios
│   ├── IntegrationTests/             ← Tests de ViewModels con SwiftData en memoria
│   ├── Photo21FTests/                ← Tests de fotos de progreso
│   ├── TestHelpers/                  ← MockURLProtocol, MockFoodImageStorage, etc.
│   └── ValidationTests/
└── proxy/                            ← Cloudflare Worker (INACTIVO)
    ├── src/index.ts                  ← Worker handler (suspendido)
    ├── src/index.test.ts             ← 20 tests Vitest (20/20 PASS)
    └── wrangler.toml                 ← Config Wrangler 4.x con [[ratelimits]]
```

---

## 4. PATRONES DE ARQUITECTURA

### 4.1 MVVM + SwiftData

```swift
// ViewModel — siempre @Observable @MainActor final class
@Observable
@MainActor
final class FooViewModel {
    private(set) var state: FooState = .idle
    private let repository: FooRepositoryProtocol
    private let service: any FooServiceProtocol

    init(context: ModelContext, service: any FooServiceProtocol = FooService()) {
        self.repository = FooRepository(context: context)
        self.service    = service
    }

    func doSomething() async {
        // async/await en @MainActor — no se necesita Task en el interior del VM
    }
}

// View — inyecta ViewModel via .onAppear o @State
struct FooView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var vm: FooViewModel?

    var body: some View {
        ContentView()
            .onAppear {
                if vm == nil {
                    vm = FooViewModel(context: modelContext)
                }
            }
    }
}
```

### 4.2 Repositorios

Los repositorios encapsulan toda interacción con SwiftData. Nunca se accede a `ModelContext` directamente desde un ViewModel — siempre a través de un Repository.

```swift
struct FooRepository: FooRepositoryProtocol {
    private let context: ModelContext
    init(context: ModelContext) { self.context = context }

    func fetch() throws -> [Foo] {
        try context.fetch(FetchDescriptor<Foo>())
    }
}
```

### 4.3 Inyección de dependencias

Los servicios se inyectan por protocolo. Los defaults son los concretos de producción. Nunca se instancian concretos dentro de ViewModels — siempre en el init.

### 4.4 Snapshots / Value types

Para pasar datos de `@Model` a servicios que no deben tener acceso al ModelContext, se usan snapshots:

```swift
// Domain value type — Sendable, sin dependencias de SwiftData
struct FoodSnapshot: Sendable {
    let id: UUID
    let name: String
    let kind: FoodKind
    // ...
}

// Generado desde el @Model
extension Food {
    func snapshot() -> FoodSnapshot { FoodSnapshot(id: id, name: name, kind: kind) }
}
```

### 4.5 Enums con rawValue String en SwiftData

Para evitar roturas de migración cuando se añaden casos, todos los enums persistidos en @Model se almacenan como `String` y se acceden via computed property:

```swift
// En @Model:
var kindRaw: String

// Computed property (no almacenada):
var kind: FoodKind {
    get { FoodKind(rawValue: kindRaw) ?? .ingredient }
    set { kindRaw = newValue.rawValue }
}
```

---

## 5. MODELOS SWIFTDATA (GYMAppSchemaV1 v1.0.2)

### Modelo central: Athlete
```
Athlete
├── id: UUID @Attribute(.unique)
├── name: String
├── birthDate: Date?
├── height: Double? (centímetros)
├── gender: Gender (rawValue String)
├── phase: AthletePhase (via phaseRaw: String)
├── profilePhotoPath: String?
├── createdAt / updatedAt: Date
├── checkIns: [CheckIn] @Relationship(deleteRule: .cascade)
└── nutritionPlans: [NutritionPlan] @Relationship(deleteRule: .cascade)
```

### CheckIn
```
CheckIn
├── id, athleteID, date, notes
├── bodyMetrics: BodyMetrics? @Relationship(deleteRule: .cascade)
├── skinfoldMeasurements: SkinfoldMeasurements?
├── circumferenceMeasurements: CircumferenceMeasurements?
├── isAKBreadthsMeasurements, ISAKLengthsMeasurements
├── progressPhotos: [ProgressPhoto]
├── aiBodyFatAssessment: AIBodyFatAssessment?
└── coachNotes: [CoachNote]
```

### Food
```
Food
├── id, name, kindRaw, categoryRaw, sourceRaw
├── calories, protein, carbohydrates, fat, fiber (Double? per 100g)
├── servingSize, servingUnitRaw, brand, tags, servings
├── externalID, barcode (para futura integración con APIs externas)
├── image: FoodImage? @Relationship(deleteRule: .cascade)
└── ingredients: [RecipeIngredient] @Relationship(deleteRule: .cascade)
```

### FoodImage
```
FoodImage
├── id, originalPath, thumbnailPath (filesystem relative paths)
├── isProcessed: Bool
├── createdAt: Date
├── imageOriginRaw: String → FoodImageOrigin (.userUploaded, .aiGenerated, .catalog, .placeholder)
├── aiGenerationStateRaw: String? → FoodImageGenerationState (.pending, .generating, .ready, .failed)
└── promptUsed: String? (prompt enviado al proveedor de IA)
```

### Nutrition (relaciones)
```
NutritionPlan → [Meal] → [MealItem] → Food
RecipeIngredient → recipe: Food, ingredient: Food
```

### Reglas de migración SwiftData
- **NUNCA** borrar el store para recuperarse de un error de schema.
- Campo `Optional` nuevo → lightweight migration, incrementar patch en `GYMAppSchemaV1.versionIdentifier`.
- Campo no-opcional, renombrado o eliminado → nueva versión `GYMAppSchemaV2` + `GYMAppMigrationPlan`.
- Ver `Core/Persistence/AppSchema.swift` para historial completo.

---

## 6. ENUMS DEL DOMINIO

```swift
// Core/Enums/ — todos: String rawValue, Codable, CaseIterable, Sendable

enum Gender:               male, female, other
enum AthletePhase:         offSeason, preContest, contest, recovery
enum AnthropometryProfile: standard, isak, extended
enum PlicometryMethod:     jackson3, jackson7, durnin, faulkner, slaughter
enum PoseType:             front, back, side, custom

enum FoodKind:    ingredient, preparedFood
enum FoodSource:  coach, system   // "system" = preloaded, no borrar
enum FoodUnit:    grams, ml, unit, tablespoon, teaspoon, cup
enum FoodCategory: proteinas, carbohidratos, grasas, verduras, frutas, lacteos,
                   leguminosas, cereales, bebidas, condimentos, otros

enum FoodImageOrigin:          userUploaded, aiGenerated, catalog, placeholder
enum FoodImageGenerationState: pending, generating, ready, failed
```

---

## 7. SISTEMA DE DISEÑO

### Espaciado (grilla de 4pt)
```swift
AppSpacing.xxs = 2    AppSpacing.xs = 4     AppSpacing.sm = 8
AppSpacing.md = 12    AppSpacing.base = 16  AppSpacing.lg = 20
AppSpacing.xl = 24    AppSpacing.xxl = 32   AppSpacing.xxxl = 48
```

### Radios
```swift
AppRadius.sm = 6    AppRadius.md = 10    AppRadius.lg = 14
AppRadius.xl = 20   AppRadius.full = 999
```

### Tipografía (tokens semánticos)
```swift
AppTypography.metricValue  = .title3.bold().monospacedDigit()
AppTypography.metricLabel  = .footnote
AppTypography.kpiValue     = .title.heavy().monospacedDigit()
AppTypography.kpiLabel     = .caption.medium()
AppTypography.sectionHeader = .footnote.semibold()
```

### Uso obligatorio
- Todos los paddings, spacings y corner radii deben usar los tokens de `AppSpacing` y `AppRadius`.
- No usar números mágicos de layout: `padding(16)` → `padding(AppSpacing.base)`.
- Componentes reutilizables: `EmptyStateView`, `MetricCard`, `SectionHeader` en `Shared/DesignSystem/Components/`.

---

## 8. CONVENCIONES DE CÓDIGO

### Reglas generales
- **Sin comentarios** salvo que el WHY sea no obvio: una restricción oculta, un invariante sutil, un workaround documentado.
- **Sin docstrings de múltiples párrafos**. Máximo una línea breve si el propósito no se deduce del nombre.
- **Sin manejo de errores para escenarios imposibles**. Solo en boundaries externos (input usuario, red, disco).
- **Sin feature flags** para compatibilidad hacia atrás. Cambiar el código directamente.
- **Sin abstracciones prematuras**. Tres líneas similares son mejores que una abstracción innecesaria.
- **Sin backward-compatibility hacks** (renamed unused _vars, re-export types, `// removed` comments).

### Naming
- ViewModels: `NombreViewModel` (e.g., `FoodImageViewModel`, `AthleteListViewModel`)
- Repositorios: `NombreRepository` + protocolo `NombreRepositoryProtocol`
- Servicios: `NombreService` + protocolo `NombreServiceProtocol`
- Stubs de test: `MockNombre` o `NombreStub`
- Enums de estado de UI: definidos dentro del ViewModel que los usa

### SwiftUI
- `.onAppear { if vm == nil { vm = ViewModel(...) } }` para inicialización lazy de ViewModels.
- `@Environment(\.modelContext) private var modelContext` para acceso al contexto.
- `@Query` solo para queries simples directamente en View; lógica compleja en Repository.
- `#Preview` con datos de ejemplo para cada View pública.

### Tests (Swift Testing)
```swift
@Suite("NombreComponente")
struct NombreComponenteTests {

    @Test("descripción en español del comportamiento esperado")
    func nombreEnCamelCase_escenario_resultadoEsperado() async throws {
        // arrange
        // act
        // assert con #expect / Issue.record
    }
}
```
- Tests unitarios: sin red real, sin disco real. Mock todo lo externo.
- Tests de integración de ViewModel: `ModelContainer(isStoredInMemoryOnly: true)`.
- **NUNCA** modificar un test para hacerlo pasar. Investigar la causa raíz.

---

## 9. MOTOR DE IA — ESTADO: SUSPENDIDO

### Estado actual (Phase 47D.2 — aprobada)

```
AppConfiguration.imageGenerationProxyURL = nil         ← gate principal
AppConfiguration.imageGenerationProxyToken = "gymapp-dev-placeholder-replace-before-deploy"
AIServiceConfiguration.makeImageGenerator()
  → proxyURL == nil
  → Secrets.openAIAPIKey == nil
  → ImageGenerationStub(behavior: .failure(.unavailable))  ← falla limpiamente
```

### Consecuencias
- El botón "Generar con IA" en `FoodDetailView` está **oculto** mientras `imageGenerationProxyURL == nil`.
- Ningún byte de imagen se escribe al disco por la ruta de generación.
- Ningún `FoodImage` falso se crea.
- El proxy Worker de Cloudflare existe en `proxy/` pero **no está desplegado**.

### Para REACTIVAR en el futuro
1. Desplegar el Worker: `cd proxy && npx wrangler deploy`
2. Configurar secretos: `wrangler secret put OPENAI_API_KEY` y `wrangler secret put APP_TOKEN`
3. Actualizar `AppConfiguration.imageGenerationProxyURL` con la URL del Worker
4. Actualizar `AppConfiguration.imageGenerationProxyToken` con el mismo valor que `APP_TOKEN`
5. Cambiar `AIServiceConfiguration.makeImageGenerator()` para quitar el override de `.failure`

### LO QUE NO DEBES HACER
- **NO** cambiar el stub de vuelta a `.success`.
- **NO** poner un token de producción real en `AppConfiguration.imageGenerationProxyToken`.
- **NO** desplegar el Worker sin autorización explícita del usuario.
- **NO** configurar secretos en Cloudflare sin autorización explícita.
- **NO** eliminar los archivos de proxy — son infraestructura dormida.

---

## 10. PROXY CLOUDFLARE (proxy/)

### Estado
- Worker `gym-app-image-proxy`: **NO existe** en Cloudflare (nunca se desplegó).
- `workers.dev`: **NO registrado**.
- Secretos: **NO configurados**.

### Configuración
```toml
# wrangler.toml
name = "gym-app-image-proxy"
compatibility_date = "2025-01-01"

[[ratelimits]]
name = "RATE_LIMITER"
namespace_id = "47001"
simple = { limit = 10, period = 60 }   # por ubicación de Cloudflare, no global
```

### Tests del Worker
- 20/20 tests Vitest pasando en `proxy/src/index.test.ts`.
- Para ejecutar: `cd proxy && npm test`
- Para verificar tipos: `cd proxy && npm run typecheck`

### LO QUE NO DEBES HACER en proxy/
- **NO** ejecutar `wrangler deploy`, `wrangler versions deploy`, `wrangler secret put`.
- **NO** registrar `workers.dev`.
- **NO** modificar el Worker salvo que haya una inconsistencia técnica real documentada.

---

## 11. INVENTARIO DE FEATURES

### ✅ Implementados y funcionales

| Feature | Módulo | Descripción |
|---------|--------|-------------|
| Gestión de atletas | `Features/Athletes/` | CRUD, fases, métricas actuales, notas, alertas |
| Timeline de atleta | `Features/Athletes/AthleteTimelineView` | Historial cronológico de check-ins |
| Predicción de progreso | `Features/Athletes/ProgressPredictionCard` | Proyección estadística de métricas |
| Reporte PDF | `Features/Athletes/AthleteReportSheet` | Exportación PDF del atleta |
| Exportación JSON/CSV | `Core/ReportEngine/` | Serialización de reportes |
| Check-in completo | `Features/CheckIn/` | Métricas corporales, pliegues, circunferencias, ISAK |
| Pliegues cutáneos | `Features/CheckIn/SkinfoldMeasurementsFormView` | Múltiples métodos de plicometría |
| Comparación de check-ins | `Features/CheckIn/ComparisonView` | Delta entre dos check-ins |
| Fotos de progreso | `Features/CheckIn/ProgressPhotoForm` | Captura y visualización por pose |
| Evaluación IA grasa corporal | `Features/CheckIn/AIBodyFatAssessmentCard` | IA stub activo |
| Dashboard | `Features/Dashboard/` | KPIs y resumen global |
| Alimentos e ingredientes | `Features/Nutrition/` | CRUD, búsqueda, categorización |
| Recetas (platillos preparados) | `Features/Nutrition/` | Composición con ingredientes, macros calculados |
| Imágenes de alimentos | `Features/Nutrition/FoodDetailView` | Upload de usuario, placeholder por categoría |
| Planes de nutrición | `Features/Nutrition/` | Planes con comidas y alimentos |
| Calendario | `Features/Calendar/` | Vista de check-ins por fecha |

### ⛔ Suspendidos

| Feature | Estado | Condición de reactivación |
|---------|--------|--------------------------|
| Generación de imágenes con OpenAI | Suspendido en Phase 47D | `imageGenerationProxyURL != nil` |

### 🔜 Próximos (no implementados aún)

| Phase | Feature |
|-------|---------|
| 48A | Investigación de proveedor de imágenes licenciadas (DECISIÓN PENDIENTE) |
| 48 | Catálogo de imágenes licenciadas para alimentos (`FoodImageOrigin.catalog`) |

---

## 12. IMÁGENES DE ALIMENTOS — DECISIONES PENDIENTES

`FoodImageOrigin.catalog` está disponible en el modelo pero sin implementación de catálogo.

**NO implementar aún:**
- Scraping de imágenes
- Descarga masiva de internet
- Integración con proveedores de imágenes externos
- Nuevo campo `sourceURL` en `FoodImage`
- Catálogo remoto / CDN

**POR QUÉ:** La decisión de proveedor/licencia está pendiente. Agregar `sourceURL` o infraestructura de catálogo antes de elegir el modelo de distribución genera deuda técnica.

**Cuándo implementar:** Después de Phase 48A (decisión de fuente y licencia de imágenes).

---

## 13. REGLAS CRÍTICAS — SIEMPRE SEGUIR

1. **Idioma de UI:** Todo texto visible = español. Todo código = inglés.
2. **Sin secretos en código:** `Secrets.swift` es gitignored por razón. `AppConfiguration` no debe tener tokens de producción.
3. **Sin despliegues de Cloudflare** salvo autorización explícita.
4. **Sin commits ni push** salvo instrucción explícita.
5. **Tests no se modifican para hacerlos pasar.** Si falla un test, investigar la causa.
6. **SwiftData migrations:** Nunca borrar el store. Ver reglas en `AppSchema.swift`.
7. **AI stub permanece en `.failure(.unavailable)`** mientras `imageGenerationProxyURL == nil`.
8. **FoodSource.system** = alimentos del sistema que NO deben borrarse (protección en repositorio).
9. **Enums en SwiftData:** Siempre almacenar como `String` rawValue + computed property. Nunca `@Attribute` de tipo enum directamente.
10. **Design tokens obligatorios:** Todo spacing/radius usa `AppSpacing`/`AppRadius`. Cero números mágicos de layout.

---

## 14. COMANDOS DE TESTING

```bash
# Suite completa
xcodebuild test \
  -scheme "GYM APP" \
  -destination "platform=iOS Simulator,id=314D39D6-4D80-4EF8-83EE-756E6E62FF9D"

# Solo tests de imagen/nutrición
xcodebuild test \
  -scheme "GYM APP" \
  -destination "platform=iOS Simulator,id=314D39D6-4D80-4EF8-83EE-756E6E62FF9D" \
  -only-testing:"GYM APPTests/EngineTests/BackendImageGenerationServiceTests" \
  -only-testing:"GYM APPTests/IntegrationTests/FoodImageViewModelTests"

# Tests del proxy Worker
cd proxy && npm test
cd proxy && npm run typecheck
```

---

## 15. ESTADO DE TESTS (baseline post-Phase 47D.2)

| Suite | Tests | Estado |
|-------|-------|--------|
| BackendImageGenerationServiceTests | 14 | ✅ |
| ImageGenerationStubTests | 13 | ✅ |
| RealImageGenerationServiceTests | 13 | ✅ |
| FoodImageViewModelTests | 11 | ✅ |
| FoodImageRepositoryTests | 11 | ✅ |
| Suite completa (GYM APPTests) | 370 | ✅ |
| Proxy Worker (Vitest) | 20 | ✅ |

**Regla:** Al terminar cualquier phase, la suite completa debe estar en 370/370 (o más si se agregan tests).

---

## 16. GIT — RESTRICCIONES

El agente **NO debe ejecutar** sin instrucción explícita:
- `git commit`
- `git push` / `git push --force`
- `git reset --hard`
- `git clean -f`
- `git checkout .` / `git restore .`

Antes de cualquier operación que descarte cambios: `git status` primero.

El usuario aprueba todos los commits y pushes.

---

*Este archivo se mantiene actualizado al final de cada phase completada.*  
*Última actualización: Phase 47D.2 — 2026-10-07*
