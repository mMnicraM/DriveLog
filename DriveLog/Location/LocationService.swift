import Foundation
import CoreLocation
import Combine

struct RecordingSnapshot: Codable {
    let startedAt: Date
    var endedAt: Date?
    let vehicleID: UUID
    let shiftID: UUID?
    var distanceMeters: Double
    var points: [TrackPoint]
}

enum LocationConfiguration {
    static func supportsBackgroundLocation(infoDictionary: [String: Any] = Bundle.main.infoDictionary ?? [:]) -> Bool {
        guard let modes = infoDictionary["UIBackgroundModes"] as? [String] else { return false }
        return modes.contains("location")
    }
}

enum LocationAuthorizationAction: Equatable {
    case start
    case requestPermission
    case openSettings

    static func resolve(_ status: CLAuthorizationStatus) -> Self {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse: .start
        case .notDetermined: .requestPermission
        case .denied, .restricted: .openSettings
        @unknown default: .openSettings
        }
    }
}

private enum RecordingDraftStore {
    private enum StoreError: LocalizedError {
        case applicationSupportUnavailable
        var errorDescription: String? {
            "Nie można uzyskać dostępu do katalogu danych aplikacji."
        }
    }
    private static let fileName = "active-route.json"
    private static var fileURL: URL? {
        guard let directory = try? FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ) else { return nil }
        return directory.appendingPathComponent(fileName)
    }

    static func load() -> RecordingSnapshot? {
        guard let fileURL, let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(RecordingSnapshot.self, from: data)
    }

    static func save(_ snapshot: RecordingSnapshot) throws {
        guard let fileURL else { throw StoreError.applicationSupportUnavailable }
        let data = try JSONEncoder().encode(snapshot)
        try data.write(to: fileURL, options: .atomic)
        UserDefaults.standard.set(true, forKey: "hasRecordingDraft")
    }

    static func remove() {
        if let fileURL { try? FileManager.default.removeItem(at: fileURL) }
        UserDefaults.standard.set(false, forKey: "hasRecordingDraft")
    }
}

@MainActor final class LocationService: NSObject, ObservableObject, @preconcurrency CLLocationManagerDelegate {
    @Published private(set) var isRecording = false
    @Published private(set) var distanceMeters: Double = 0
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var points: [TrackPoint] = []
    @Published private(set) var recoverableDraft: RecordingSnapshot?
    @Published private(set) var persistenceError: String?
    let backgroundTrackingAvailable = LocationConfiguration.supportsBackgroundLocation()

    private let manager = CLLocationManager()
    private var previous: CLLocation?
    private var activeSnapshot: RecordingSnapshot?
    private var lastPersistedAt = Date.distantPast

    override init() {
        super.init()
        manager.delegate = self
        manager.activityType = .automotiveNavigation
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.distanceFilter = 5
        authorizationStatus = manager.authorizationStatus
        recoverableDraft = RecordingDraftStore.load()
        UserDefaults.standard.set(recoverableDraft != nil, forKey: "hasRecordingDraft")
    }

    func requestPermission() { manager.requestWhenInUseAuthorization() }

    func refreshAuthorizationStatus() {
        authorizationStatus = manager.authorizationStatus
    }

    func start(vehicleID: UUID, shiftID: UUID?) {
        guard !isRecording, CLLocationManager.locationServicesEnabled(),
              authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse else { return }
        let snapshot = RecordingSnapshot(
            startedAt: .now,
            endedAt: nil,
            vehicleID: vehicleID,
            shiftID: shiftID,
            distanceMeters: 0,
            points: []
        )
        activeSnapshot = snapshot
        recoverableDraft = nil
        points = []
        distanceMeters = 0
        previous = nil
        isRecording = true
        persist(snapshot)
        startManager()
    }

    func resumeDraft() {
        guard !isRecording, let draft = recoverableDraft, draft.endedAt == nil,
              CLLocationManager.locationServicesEnabled(),
              authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse else { return }
        activeSnapshot = draft
        recoverableDraft = nil
        points = draft.points
        distanceMeters = draft.distanceMeters
        if let last = draft.points.last {
            previous = CLLocation(
                coordinate: .init(latitude: last.latitude, longitude: last.longitude),
                altitude: 0,
                horizontalAccuracy: 0,
                verticalAccuracy: -1,
                timestamp: last.timestamp
            )
        }
        isRecording = true
        startManager()
    }

    func finishRecoveredDraft() -> RecordingSnapshot? {
        guard var draft = recoverableDraft ?? activeSnapshot else { return nil }
        draft.endedAt = draft.endedAt ?? .now
        activeSnapshot = nil
        recoverableDraft = draft
        points = draft.points
        distanceMeters = draft.distanceMeters
        persist(draft)
        stopManager()
        return draft
    }

    func stop() -> RecordingSnapshot? {
        guard var snapshot = activeSnapshot else { return nil }
        snapshot.endedAt = .now
        snapshot.distanceMeters = distanceMeters
        snapshot.points = points
        activeSnapshot = nil
        recoverableDraft = snapshot
        persist(snapshot)
        stopManager()
        return snapshot
    }

    func completeDraft() {
        activeSnapshot = nil
        recoverableDraft = nil
        points = []
        distanceMeters = 0
        previous = nil
        persistenceError = nil
        RecordingDraftStore.remove()
    }

    func discardDraft() {
        stopManager()
        completeDraft()
    }

    func flushDraft() {
        guard var snapshot = activeSnapshot else { return }
        snapshot.distanceMeters = distanceMeters
        snapshot.points = points
        activeSnapshot = snapshot
        persist(snapshot)
    }

    private func startManager() {
        // Setting this to true without a valid UIBackgroundModes array raises
        // an Objective-C exception and terminates the app. Keep foreground GPS
        // available even if a generated project loses the capability.
        manager.allowsBackgroundLocationUpdates = backgroundTrackingAvailable
        manager.showsBackgroundLocationIndicator = backgroundTrackingAvailable
        manager.pausesLocationUpdatesAutomatically = false
        manager.startUpdatingLocation()
    }

    private func stopManager() {
        manager.stopUpdatingLocation()
        manager.allowsBackgroundLocationUpdates = false
        manager.showsBackgroundLocationIndicator = false
        isRecording = false
    }

    private func persist(_ snapshot: RecordingSnapshot) {
        do {
            try RecordingDraftStore.save(snapshot)
            lastPersistedAt = .now
            persistenceError = nil
        } catch {
            persistenceError = error.localizedDescription
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .denied || authorizationStatus == .restricted, isRecording {
            _ = stop()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        persistenceError = error.localizedDescription
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isRecording, var snapshot = activeSnapshot else { return }
        var changed = false
        for location in locations where location.horizontalAccuracy >= 0 && location.horizontalAccuracy <= 50 {
            guard location.timestamp >= snapshot.startedAt,
                  previous == nil || location.timestamp > previous!.timestamp else { continue }
            if let previous {
                let segment = location.distance(from: previous)
                if segment.isFinite, segment >= 0, segment <= 2_000 {
                    distanceMeters += segment
                }
            }
            previous = location
            points.append(.init(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                timestamp: location.timestamp
            ))
            changed = true
        }
        guard changed else { return }
        snapshot.distanceMeters = distanceMeters
        snapshot.points = points
        activeSnapshot = snapshot
        if Date.now.timeIntervalSince(lastPersistedAt) >= 5 || points.count.isMultiple(of: 10) {
            persist(snapshot)
        }
    }
}
