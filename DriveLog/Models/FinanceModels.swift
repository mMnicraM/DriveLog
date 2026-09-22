import Foundation
import SwiftData

enum ExpenseCategory: String, Codable, CaseIterable, Identifiable {
    case service = "Serwis", oil = "Olej", tyres = "Opony", insurance = "Ubezpieczenie", lease = "Leasing/rata", wash = "Myjnia", parking = "Parking", tolls = "Autostrady", repairs = "Naprawy", other = "Inne"
    var id: String { rawValue }
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
    var id: UUID; var date: Date; var amount: Double; var platform: String; var tips: Double; var commission: Double; var note: String
    init(date: Date = .now, amount: Double, platform: String, tips: Double = 0, commission: Double = 0, note: String = "") { id = UUID(); self.date = date; self.amount = amount; self.platform = platform; self.tips = tips; self.commission = commission; self.note = note }
    var netAmount: Double { amount + tips - commission }
}
