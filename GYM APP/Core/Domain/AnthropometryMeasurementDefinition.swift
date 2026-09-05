//
//  AnthropometryMeasurementDefinition.swift
//  GYM APP
//
//  Centralized ISAK anthropometry measurement catalog.
//  Sources:
//    • isak.global/FormationSystem/AccreditationScheme (counts confirmed 2026-08-29)
//    • Marfell-Jones, Olds, Stewart & Carter (2006). International Standards for
//      Anthropometric Assessment. ISAK. (measurement names and anatomical descriptions)
//
//  IMPORTANT — anatomical precision:
//  • suprailiac (existing generic field in SkinfoldMeasurements) ≠ ISAK supraspinale
//  • ISAK requires both iliac_crest AND supraspinale as separate sites
//  • Do NOT silently map the existing `suprailiac` field to either ISAK site

import Foundation

// MARK: - Category

enum AnthropometryCategory: String, Codable, CaseIterable, Sendable {
    case base        // Body mass, stature, sitting height, arm span
    case skinfold    // Skinfold sites in mm
    case girth       // Circumference/girth in cm
    case length      // Segment lengths in cm
    case height      // Segment heights from floor in cm
    case breadth     // Biepicondylar / transverse widths in cm
    case depth       // Anteroposterior diameters in cm

    var displayName: String {
        switch self {
        case .base:     return "Medidas Base"
        case .skinfold: return "Pliegues Cutáneos"
        case .girth:    return "Perímetros"
        case .length:   return "Longitudes"
        case .height:   return "Alturas"
        case .breadth:  return "Diámetros"
        case .depth:    return "Profundidades"
        }
    }

    var icon: String {
        switch self {
        case .base:     return "scalemass.fill"
        case .skinfold: return "ruler.fill"
        case .girth:    return "arrow.left.and.right.circle.fill"
        case .length:   return "arrow.up.and.down.circle"
        case .height:   return "arrow.up.circle.fill"
        case .breadth:  return "arrow.left.and.right"
        case .depth:    return "circle.dotted"
        }
    }
}

// MARK: - Unit

enum AnthropometryUnit: String, Sendable {
    case kilograms   = "kg"
    case centimeters = "cm"
    case millimeters = "mm"
}

// MARK: - Definition

/// Immutable descriptor for a single anthropometric measurement site or dimension.
/// `id` values are stable snake_case identifiers — do NOT rename them after data is written.
struct AnthropometryMeasurementDefinition: Identifiable, Sendable {
    let id: String                          // stable snake_case
    let spanishName: String                 // UI label (Spanish)
    let canonicalName: String               // English ISAK term
    let category: AnthropometryCategory
    let unit: AnthropometryUnit
    let profiles: Set<AnthropometryProfile> // which profiles include this measurement
    let sortOrder: Int
}

// MARK: - Catalog

enum AnthropometryMeasurementCatalog {

    /// All definitions for a given profile, sorted by sortOrder.
    static func definitions(for profile: AnthropometryProfile) -> [AnthropometryMeasurementDefinition] {
        all.filter { $0.profiles.contains(profile) }
           .sorted { $0.sortOrder < $1.sortOrder }
    }

    /// All definitions for a given profile and category.
    static func definitions(
        for profile: AnthropometryProfile,
        category: AnthropometryCategory
    ) -> [AnthropometryMeasurementDefinition] {
        definitions(for: profile).filter { $0.category == category }
    }

    static let all: [AnthropometryMeasurementDefinition] = base + skinfolds + girths + breadthsAndDepths + lengthsAndHeights

    // MARK: - Base measurements (4)
    // Level 1 and Level 2. Body mass / stature also present in standard profile.

