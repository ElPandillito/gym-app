//
//  AthleteReportSerializer.swift
//  GYM APP
//

import Foundation

enum AthleteReportSerializer {

    static func text(from report: AthleteReport) -> String {
        text(from: report, preferences: .default)
    }

    static func text(from report: AthleteReport, preferences: CoachPreferences) -> String {
        let fmt     = AppUnitFormatter(preferences: preferences)
        let dateFmt = makeDateFormatter()
        let a       = report.athlete
        let s       = report.statistics
        var out: [String] = []

        // ── Encabezado ────────────────────────────────────────
        out += [
            "REPORTE DEL ATLETA",
            String(repeating: "=", count: 44),
            "Nombre:   \(a.name)",
            "Género:   \(a.gender.displayName)",
        ]
        if let age = a.ageYears { out.append("Edad:     \(Int(age)) años") }
        if let h   = a.heightCm { out.append("Estatura: \(fmt.height(h))") }
        out.append("Generado: \(dateFmt.string(from: report.generatedAt))")
        out.append("")

        // ── Estadísticas generales ────────────────────────────
        out += [
            "ESTADÍSTICAS GENERALES",
            String(repeating: "-", count: 44),
            "Check-ins registrados: \(s.checkInCount)",
        ]
        if let p = s.period {
            out.append("Período:  \(dateFmt.string(from: p.start)) – \(dateFmt.string(from: p.end))")
        }
        if let avg = s.averageDaysBetweenCheckIns {
            out.append(String(format: "Frecuencia promedio: %.0f días entre check-ins", avg))
        }
        out.append("")

        // ── Tendencias ────────────────────────────────────────
        out += [
            "TENDENCIAS (Regresión Lineal OLS)",
            String(repeating: "-", count: 44),
            "Peso:          \(trendLine(s.weightTrend,     slopeMonthly: fmt.convertedWeight(s.weightTrend.slope * 30),     unit: fmt.weightLabel))",
            "% Grasa:       \(trendLine(s.bodyFatTrend,    slopeMonthly: s.bodyFatTrend.slope * 30,                          unit: "%"))",
            "Masa muscular: \(trendLine(s.muscleMassTrend, slopeMonthly: fmt.convertedWeight(s.muscleMassTrend.slope * 30), unit: fmt.weightLabel))",
            "",
        ]

        // ── Marcas personales ─────────────────────────────────
        out += ["MARCAS PERSONALES", String(repeating: "-", count: 44)]
        var hasRecords = false
        let records: [(String, MetricRecord?, Bool)] = [
            ("Menor % grasa",      s.lowestBodyFat,    false),
            ("Mayor % grasa",      s.highestBodyFat,   false),
            ("Menor peso",         s.lowestWeight,     true),
            ("Mayor peso",         s.highestWeight,    true),
            ("Pico masa muscular", s.peakMuscleMass,   true),
        ]
        for (label, record, isWeight) in records {
            if let r = record {
                let valueStr = isWeight
                    ? String(format: "%.1f \(fmt.weightLabel)", fmt.convertedWeight(r.value))
                    : String(format: "%.1f", r.value)
                out.append("\(label): \(valueStr)  (\(dateFmt.string(from: r.date)))")
                hasRecords = true
            }
        }
        if !hasRecords { out.append("Sin datos suficientes para marcas personales.") }

        out += ["", String(repeating: "-", count: 44), "Generado por GYM APP"]
        return out.joined(separator: "\n")
    }

    // MARK: - Private

    private static func trendLine(_ trend: Trend, slopeMonthly: Double, unit: String) -> String {
        switch trend.direction {
        case .rising:       return String(format: "↑ Subiendo  (+%.2f %@/mes)", slopeMonthly, unit)
        case .falling:      return String(format: "↓ Bajando   (%.2f %@/mes)",  slopeMonthly, unit)
        case .flat:         return "→ Estable"
        case .insufficient: return "— Datos insuficientes"
        }
    }

    private static func makeDateFormatter() -> DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.locale    = Locale(identifier: "es_MX")
        return f
    }
}
