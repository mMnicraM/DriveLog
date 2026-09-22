import SwiftUI
import SwiftData
import MapKit
import UIKit
import Combine

struct TripsView: View {
    @Query(sort: \Trip.startedAt, order: .reverse) private var trips: [Trip]
    @Environment(\.modelContext) private var context
    @State private var deleting: [Trip] = []
    @State private var showDelete = false
    @State private var error = ""
    var body: some View {
        List { if trips.isEmpty { ContentUnavailableView("Brak tras", systemImage: "map", description: Text("Rozpocznij pierwszą trasę z ekranu Start.")) }
            ForEach(trips) { trip in NavigationLink { TripDetailView(trip: trip) } label: { VStack(alignment: .leading, spacing: 6) { HStack { Text(trip.startedAt, format: .dateTime.day().month().hour().minute()).font(.headline); Spacer(); Text(trip.category.rawValue).font(.caption).foregroundStyle(trip.category == .business ? .green : .secondary) }; HStack { Label(Formatters.distance(trip.distanceKM), systemImage: "road.lanes"); Label(Formatters.duration(trip.duration), systemImage: "clock") }.font(.subheadline).foregroundStyle(.secondary) } } }.onDelete { deleting = $0.map { trips[$0] }; showDelete = true }
        }.navigationTitle("Trasy")
        .confirmationDialog("Usunąć wybrane trasy? Tej operacji nie można cofnąć.", isPresented: $showDelete, titleVisibility: .visible) {
            Button("Usuń", role: .destructive) {
                deleting.forEach { context.delete($0) }
                do { try context.save(); deleting = [] }
                catch { context.rollback(); self.error = error.localizedDescription }
            }
            Button("Anuluj", role: .cancel) { deleting = [] }
        }
        .alert("Nie udało się usunąć", isPresented: Binding(get: { !error.isEmpty }, set: { if !$0 { error = "" } })) { Button("OK") {} } message: { Text(error) }
    }
}

