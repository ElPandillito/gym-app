//
//  AthleteReportSerializer.swift
//  GYM APP
//

import Foundation

enum AthleteReportSerializer {

    static func text(from report: AthleteReport) -> String {
        let fmt = makeDateFormatter()
        let a   = report.athlete
        let s   = report.statistics
        var out: [String] = []

        // ── Encabezado ────────────────────────────────────────
        out += [
            "REPORTE DEL ATLETA",
            String(repeating: "=", count: 44),
            "Nombre:   \(a.name)",
            "Género:   \(a.gender.displayName)",
        ]
        if let age = a.ageYears { out.append("Edad:     \(Int(age)) años") }
        if let h   = a.heightCm { out.append(String(format: "Estatura: %.0f cm", h)) }
        out.append("Generado: \(fmt.string(from: report.generatedAt))")
        out.append("")

        // ── Estadísticas generales ────────────────────────────
        out += [
            "ESTADÍSTICAS GENERALES",
            String(repeating: "-", count: 44),
            "Check-ins registrados: \(s.checkInCount)",
        ]
        if let p = s.period {
            out.append("Período:  \(fmt.string(from: p.start)) – \(fmt.string(from: p.end))")
        }
        if let avg = s.averageDaysBetweenCheckIns {
            out.append(String(format: "Frecuencia promedio: %.0f días entre check-ins", avg))
        }
        out.append("")

        // ── Tendencias ────────────────────────────────────────
        out += [
            "TENDENCIAS (Regresión Lineal OLS)",
            String(repeating: "-", count: 44),
            "Peso:          \(trendLine(s.weightTrend,     unit: "kg"))",
            "% Grasa:       \(trendLine(s.bodyFatTrend,    unit: "%"))",
            "Masa muscular: \(trendLine(s.muscleMassTrend, unit: "kg"))",
            "",
        ]

        // ── Marcas personales ─────────────────────────────────
        out += ["MARCAS PERSONALES", String(repeating: "-", count: 44)]
        var hasRecords = false
        let records: [(String, MetricRecord?)] = [
            ("Menor % grasa",      s.lowestBodyFat),
            ("Mayor % grasa",      s.highestBodyFat),
            ("Menor peso",         s.lowestWeight),
            ("Mayor peso",         s.highestWeight),
            ("Pico masa muscular", s.peakMuscleMass),
        ]
        for (label, record) in records {
            if let r = record {
                out.append("\(label): \(String(format: "%.1f", r.value))  (\(fmt.string(from: r.date)))")
                hasRecords = true
            }
        }
        if !hasRecords { out.append("Sin datos suficientes para marcas personales.") }

        out += ["", String(repeating: "-", count: 44), "Generado por GYM APP"]
        return out.joined(separator: "\n")
    }

    // MARK: - Private

    private static func trendLine(_ trend: Trend, unit: String) -> String {
        let monthly = trend.slope * 30
        switch trend.direction {
        case .rising:       return String(format: "↑ Subiendo  (+%.2f %@/mes)", monthly, unit)
        case .falling:      return String(format: "↓ Bajando   (%.2f %@/mes)",  monthly, unit)
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
