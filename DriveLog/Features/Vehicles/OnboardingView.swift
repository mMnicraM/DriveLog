import SwiftUI
import SwiftData

struct OnboardingView: View {
    let completed: () -> Void
    var body: some View {
        NavigationStack { VehicleEditor(onboarding: true, completed: completed) }
    }
}

struct VehiclesView: View {
    @Query(sort: \Vehicle.createdAt) private var vehicles: [Vehicle]
    @State private var showingAdd = false
    var body: some View {
        List {
            Section("Twoje pojazdy") {
                ForEach(vehicles) { vehicle in
                    NavigationLink { VehicleEditor(vehicle: vehicle) } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "car.side").font(.title2).foregroundStyle(Brand.green)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(vehicle.displayName).font(.headline)
                                Text("\(vehicle.registration) · \(String(vehicle.year)) · \(vehicle.fuelType.rawValue)")
                                    .font(.subheadline).foregroundStyle(.secondary)
                                Text("\(EntryNumber.text(vehicle.odometer)) km").font(.caption).foregroundStyle(.secondary)
                            }
                        }.padding(.vertical, 4)
                    }
                }
            }
            Section("Dane") {
                NavigationLink { RecordsView() } label: { Label("Historia wpisów", systemImage: "clock.arrow.circlepath") }
                NavigationLink { PlatformSettingsView() } label: { Label("Platformy i prowizje", systemImage: "percent") }
                NavigationLink {
                    Form {
                        Section("Przechowywanie") {
                            Text("Wpisy i ślady GPS są przechowywane lokalnie na tym urządzeniu. Ta wersja nie synchronizuje ich z iCloud.")
                            Text("Mapa korzysta z usług Apple. Uprawnienia GPS możesz zmienić w ustawieniach systemowych.")
                        }
                        Section("Ważne") { Text("Odinstalowanie aplikacji może usunąć wszystkie jej dane. Eksport i kopia zapasowa nie są jeszcze dostępne.") }
                    }.navigationTitle("Prywatność")
                } label: { Label("Prywatność i dane", systemImage: "lock.shield") }
            }
            Section { Text("DriveLog 0.6.0 • wersja testowa").font(.caption).foregroundStyle(.secondary) }
        }.navigationTitle("Więcej")
            .toolbar { Button { showingAdd = true } label: { Image(systemName: "plus") } }
            .sheet(isPresented: $showingAdd) { NavigationStack { VehicleEditor() } }
    }
}

struct VehicleEditor: View {
    var vehicle: Vehicle? = nil
    var onboarding = false
    var completed: () -> Void = {}
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("activeVehicleID") private var activeVehicleID = ""
    @AppStorage("saveNotice") private var notice = ""
    @State private var make = ""
    @State private var model = ""
    @State private var registration = ""
    @State private var year = Calendar.current.component(.year, from: .now)
    @State private var odometer = ""
    @State private var fuel: FuelType = .petrol
    @State private var loaded = false
    @State private var error = ""
    private var valid: Bool {
        !make.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        EntryNumber.parse(odometer) != nil
    }
    var body: some View {
        Form {
            if onboarding {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Image("BrandIcon").resizable().scaledToFit().frame(width: 64, height: 64).clipShape(RoundedRectangle(cornerRadius: 16))
                        Text("Twój samochód.\nTwoje wyniki.").font(.largeTitle.bold())
                        Text("Dodaj pierwszy pojazd. Pozostałe informacje uzupełnisz w trakcie korzystania.").foregroundStyle(.secondary)
                    }.padding(.vertical, 10)
                }
            }
            Section("Dane pojazdu") {
                EntryField(title: "Marka", text: $make)
                EntryField(title: "Model", text: $model)
                EntryField(title: "Numer rejestracyjny", text: $registration, hint: "Opcjonalnie")
                    .textInputAutocapitalization(.characters)
                Picker("Rodzaj napędu", selection: $fuel) { ForEach(FuelType.allCases) { Text($0.rawValue).tag($0) } }
                Picker("Rok produkcji", selection: $year) {
                    ForEach((1980...(Calendar.current.component(.year, from: .now) + 1)).reversed(), id: \.self) {
                        Text(String($0)).tag($0)
                    }
                }
                EntryField(title: "Aktualny stan licznika", text: $odometer, unit: "km", hint: "Całkowity przebieg samochodu, nie długość jednej trasy.", numeric: true)
            }
            Section {
                if !valid { Text("Uzupełnij markę, model i nieujemny przebieg.").font(.footnote).foregroundStyle(.secondary) }
                Button(onboarding ? "Utwórz mój dziennik" : "Zapisz pojazd", action: save)
                    .disabled(!valid).frame(maxWidth: .infinity)
            }
        }.navigationTitle(onboarding ? "DriveLog" : (vehicle == nil ? "Nowy pojazd" : "Edytuj pojazd"))
            .navigationBarTitleDisplayMode(.inline).modifier(FormKeyboard())
            .scrollContentBackground(.hidden).background(Brand.background)
            .toolbar { if !onboarding { ToolbarItem(placement: .cancellationAction) { Button("Anuluj") { dismiss() } } } }
            .onAppear {
                guard !loaded else { return }; loaded = true
                if let vehicle {
                    make = vehicle.make; model = vehicle.model; registration = vehicle.registration
                    year = vehicle.year; fuel = vehicle.fuelType; odometer = EntryNumber.text(vehicle.odometer)
                }
            }
            .alert("Nie udało się zapisać", isPresented: Binding(get: { !error.isEmpty }, set: { if !$0 { error = "" } })) { Button("OK") {} } message: { Text(error) }
    }
    private func save() {
        guard valid, let distance = EntryNumber.parse(odometer) else { return }
        let item = vehicle ?? Vehicle(make: "", model: "", registration: "", year: year, fuelType: fuel, odometer: distance)
        if vehicle == nil { context.insert(item) }
        item.make = make.trimmingCharacters(in: .whitespacesAndNewlines)
        item.model = model.trimmingCharacters(in: .whitespacesAndNewlines)
        item.registration = registration.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        item.year = year; item.fuelTypeRaw = fuel.rawValue; item.odometer = distance
        do {
            try context.save()
            if activeVehicleID.isEmpty || onboarding { activeVehicleID = item.id.uuidString }
            notice = "Zapisano pojazd"
            if onboarding { completed() } else { dismiss() }
        } catch { context.rollback(); self.error = error.localizedDescription }
    }
}
