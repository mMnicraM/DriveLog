import Foundation
import SwiftData

enum ExpenseCategory: String, Codable, CaseIterable, Identifiable {
    case service = "Serwis", oil = "Olej", tyres = "Opony", insurance = "Ubezpieczenie", lease = "Leasing/rata", wash = "Myjnia", parking = "Parking", tolls = "Autostrady", repairs = "Naprawy", other = "Inne"
    var id: String { rawValue }
}

enum IncomePlatform: String, Codable, CaseIterable, Identifiable {
    case uber = "Uber"
    case bolt = "Bolt"
    case freeNow = "FreeNow"
    case glovo = "Glovo"
    case wolt = "Wolt"
    case other = "Inne"
    var id: String { rawValue }
}

enum PlatformCommissionStore {
    private static let prefix = "platformCommissionPercentage."

    static func percentage(for platform: String, defaults: UserDefaults = .standard) -> Double {
        guard let stored = defaults.object(forKey: prefix + platform) as? NSNumber else { return 0 }
        let value = stored.doubleValue
        return min(max(value, 0), 100)
    }

    static func setPercentage(_ value: Double, for platform: String, defaults: UserDefaults = .standard) {
        defaults.set(min(max(value, 0), 100), forKey: prefix + platform)
    }
}

enum TripSettlementCalculator {
    static func commission(fare: Double, percentage: Double) -> Double {
        max(0, fare) * min(max(percentage, 0), 100) / 100
    }

    static func net(fare: Double, tips: Double, percentage: Double) -> Double {
        max(0, fare) + max(0, tips) - commission(fare: fare, percentage: percentage)
    }
}

@Model final class FuelEntry {
    var shiftID: UUID?
    var quantityUnit: String?
    var id: UUID; var date: Date; var vehicleID: UUID; var odometer: Double; var liters: Double; var pricePerUnit: Double; var total: Double; var station: String; var fullTank: Bool
    init(date: Date = .now, vehicleID: UUID, odometer: Double, liters: Double, pricePerUnit: Double, station: String = "", fullTank: Bool = true) {
        id = UUID(); self.date = date; self.vehicleID = vehicleID; self.odometer = odometer; self.liters = liters; self.pricePerUnit = pricePerUnit; total = liters * pricePerUnit; self.station = station; self.fullTank = fullTank
    }
}

@Model final class Expense {
    var shiftID: UUID?
    var id: UUID; var date: Date; var vehicleID: UUID; var amount: Double; var categoryRaw: String; var details: String
    init(date: Date = .now, vehicleID: UUID, amount: Double, category: ExpenseCategory, details: String = "") { id = UUID(); self.date = date; self.vehicleID = vehicleID; self.amount = amount; categoryRaw = category.rawValue; self.details = details }
    var category: ExpenseCategory { ExpenseCategory(rawValue: categoryRaw) ?? .other }
}

@Model final class Income {
    var vehicleID: UUID?
    var shiftID: UUID?
    var tripID: UUID?
    var id: UUID; var date: Date; var amount: Double; var platform: String; var tips: Double; var commission: Double; var note: String
    init(date: Date = .now, amount: Double, platform: String, tips: Double = 0, commission: Double = 0, note: String = "", tripID: UUID? = nil) {
        id = UUID(); self.date = date; self.amount = amount; self.platform = platform
        self.tips = tips; self.commission = commission; self.note = note; self.tripID = tripID
    }
    var netAmount: Double { amount + tips - commission }
}
