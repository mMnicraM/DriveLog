import Foundation

struct ProfitabilitySummary: Equatable {
    let income: Double, costs: Double, distanceKM: Double, workSeconds: TimeInterval
    var profit: Double { income - costs }
    var profitPerKM: Double { distanceKM > 0 ? profit / distanceKM : 0 }
    var profitPerHour: Double { workSeconds > 0 ? profit / (workSeconds / 3600) : 0 }
}

enum ReportPeriod: String, CaseIterable, Identifiable {
    case day = "Dzień", week = "Tydzień", month = "Miesiąc", year = "Rok"
    var id: String { rawValue }
    func interval(now: Date = .now, calendar: Calendar = .current) -> DateInterval {
        let component: Calendar.Component
        switch self { case .day: component = .day; case .week: component = .weekOfYear; case .month: component = .month; case .year: component = .year }
        return calendar.dateInterval(of: component, for: now) ?? DateInterval(start: now, duration: 1)
    }
}

enum ProfitabilityCalculator {
    static func calculate(trips: [Trip], fuel: [FuelEntry], expenses: [Expense], incomes: [Income],
                          interval: DateInterval, vehicleID: UUID? = nil) -> ProfitabilitySummary {
        // Half-open intervals avoid counting midnight in two days.
        func contains(_ date: Date) -> Bool { date >= interval.start && date < interval.end }
        let selected = trips.filter { contains($0.startedAt) && $0.category == .business && (vehicleID == nil || $0.vehicleID == vehicleID) }
        return ProfitabilitySummary(
            income: incomes.filter { contains($0.date) && (vehicleID == nil || $0.vehicleID == vehicleID) }.reduce(0) { $0 + $1.netAmount },
            costs: fuel.filter { contains($0.date) && (vehicleID == nil || $0.vehicleID == vehicleID) }.reduce(0) { $0 + $1.total }
                + expenses.filter { contains($0.date) && (vehicleID == nil || $0.vehicleID == vehicleID) }.reduce(0) { $0 + $1.amount },
            distanceKM: selected.reduce(0) { $0 + $1.distanceKM },
            workSeconds: selected.reduce(0) { $0 + $1.duration }
        )
    }
}