    private static let base: [AnthropometryMeasurementDefinition] = [
        .init(id: "body_mass",
              spanishName: "Masa corporal",
              canonicalName: "Body mass",
              category: .base, unit: .kilograms,
              profiles: [.standard, .isakLevel1, .isakLevel2], sortOrder: 1),
        .init(id: "stature",
              spanishName: "Talla (estatura de pie)",
              canonicalName: "Stature",
              category: .base, unit: .centimeters,
              profiles: [.standard, .isakLevel1, .isakLevel2], sortOrder: 2),
        .init(id: "sitting_height",
              spanishName: "Talla sentada",
              canonicalName: "Sitting height",
              category: .base, unit: .centimeters,
              profiles: [.isakLevel1, .isakLevel2], sortOrder: 3),
        .init(id: "arm_span",
              spanishName: "Envergadura",
              canonicalName: "Arm span",
              category: .base, unit: .centimeters,
              profiles: [.isakLevel1, .isakLevel2], sortOrder: 4),
    ]

    // MARK: - Skinfolds (8) — same for Level 1 and Level 2
    // NOTE on supraspinale vs suprailiac:
    //   ISAK supraspinale site = intersection of line from ASIS to anterior axillary fold.
    //   Generic "suprailiac" (used in JP and Parrillo in this project) ≠ ISAK supraspinale.
    //   ISAK also requires a SEPARATE iliac crest site (superior to the crest, oblique fold).
    //   Both are represented here and stored in new fields added to SkinfoldMeasurements.

    private static let skinfolds: [AnthropometryMeasurementDefinition] = [
        .init(id: "sf_triceps",
              spanishName: "Tríceps",
              canonicalName: "Triceps skinfold",
              category: .skinfold, unit: .millimeters,
              profiles: [.isakLevel1, .isakLevel2], sortOrder: 10),
        .init(id: "sf_subscapular",
              spanishName: "Subescapular",
              canonicalName: "Subscapular skinfold",
              category: .skinfold, unit: .millimeters,
              profiles: [.isakLevel1, .isakLevel2], sortOrder: 11),
        .init(id: "sf_biceps",
              spanishName: "Bíceps",
              canonicalName: "Biceps skinfold",
              category: .skinfold, unit: .millimeters,
              profiles: [.isakLevel1, .isakLevel2], sortOrder: 12),
        .init(id: "sf_iliac_crest",
              spanishName: "Cresta ilíaca",
              canonicalName: "Iliac crest skinfold",
              category: .skinfold, unit: .millimeters,
              profiles: [.isakLevel1, .isakLevel2], sortOrder: 13),
        .init(id: "sf_supraspinale",
              spanishName: "Supraespinal",
              canonicalName: "Supraspinale skinfold",
              category: .skinfold, unit: .millimeters,
              profiles: [.isakLevel1, .isakLevel2], sortOrder: 14),
        .init(id: "sf_abdominal",
              spanishName: "Abdominal",
              canonicalName: "Abdominal skinfold",
              category: .skinfold, unit: .millimeters,
              profiles: [.isakLevel1, .isakLevel2], sortOrder: 15),
        .init(id: "sf_front_thigh",
              spanishName: "Muslo anterior",
              canonicalName: "Front thigh skinfold",
              category: .skinfold, unit: .millimeters,
              profiles: [.isakLevel1, .isakLevel2], sortOrder: 16),
        .init(id: "sf_medial_calf",
              spanishName: "Pantorrilla medial",
              canonicalName: "Medial calf skinfold",
              category: .skinfold, unit: .millimeters,
              profiles: [.isakLevel1, .isakLevel2], sortOrder: 17),
    ]

    // MARK: - Girths (6 Level 1 + 7 additional Level 2 = 13 total)

