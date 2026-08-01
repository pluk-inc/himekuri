//
//  LayoutSupport.swift
//  himekuri
//
//  Small helpers shared by the page layouts.
//

import Foundation

nonisolated func totalDays(of info: DayInfo) -> Int {
    Calendar(identifier: .gregorian).range(of: .day, in: .year, for: info.date)?.count ?? 365
}

nonisolated let monthNamesEN = [
    "", "JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE",
    "JULY", "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER",
]

nonisolated let weekdayNamesEN = [
    "", "SUNDAY", "MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY",
]
