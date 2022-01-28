//
//  Date.swift
//  LibreDirect
//

import Foundation

extension Date {
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
        Double(self.timeIntervalSince1970 * 1000)
    }

    func toLocalDateTime() -> String {
        return Date.localDateTimeFormatter.string(from: self)
    }

    func toLocalTime() -> String {
        return Date.localTimeFormatter.string(from: self)
    }

    private func floorAllComponents(before component: Calendar.Component) -> Date {
        // All components to round ordered by length
        let components = [Calendar.Component.year, .month, .day, .hour, .minute, .second, .nanosecond]

        guard let index = components.firstIndex(of: component) else {
            fatalError("Wrong component")
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

    private static var localDateTimeFormatter: DateFormatter = {
        let format = DateFormatter()
        format.timeZone = .current
        format.dateStyle = .short
        format.timeStyle = .short

        return format
    }()

    private static var localTimeFormatter: DateFormatter = {
        let format = DateFormatter()
        format.timeZone = .current
        format.timeStyle = .short
        format.dateStyle = .none

        return format
    }()
}