struct RecordingView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @Query private var vehicles: [Vehicle]
    @Query private var shifts: [WorkShift]
    @StateObject private var location = LocationService()
    @State private var vehicleID: UUID?
    @State private var shiftID: UUID?
    @State private var pending: RecordingSnapshot?
    @State private var error = ""
    @State private var showRecovery = false
    @State private var showLocationSettings = false
    @State private var startAfterPermission = false
    @AppStorage("activeVehicleID") private var activeVehicleID = ""
    @AppStorage("saveNotice") private var notice = ""

    private var authorized: Bool {
        location.authorizationStatus == .authorizedAlways ||
        location.authorizationStatus == .authorizedWhenInUse
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: location.isRecording ? "location.fill.viewfinder" : pending != nil ? "externaldrive.fill.badge.checkmark" : "location.slash")
                    .font(.system(size: 64))
                    .foregroundStyle(location.isRecording ? Brand.green : .secondary)
                    .padding(.top, 32)
                Text(location.isRecording ? "Trasa jest rejestrowana" : pending != nil ? "Trasa oczekuje na zapis" : "Gotowy do jazdy")
                    .font(.title2.bold())
                Text(Formatters.distance(location.distanceMeters / 1000))
                    .font(.largeTitle.bold().monospacedDigit())
                if location.isRecording {
                    Text(location.points.isEmpty
                         ? "Oczekiwanie na pierwszy punkt GPS…"
                         : "Zapisano punktów GPS: \(location.points.count)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                if !location.isRecording && pending == nil {
                    Picker("Pojazd", selection: $vehicleID) {
                        Text("Wybierz pojazd").tag(nil as UUID?)
                        ForEach(vehicles) { Text($0.displayName).tag(Optional($0.id)) }
                    }
                }
                if !authorized {
                    Text(location.authorizationStatus == .notDetermined
                         ? "Po dotknięciu przycisku iPhone poprosi o dostęp do lokalizacji, a trasa rozpocznie się automatycznie."
                         : "Dostęp do lokalizacji jest wyłączony. Otwórz ustawienia DriveLog i wybierz „Gdy używam aplikacji” lub „Zawsze”.")
                        .font(.callout).foregroundStyle(.secondary)
                }
                if authorized && !location.backgroundTrackingAvailable {
                    Label("GPS działa teraz tylko przy otwartej aplikacji. Tryb pracy w tle nie został rozpoznany przez iOS.", systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }
                if location.isRecording && location.backgroundTrackingAvailable {
                    Label("Rejestrowanie po wygaszeniu ekranu jest aktywne", systemImage: "lock.open.fill")
                        .font(.footnote)
                        .foregroundStyle(Brand.green)
                }
                Button(primaryActionTitle) {
                    toggle()
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(pending == nil && !location.isRecording && vehicleID == nil)
                if pending != nil {
                    Button("Odrzuć tę trasę", role: .destructive) {
                        pending = nil
                        location.discardDraft()
                    }
                    .frame(maxWidth: .infinity)
                }
                Text("Trasa jest zapisywana roboczo na urządzeniu. Po przerwaniu aplikacja pozwoli ją kontynuować, zapisać lub odrzucić. Dokładność i działanie w tle sprawdź na prawdziwym iPhonie.")
                    .font(.footnote).foregroundStyle(.secondary)
            }.padding()
        }
        .navigationTitle("Rejestracja GPS")
        .navigationBarBackButtonHidden(location.isRecording || pending != nil)
        .interactiveDismissDisabled(location.isRecording || pending != nil)
        .onAppear(perform: prepare)
        .onChange(of: location.persistenceError) { _, value in
            if let value { error = "Nie udało się zapisać kopii roboczej: \(value)" }
        }
        .onChange(of: location.locationError) { _, value in
            guard let value else { return }
            if !location.isRecording { pending = location.recoverableDraft }
            error = value
        }
        .onChange(of: location.authorizationStatus) { _, status in
            guard startAfterPermission else { return }
            switch LocationAuthorizationAction.resolve(status) {
            case .start:
                startAfterPermission = false
                beginRecording()
            case .openSettings:
                startAfterPermission = false
                showLocationSettings = true
            case .requestPermission:
                break
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { location.refreshAuthorizationStatus() }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            location.flushDraft()
        }
        .confirmationDialog("Znaleziono niedokończoną trasę", isPresented: $showRecovery, titleVisibility: .visible) {
            Button("Kontynuuj rejestrowanie") {
                location.resumeDraft()
                if !location.isRecording { error = "Nie można wznowić. Sprawdź dostęp do lokalizacji." }
            }
            Button("Zakończ teraz i zapisz") { pending = location.finishRecoveredDraft() }
            Button("Odrzuć trasę", role: .destructive) {
                location.discardDraft()
                vehicleID = vehicles.first { $0.id.uuidString == activeVehicleID }?.id ?? vehicles.first?.id
                shiftID = nil
            }
            Button("Anuluj", role: .cancel) {}
        } message: {
            Text("Kopia robocza pozostanie na urządzeniu, dopóki nie zapiszesz albo nie odrzucisz trasy.")
        }
        .alert("Rejestracja trasy", isPresented: Binding(
            get: { !error.isEmpty },
            set: { if !$0 { error = "" } }
        )) { Button("OK") {} } message: { Text(error) }
        .alert("Włącz lokalizację dla DriveLog", isPresented: $showLocationSettings) {
            Button("Otwórz Ustawienia") {
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                openURL(url)
            }
            Button("Anuluj", role: .cancel) {}
        } message: {
            Text("Bez dostępu do lokalizacji DriveLog nie może rozpocząć zapisu trasy.")
        }
    }

    private var primaryActionTitle: String {
        if let pending {
            return pending.points.isEmpty ? "Zapisz trasę bez śladu GPS" : "Zapisz odzyskaną trasę"
        }
        if location.isRecording { return "Zakończ i zapisz trasę" }
        switch LocationAuthorizationAction.resolve(location.authorizationStatus) {
        case .start: return "Rozpocznij trasę"
        case .requestPermission: return "Zezwól i rozpocznij trasę"
        case .openSettings: return "Włącz lokalizację w Ustawieniach"
        }
    }

    private func prepare() {
        location.refreshAuthorizationStatus()
        if let draft = location.recoverableDraft {
            vehicleID = draft.vehicleID
            shiftID = draft.shiftID
            if draft.endedAt != nil {
                pending = draft
            } else {
                showRecovery = true
            }
        } else if vehicleID == nil {
            vehicleID = vehicles.first { $0.id.uuidString == activeVehicleID }?.id ?? vehicles.first?.id
        }
    }

    private func toggle() {
        let justStopped = pending == nil && location.isRecording
        if justStopped { pending = location.stop() }
        if let snapshot = pending {
            if justStopped && snapshot.points.isEmpty {
                error = "Nie odebrano żadnego punktu GPS. Sprawdź dostęp do lokalizacji i wyjdź z budynku. Możesz odrzucić kopię albo świadomie zapisać trasę bez mapy."
                return
            }
            let trip = Trip(
                startedAt: snapshot.startedAt,
                endedAt: snapshot.endedAt ?? .now,
                distanceMeters: snapshot.distanceMeters,
                vehicleID: snapshot.vehicleID,
                category: .gpsDefault,
                points: snapshot.points
            )
            trip.shiftID = snapshot.shiftID
            context.insert(trip)
            do {
                try context.save()
                activeVehicleID = snapshot.vehicleID.uuidString
                pending = nil
                location.completeDraft()
                notice = "Zapisano trasę jako służbową"
                dismiss()
            } catch {
                context.rollback()
                self.error = error.localizedDescription
            }
        } else {
            switch LocationAuthorizationAction.resolve(location.authorizationStatus) {
            case .start:
                beginRecording()
            case .requestPermission:
                startAfterPermission = true
                location.requestPermission()
            case .openSettings:
                showLocationSettings = true
            }
        }
    }

    private func beginRecording() {
        guard let vehicleID else {
            error = "Wybierz pojazd przed rozpoczęciem trasy."
            return
        }
        shiftID = shifts.first { $0.isActive && $0.vehicleID == vehicleID }?.id
        location.start(vehicleID: vehicleID, shiftID: shiftID)
        if !location.isRecording {
            error = "Nie można rozpocząć. Sprawdź, czy usługi lokalizacji są włączone."
        }
    }
}


