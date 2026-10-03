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

    // MARK: - JSON

    /// Serializes the full `AthleteReport` domain model to deterministic UTF-8 JSON.
    /// Reuses `AthleteReport`'s own `Encodable` conformance — no parallel JSON model.
    /// Keys are sorted and dates use ISO 8601 for a stable, machine-consumable output.
    static func json(from report: AthleteReport) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(report)
    }

    // MARK: - CSV

    /// Serializes the report to RFC 4180-compliant UTF-8 CSV.
    /// Outputs raw SI units (kg, %, cm) for machine interoperability.
    /// Optional fields that have no data are omitted entirely.
    static func csv(from report: AthleteReport) -> String {
        let a = report.athlete
        let s = report.statistics

        var rows: [(key: String, value: String, unit: String)] = []

        // ── Athlete ──────────────────────────────────────────
        rows.append(("athlete.name",    a.name,                      ""))
        rows.append(("athlete.gender",  a.gender.displayName,        ""))
        if let age = a.ageYears { rows.append(("athlete.age_years",  csvDbl(age, 1),  "years")) }
        if let h   = a.heightCm { rows.append(("athlete.height_cm",  csvDbl(h, 1),    "cm")) }
        rows.append(("report.generated_at", isoDay(report.generatedAt), ""))

        // ── Statistics ───────────────────────────────────────
        rows.append(("stats.check_in_count", "\(s.checkInCount)", ""))
        if let p = s.period {
            rows.append(("stats.period_start", isoDay(p.start), ""))
            rows.append(("stats.period_end",   isoDay(p.end),   ""))
        }
        if let avg = s.averageDaysBetweenCheckIns {
            rows.append(("stats.avg_days_between_checkins", csvDbl(avg, 1), "days"))
        }

        // ── OLS Trends ───────────────────────────────────────
        rows += trendRows("weight",      s.weightTrend,     "kg")
        rows += trendRows("body_fat",    s.bodyFatTrend,    "%")
        rows += trendRows("muscle_mass", s.muscleMassTrend, "kg")

        // ── Personal records ─────────────────────────────────
        if let r = s.lowestBodyFat  { rows += recordRows("lowest_body_fat",  r, "%") }
        if let r = s.highestBodyFat { rows += recordRows("highest_body_fat", r, "%") }
        if let r = s.lowestWeight   { rows += recordRows("lowest_weight",    r, "kg") }
        if let r = s.highestWeight  { rows += recordRows("highest_weight",   r, "kg") }
        if let r = s.peakMuscleMass { rows += recordRows("peak_muscle_mass", r, "kg") }

        var lines = ["key,value,unit"]
        for row in rows {
            lines.append("\(esc(row.key)),\(esc(row.value)),\(esc(row.unit))")
        }
        return lines.joined(separator: "\r\n")
    }

    // MARK: - CSV helpers

    private static func trendRows(
        _ metric: String,
        _ trend: Trend,
        _ unit: String
    ) -> [(key: String, value: String, unit: String)] {
        [
            ("trend.\(metric).direction",       trendDir(trend),           ""),
            ("trend.\(metric).slope_per_day",   csvDbl(trend.slope, 6),    "\(unit)/day"),
        ]
    }

    private static func recordRows(
        _ name: String,
        _ record: MetricRecord,
        _ unit: String
    ) -> [(key: String, value: String, unit: String)] {
        [
            ("record.\(name).value", csvDbl(record.value, 4), unit),
            ("record.\(name).date",  isoDay(record.date),     ""),
        ]
    }

    private static func trendDir(_ trend: Trend) -> String {
        switch trend.direction {
        case .rising:       return "rising"
        case .falling:      return "falling"
        case .flat:         return "flat"
        case .insufficient: return "insufficient"
        }
    }

    /// Wraps a field in quotes and doubles any interior quotes (RFC 4180 §2).
    static func esc(_ field: String) -> String {
        guard field.contains(",") || field.contains("\"")
                || field.contains("\n") || field.contains("\r") else {
            return field
        }
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    /// Formats a Double with a fixed number of fraction digits using POSIX locale
    /// so the decimal separator is always "." regardless of device locale.
    private static func csvDbl(_ value: Double, _ fractionDigits: Int) -> String {
        let nf = NumberFormatter()
        nf.locale            = Locale(identifier: "en_US_POSIX")
        nf.numberStyle       = .decimal
        nf.minimumFractionDigits = fractionDigits
        nf.maximumFractionDigits = fractionDigits
        nf.usesGroupingSeparator = false
        return nf.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private static func isoDay(_ date: Date) -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        return f.string(from: date)
    }

    // MARK: - Private (text)

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
