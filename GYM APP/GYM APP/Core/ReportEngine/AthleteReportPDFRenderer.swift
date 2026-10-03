//
//  AthleteReportPDFRenderer.swift
//  GYM APP
//
//  Renders an AthleteReport to A4 PDF using UIGraphicsPDFRenderer (iOS only).
//  Returns nil on macOS — callers must fall back to plain text.
//

import Foundation
#if os(iOS)
import UIKit
#endif

enum AthleteReportPDFRenderer {

    /// Returns A4 PDF data, or nil if the platform does not support PDF rendering.
    static func render(
        _ report: AthleteReport,
        preferences: CoachPreferences = .default
    ) -> Data? {
#if os(iOS)
        return PDFCanvas.render(report, preferences: preferences)
#else
        return nil
#endif
    }
}

// MARK: - iOS canvas

#if os(iOS)
private enum PDFCanvas {

    static let W: CGFloat      = 595  // A4 width in points (72 dpi)
    static let H: CGFloat      = 842  // A4 height in points
    static let margin: CGFloat = 48
    static let rowH: CGFloat   = 20
    static let gap: CGFloat    = 14

    static func render(_ report: AthleteReport,
                       preferences: CoachPreferences) -> Data? {
        let fmt     = AppUnitFormatter(preferences: preferences)
        let dateFmt = makeDateFormatter()
        let page    = CGRect(x: 0, y: 0, width: W, height: H)

        return UIGraphicsPDFRenderer(bounds: page).pdfData { ctx in
            ctx.beginPage()
            let cg = ctx.cgContext
            var y  = margin

            y = drawHeader(cg, page: page, y: y, date: report.generatedAt, df: dateFmt)

            // ── Athlete ──────────────────────────────────────────
            let a = report.athlete
            y = sectionTitle("ATLETA", y: y)
            y = row("Nombre", a.name, y)
            y = row("Género", a.gender.displayName, y)
            if let age = a.ageYears { y = row("Edad",     "\(Int(age)) años", y) }
            if let h   = a.heightCm { y = row("Estatura", fmt.height(h), y) }
            y += gap

            // ── Statistics ───────────────────────────────────────
            let s = report.statistics
            y = sectionTitle("ESTADÍSTICAS GENERALES", y: y)
            y = row("Check-ins", "\(s.checkInCount)", y)
            if let p = s.period {
                y = row("Período",
                        "\(dateFmt.string(from: p.start)) – \(dateFmt.string(from: p.end))", y)
            }
            if let avg = s.averageDaysBetweenCheckIns {
                y = row("Frecuencia", String(format: "%.0f días promedio", avg), y)
            }
            y += gap

            // ── OLS Trends ───────────────────────────────────────
            y = sectionTitle("TENDENCIAS (Regresión OLS)", y: y)
            y = row("Peso",
                    trendStr(s.weightTrend,
                             fmt.convertedWeight(s.weightTrend.slope * 30),
                             fmt.weightLabel), y)
            y = row("% Grasa",
                    trendStr(s.bodyFatTrend, s.bodyFatTrend.slope * 30, "%"), y)
            y = row("Masa Muscular",
                    trendStr(s.muscleMassTrend,
                             fmt.convertedWeight(s.muscleMassTrend.slope * 30),
                             fmt.weightLabel), y)
            y += gap

            // ── Personal records ─────────────────────────────────
            let recs: [(String, MetricRecord?, Bool)] = [
                ("Menor % Grasa",      s.lowestBodyFat,  false),
                ("Mayor % Grasa",      s.highestBodyFat, false),
                ("Menor Peso",         s.lowestWeight,   true),
                ("Mayor Peso",         s.highestWeight,  true),
                ("Pico Masa Muscular", s.peakMuscleMass, true),
            ]
            let available = recs.compactMap { (label, rec, isW) -> (String, MetricRecord, Bool)? in
                guard let rec else { return nil }
                return (label, rec, isW)
            }
            if !available.isEmpty {
                y = sectionTitle("MARCAS PERSONALES", y: y)
                for (label, rec, isW) in available {
                    let val = isW
                        ? "\(String(format: "%.1f", fmt.convertedWeight(rec.value))) \(fmt.weightLabel)"
                        : String(format: "%.1f", rec.value)
                    y = row(label, "\(val)  (\(dateFmt.string(from: rec.date)))", y)
                }
            }

            drawFooter(cg, page: page)
        }
    }