    private static let girths: [AnthropometryMeasurementDefinition] = [
        // Level 1 (6)
        .init(id: "g_arm_relaxed",
              spanishName: "Brazo relajado",
              canonicalName: "Arm girth (relaxed)",
              category: .girth, unit: .centimeters,
              profiles: [.isakLevel1, .isakLevel2], sortOrder: 20),
        .init(id: "g_arm_flexed",
              spanishName: "Brazo contraído (máx.)",
              canonicalName: "Arm girth (flexed and tensed)",
              category: .girth, unit: .centimeters,
              profiles: [.isakLevel1, .isakLevel2], sortOrder: 21),
        .init(id: "g_waist",
              spanishName: "Cintura (mínima)",
              canonicalName: "Waist girth (minimum)",
              category: .girth, unit: .centimeters,
              profiles: [.isakLevel1, .isakLevel2], sortOrder: 22),
        .init(id: "g_hip",
              spanishName: "Cadera / Glúteos (máx.)",
              canonicalName: "Hip (gluteal) girth",
              category: .girth, unit: .centimeters,
              profiles: [.isakLevel1, .isakLevel2], sortOrder: 23),
        .init(id: "g_thigh_proximal",
              spanishName: "Muslo proximal",
              canonicalName: "Thigh girth (1 cm below gluteal fold)",
              category: .girth, unit: .centimeters,
              profiles: [.isakLevel1, .isakLevel2], sortOrder: 24),
        .init(id: "g_calf_max",
              spanishName: "Pantorrilla (máxima)",
              canonicalName: "Calf girth (maximum)",
              category: .girth, unit: .centimeters,
              profiles: [.isakLevel1, .isakLevel2], sortOrder: 25),
        // Level 2 additional (7)
        .init(id: "g_head",
              spanishName: "Perímetro cefálico",
              canonicalName: "Head girth (maximum)",
              category: .girth, unit: .centimeters,
              profiles: [.isakLevel2], sortOrder: 26),
        .init(id: "g_neck",
              spanishName: "Cuello",
              canonicalName: "Neck girth (minimum)",
              category: .girth, unit: .centimeters,
              profiles: [.isakLevel2], sortOrder: 27),
        .init(id: "g_chest",
              spanishName: "Tórax mesoesternal",
              canonicalName: "Chest girth (mesosternal)",
              category: .girth, unit: .centimeters,
              profiles: [.isakLevel2], sortOrder: 28),
        .init(id: "g_wrist",
              spanishName: "Muñeca",
              canonicalName: "Wrist girth (minimum)",
              category: .girth, unit: .centimeters,
              profiles: [.isakLevel2], sortOrder: 29),
        .init(id: "g_ankle",
              spanishName: "Tobillo",
              canonicalName: "Ankle girth (minimum)",
              category: .girth, unit: .centimeters,
              profiles: [.isakLevel2], sortOrder: 30),
        .init(id: "g_mid_thigh",
              spanishName: "Muslo medio",
              canonicalName: "Thigh girth (mid)",
              category: .girth, unit: .centimeters,
              profiles: [.isakLevel2], sortOrder: 31),
        .init(id: "g_forearm_max",
              spanishName: "Antebrazo máximo",
              canonicalName: "Forearm girth (maximum)",
              category: .girth, unit: .centimeters,
              profiles: [.isakLevel2], sortOrder: 32),
    ]

    // MARK: - Breadths and Depths (3 Level 1 + 6 Level 2 = 9 total)
    // NOTE: The third Level 1 breadth (foot breadth, id: "b_foot") is consistent with
    // published ISAK accreditation course materials. Verify against the physical ISAK manual
    // (Marfell-Jones et al., 2006) for definitive confirmation before professional accreditation use.

