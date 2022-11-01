//
//  Date.swift
//  GlucoseDirect
//

import Foundation

// MARK: - TimeFormat

enum TimeFormat {
    case hour
    case hourWithMinutes
}

extension Date {
    static func valuesBetween(from fromDate: Date, to toDate: Date, component: Calendar.Component, step: Int) -> [Date] {
        var dates: [Date] = []
        var date = fromDate

        while date <= toDate {
            dates.append(date.toRounded(on: step, component))

            guard let newDate = Calendar.current.date(byAdding: component, value: step, to: date) else {
                break
            }

            date = newDate
        }

        return dates
    }

    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }

    func toMillisecondsAsInt64() -> Int64 {
        Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }

    func toRounded(on amount: Int, _ component: Calendar.Component) -> Date {
        let cal = Calendar.current
        let value = cal.component(component, from: self)

        // Compute nearest multiple of amount:
        let roundedValue = Int(Double(value) / Double(amount)) * amount
        let newDate = cal.date(byAdding: component, value: roundedValue - value, to: self)!

        return newDate.floorAllComponents(before: component)
    }

    func toISOStringFromDate() -> String {
        return Date.isoDateFormatter.string(from: self).appending("Z")
    }

    func toMillisecondsAsDouble() -> Double {
        return Double(self.timeIntervalSince1970 * 1000)
    }

    func toLocalDateTime() -> String {
        return Date.localDateTimeFormatter.string(from: self)
    }

    func toLocalTime(format: TimeFormat = .hourWithMinutes) -> String {
        if format == .hour {
            return Date.localHourFormatter.string(from: self)
        }

        return Date.localTimeFormatter.string(from: self)
    }

    func toLocalDate() -> String {
        return Date.localDateFormatter.string(from: self)
    }

    private func floorAllComponents(before component: Calendar.Component) -> Date {
        // All components to round ordered by length
        let components = [Calendar.Component.year, .month, .day, .hour, .minute, .second, .nanosecond]

        guard let index = components.firstIndex(of: component) else {
            return self
        }

        let cal = Calendar.current
        var date = self

        components.suffix(from: index + 1).forEach { roundComponent in
            let value = cal.component(roundComponent, from: date) * -1
            date = cal.date(byAdding: roundComponent, value: value, to: date)!
        }

        return date
    }

    private static var isoDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"

        return dateFormatter
    }()

    private static var localHourFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = .current
        dateFormatter.dateFormat = "HH"

        return dateFormatter
    }()

    private static var localDateTimeFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = .current
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short

        return dateFormatter
    }()

    private static var localTimeFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = .current
        dateFormatter.timeStyle = .short
        dateFormatter.dateStyle = .none

        return dateFormatter
    }()

    private static var localDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = .current
        dateFormatter.timeStyle = .none
        dateFormatter.dateStyle = .short

        return dateFormatter
    }()
}