private struct TripDetailView: View {
    let trip: Trip
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("saveNotice") private var notice = ""
    @State private var category: TripCategory = .unclassified
    @State private var purpose = ""
    @State private var note = ""
    @State private var loaded = false
    @State private var error = ""
    private var coordinates: [CLLocationCoordinate2D] { trip.points.map { .init(latitude: $0.latitude, longitude: $0.longitude) } }
    private var region: MKCoordinateRegion {
        guard let first = coordinates.first else { return .init(center: .init(latitude: 52.0, longitude: 19.0), span: .init(latitudeDelta: 5, longitudeDelta: 5)) }
        let latitudes = coordinates.map(\.latitude), longitudes = coordinates.map(\.longitude)
        let minLat = latitudes.min() ?? first.latitude, maxLat = latitudes.max() ?? first.latitude
        let minLon = longitudes.min() ?? first.longitude, maxLon = longitudes.max() ?? first.longitude
        return .init(center: .init(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2), span: .init(latitudeDelta: max((maxLat - minLat) * 1.5, 0.008), longitudeDelta: max((maxLon - minLon) * 1.5, 0.008)))
    }
    var body: some View {
        Form {
            if !coordinates.isEmpty {
                Section("Ślad GPS") {
                    Map(initialPosition: .region(region)) {
                        if coordinates.count > 1 {
                            MapPolyline(coordinates: coordinates).stroke(Brand.green, lineWidth: 5)
                        }
                        if let start = coordinates.first { Marker("Start", systemImage: "flag.fill", coordinate: start).tint(Brand.green) }
                        if coordinates.count > 1, let end = coordinates.last { Marker("Koniec", systemImage: "flag.checkered", coordinate: end).tint(.red) }
                    }.frame(height: 250).clipShape(RoundedRectangle(cornerRadius: 14))
                }
            } else {
                Section { ContentUnavailableView("Brak śladu GPS", systemImage: "map", description: Text("Trasa została dodana ręcznie albo nie otrzymano wystarczającej liczby punktów lokalizacji.")) }
            }
            Section("Przejazd") {
                LabeledContent("Dystans", value: Formatters.distance(trip.distanceKM))
                LabeledContent("Czas", value: Formatters.duration(trip.duration))
                Picker("Kategoria", selection: $category) { ForEach(TripCategory.allCases) { Text($0.rawValue).tag($0) } }
                EntryField(title: "Cel przejazdu", text: $purpose, hint: "Opcjonalnie")
                EntryField(title: "Notatka", text: $note, hint: "Opcjonalnie")
                Button("Zapisz zmiany") {
                    trip.category = category; trip.purpose = purpose; trip.note = note
                    do { try context.save(); notice = "Zapisano trasę"; dismiss() }
                    catch { context.rollback(); self.error = error.localizedDescription }
                }
            }
        }.navigationTitle("Szczegóły trasy").modifier(FormKeyboard())
            .onAppear { if !loaded { category = trip.category; purpose = trip.purpose; note = trip.note; loaded = true } }
            .alert("Nie udało się zapisać", isPresented: Binding(get: { !error.isEmpty }, set: { if !$0 { error = "" } })) { Button("OK") {} } message: { Text(error) }
    }
}
