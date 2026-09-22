import Foundation
import SwiftData

enum TripCategory: String, Codable, CaseIterable, Identifiable {
    case business = "Służbowa", privateTrip = "Prywatna", unclassified = "Nierozpoznana"
    static let gpsDefault: TripCategory = .business
    var id: String { rawValue }
}

struct TrackPoint: Codable, Hashable {
    let latitude: Double
    let longitude: Double
    let timestamp: Date
}

@Model final class Trip {
    var id: UUID
    var startedAt: Date
    var endedAt: Date
    var distanceMeters: Double
    var categoryRaw: String
    var purpose: String
    var note: String
    var vehicleID: UUID
    var encodedTrack: Data?
    var shiftID: UUID?

    init(startedAt: Date, endedAt: Date, distanceMeters: Double, vehicleID: UUID, category: TripCategory = .unclassified, purpose: String = "", note: String = "", points: [TrackPoint] = []) {
        id = UUID(); self.startedAt = startedAt; self.endedAt = endedAt; self.distanceMeters = distanceMeters
        self.vehicleID = vehicleID; categoryRaw = category.rawValue; self.purpose = purpose; self.note = note
        encodedTrack = try? JSONEncoder().encode(points)
    }
    var category: TripCategory { get { TripCategory(rawValue: categoryRaw) ?? .unclassified } set { categoryRaw = newValue.rawValue } }
    var distanceKM: Double { distanceMeters / 1000 }
    var duration: TimeInterval { max(0, endedAt.timeIntervalSince(startedAt)) }
    var points: [TrackPoint] { (try? JSONDecoder().decode([TrackPoint].self, from: encodedTrack ?? Data())) ?? [] }
}
