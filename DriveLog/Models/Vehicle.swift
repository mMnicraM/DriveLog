import Foundation
import SwiftData

enum FuelType: String, Codable, CaseIterable, Identifiable {
    case petrol = "Benzyna", diesel = "Diesel", lpg = "LPG", hybrid = "Hybryda", phev = "PHEV", electric = "Elektryczny"
    var id: String { rawValue }
}

@Model final class Vehicle {
    var id: UUID
    var make: String
    var model: String
    var registration: String
    var year: Int
    var fuelTypeRaw: String
    var odometer: Double
    var createdAt: Date

    init(make: String, model: String, registration: String, year: Int, fuelType: FuelType, odometer: Double) {
        id = UUID(); self.make = make; self.model = model; self.registration = registration.uppercased()
        self.year = year; fuelTypeRaw = fuelType.rawValue; self.odometer = odometer; createdAt = .now
    }
    var displayName: String { "\(make) \(model)" }
    var fuelType: FuelType { FuelType(rawValue: fuelTypeRaw) ?? .petrol }
}