    private static let breadthsAndDepths: [AnthropometryMeasurementDefinition] = [
        // Level 1 (3)
        .init(id: "b_humerus",
              spanishName: "Diám. biepicondilar húmero",
              canonicalName: "Biepicondylar humerus breadth",
              category: .breadth, unit: .centimeters,
              profiles: [.isakLevel1, .isakLevel2], sortOrder: 40),
        .init(id: "b_femur",
              spanishName: "Diám. biepicondilar fémur",
              canonicalName: "Biepicondylar femur breadth",
              category: .breadth, unit: .centimeters,
              profiles: [.isakLevel1, .isakLevel2], sortOrder: 41),
        .init(id: "b_foot",
              spanishName: "Anchura del pie",
              canonicalName: "Foot breadth",
              category: .breadth, unit: .centimeters,
              profiles: [.isakLevel1, .isakLevel2], sortOrder: 42),
        // Level 2 additional (6)
        .init(id: "b_biacromial",
              spanishName: "Diám. biacromial",
              canonicalName: "Biacromial breadth",
              category: .breadth, unit: .centimeters,
              profiles: [.isakLevel2], sortOrder: 43),
        .init(id: "b_bicristal",
              spanishName: "Diám. bicristal",
              canonicalName: "Bicristal (biiliac) breadth",
              category: .breadth, unit: .centimeters,
              profiles: [.isakLevel2], sortOrder: 44),
        .init(id: "b_chest_transverse",
              spanishName: "Diám. torácico transverso",
              canonicalName: "Chest transverse breadth",
              category: .breadth, unit: .centimeters,
              profiles: [.isakLevel2], sortOrder: 45),
        .init(id: "d_chest_ap",
              spanishName: "Prof. torácica anteroposterior",
              canonicalName: "Chest depth (anteroposterior)",
              category: .depth, unit: .centimeters,
              profiles: [.isakLevel2], sortOrder: 46),
        .init(id: "b_ankle",
              spanishName: "Diám. biepicondilar tobillo",
              canonicalName: "Biepicondylar ankle breadth",
              category: .breadth, unit: .centimeters,
              profiles: [.isakLevel2], sortOrder: 47),
        .init(id: "b_wrist",
              spanishName: "Diám. biepicondilar muñeca",
              canonicalName: "Biepicondylar wrist breadth",
              category: .breadth, unit: .centimeters,
              profiles: [.isakLevel2], sortOrder: 48),
    ]

    // MARK: - Lengths and Heights (9) — Level 2 only

    private static let lengthsAndHeights: [AnthropometryMeasurementDefinition] = [
        .init(id: "l_acromiale_radiale",
              spanishName: "Long. acromial-radial",
              canonicalName: "Acromiale-radiale length",
              category: .length, unit: .centimeters,
              profiles: [.isakLevel2], sortOrder: 50),
        .init(id: "l_radiale_stylion",
              spanishName: "Long. radial-estilión",
              canonicalName: "Radiale-stylion length",
              category: .length, unit: .centimeters,
              profiles: [.isakLevel2], sortOrder: 51),
        .init(id: "l_midstylion_dactylion",
              spanishName: "Long. medioestilión-dactilión",
              canonicalName: "Midstylion-dactylion length",
              category: .length, unit: .centimeters,
              profiles: [.isakLevel2], sortOrder: 52),
        .init(id: "h_iliospinale",
              spanishName: "Altura ilioespinal",
              canonicalName: "Iliospinale height",
              category: .height, unit: .centimeters,
              profiles: [.isakLevel2], sortOrder: 53),
        .init(id: "h_trochanterion",
              spanishName: "Altura trocantérea",
              canonicalName: "Trochanterion height",
              category: .height, unit: .centimeters,
              profiles: [.isakLevel2], sortOrder: 54),
        .init(id: "l_troch_tib_lat",
              spanishName: "Long. trocánterea-tibial lat.",
              canonicalName: "Trochanterion-tibiale laterale length",
              category: .length, unit: .centimeters,
              profiles: [.isakLevel2], sortOrder: 55),
        .init(id: "h_tibiale_lat",
              spanishName: "Altura tibial lateral",
              canonicalName: "Tibiale laterale height",
              category: .height, unit: .centimeters,
              profiles: [.isakLevel2], sortOrder: 56),
        .init(id: "l_tib_sphyrion",
              spanishName: "Long. tibial lat.-sfirión tibial",
              canonicalName: "Tibiale laterale-sphyrion tibiale length",
              category: .length, unit: .centimeters,
              profiles: [.isakLevel2], sortOrder: 57),
        .init(id: "l_foot",
              spanishName: "Longitud del pie",
              canonicalName: "Foot length",
              category: .length, unit: .centimeters,
              profiles: [.isakLevel2], sortOrder: 58),
    ]
}
