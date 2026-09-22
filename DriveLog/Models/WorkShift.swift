import Foundation
import SwiftData

@Model final class WorkShift {
    var id: UUID
    var startedAt: Date
    var endedAt: Date?
    var vehicleID: UUID
    var note: String

    init(startedAt: Date = .now, endedAt: Date? = nil, vehicleID: UUID, note: String = "") {
        id = UUID()
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.vehicleID = vehicleID
        self.note = note
    }

    var duration: TimeInterval { (endedAt ?? .now).timeIntervalSince(startedAt) }
    var isActive: Bool { endedAt == nil }
}