    // MARK: - Drawing primitives

    @discardableResult
    static func drawHeader(_ ctx: CGContext, page: CGRect, y: CGFloat,
                           date: Date, df: DateFormatter) -> CGFloat {
        ("GYM APP — Reporte del Atleta" as NSString).draw(
            at: CGPoint(x: margin, y: y),
            withAttributes: [
                .font: UIFont.systemFont(ofSize: 20, weight: .bold),
                .foregroundColor: UIColor.label
            ]
        )

        let subAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.secondaryLabel
        ]
        let sub  = "Generado el \(df.string(from: date))" as NSString
        let subW = sub.size(withAttributes: subAttr).width
        sub.draw(at: CGPoint(x: page.width - margin - subW, y: y + 7),
                 withAttributes: subAttr)

        let lineY = y + 34
        ctx.setStrokeColor(UIColor.separator.cgColor)
        ctx.setLineWidth(0.5)
        ctx.move(to: CGPoint(x: margin, y: lineY))
        ctx.addLine(to: CGPoint(x: page.width - margin, y: lineY))
        ctx.strokePath()

        return lineY + 16
    }

    static func drawFooter(_ ctx: CGContext, page: CGRect) {
        let lineY = H - margin
        ctx.setStrokeColor(UIColor.separator.cgColor)
        ctx.setLineWidth(0.5)
        ctx.move(to: CGPoint(x: margin, y: lineY))
        ctx.addLine(to: CGPoint(x: page.width - margin, y: lineY))
        ctx.strokePath()

        let attr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9),
            .foregroundColor: UIColor.tertiaryLabel
        ]
        let text = "Generado por GYM APP" as NSString
        let tw   = text.size(withAttributes: attr).width
        text.draw(at: CGPoint(x: page.width / 2 - tw / 2, y: lineY + 6),
                  withAttributes: attr)
    }

    @discardableResult
    static func sectionTitle(_ title: String, y: CGFloat) -> CGFloat {
        (title as NSString).draw(
            at: CGPoint(x: margin, y: y),
            withAttributes: [
                .font: UIFont.systemFont(ofSize: 10, weight: .semibold),
                .foregroundColor: UIColor.systemBlue
            ]
        )
        return y + 16
    }

    @discardableResult
    static func row(_ label: String, _ value: String, _ y: CGFloat) -> CGFloat {
        let cw = W - margin * 2
        let lw = cw * 0.38

        (label as NSString).draw(
            in: CGRect(x: margin, y: y, width: lw, height: rowH),
            withAttributes: [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: UIColor.secondaryLabel
            ]
        )
        (value as NSString).draw(
            in: CGRect(x: margin + lw, y: y, width: cw - lw, height: rowH),
            withAttributes: [
                .font: UIFont.systemFont(ofSize: 11, weight: .medium),
                .foregroundColor: UIColor.label
            ]
        )
        return y + rowH
    }

    static func trendStr(_ trend: Trend, _ monthly: Double, _ unit: String) -> String {
        switch trend.direction {
        case .rising:       return String(format: "↑ +%.2f %@/mes", monthly, unit)
        case .falling:      return String(format: "↓ %.2f %@/mes",  monthly, unit)
        case .flat:         return "→ Estable"
        case .insufficient: return "— Datos insuficientes"
        }
    }

    static func makeDateFormatter() -> DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.locale    = Locale(identifier: "es_MX")
        return f
    }
}
#endif
