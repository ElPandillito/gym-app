//
//  Date+Extensions.swift
//  GYM APP
//

import Foundation

extension Date {
    var startOfDay: Date { Calendar.current.startOfDay(for: self) }

    var startOfMonth: Date {
        Calendar.current.dateInterval(of: .month, for: self)?.start ?? self
    }

    var endOfMonth: Date {
        guard let interval = Calendar.current.dateInterval(of: .month, for: self) else { return self }
        return Calendar.current.date(byAdding: .second, value: -1, to: interval.end) ?? self
    }

    func daysFrom(_ other: Date) -> Int {
        Calendar.current.dateComponents([.day], from: other.startOfDay, to: startOfDay).day ?? 0
    }

    var ageYears: Int? {
        Calendar.current.dateComponents([.year], from: self, to: Date()).year
    }

    var isToday: Bool { Calendar.current.isDateInToday(self) }
    var isThisWeek: Bool { Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear) }
    var isThisMonth: Bool { Calendar.current.isDate(self, equalTo: Date(), toGranularity: .month) }
}
