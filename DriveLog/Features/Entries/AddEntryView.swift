import SwiftUI
import SwiftData

struct AddEntryView: View {
    var body: some View {
        List {
            Section("Nowy wpis") {
                NavigationLink { IncomeForm() } label: { Label("Przychód", systemImage: "banknote") }
                NavigationLink { FuelForm() } label: { Label("Tankowanie / ładowanie", systemImage: "fuelpump") }
                NavigationLink { ExpenseForm() } label: { Label("Koszt", systemImage: "wrench.and.screwdriver") }
                NavigationLink { ManualTripForm() } label: { Label("Trasa ręczna", systemImage: "map") }
            }
            Section("Zapisane dane") {
                NavigationLink { RecordsView() } label: { Label("Historia i edycja wpisów", systemImage: "clock.arrow.circlepath") }
            }
        }.navigationTitle("Dodaj wpis")
    }
}

enum EntryKind: String { case income = "Przychód", fuel = "Tankowanie / ładowanie", expense = "Koszt" }
struct IncomeForm: View { var body: some View { FinanceEditor(kind: .income) } }
struct FuelForm: View { var body: some View { FinanceEditor(kind: .fuel) } }
struct ExpenseForm: View { var body: some View { FinanceEditor(kind: .expense) } }

/// All fields are drafts: navigating back or cancelling never changes the database.
struct FinanceEditor: View {
    let kind: EntryKind
    var income: Income? = nil
    var fuel: FuelEntry? = nil
    var expense: Expense? = nil
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Vehicle.createdAt) private var vehicles: [Vehicle]
    @Query(sort: \WorkShift.startedAt, order: .reverse) private var shifts: [WorkShift]
    @AppStorage("activeVehicleID") private var activeVehicleID = ""
    @AppStorage("saveNotice") private var notice = ""
    @State private var vehicleID: UUID?
    @State private var shiftID: UUID?
    @State private var date = Date()
    @State private var amount = ""
    @State private var tips = "0"
    @State private var commission = "0"
    @State private var quantity = ""
    @State private var price = ""
    @State private var odometer = ""
    @State private var platform = "Uber"
    @State private var details = ""
    @State private var station = ""
    @State private var fullTank = true
    @State private var category: ExpenseCategory = .service
    @State private var loaded = false
    @State private var error = ""
    private var editing: Bool { income != nil || fuel != nil || expense != nil }
    private var vehicle: Vehicle? { vehicles.first { $0.id == vehicleID } }
    private var electric: Bool {
        if let fuel, fuel.vehicleID == vehicleID, let unit = fuel.quantityUnit { return unit == "kWh" }
        return vehicle?.fuelType == .electric
    }
    private var compatibleShifts: [WorkShift] { shifts.filter { $0.vehicleID == vehicleID } }
    private var problem: String? {
        if kind != .income && vehicleID == nil { return "Wybierz pojazd." }
        if let vehicleID, !vehicles.contains(where: { $0.id == vehicleID }) { return "Wybierz istniejący pojazd." }
        if let shiftID {
            guard let shift = compatibleShifts.first(where: { $0.id == shiftID }) else { return "Wybierz zmianę zgodną z pojazdem." }
            if date < shift.startedAt || date > (shift.endedAt ?? .now) { return "Data wpisu musi należeć do wybranej zmiany." }
        }
        if kind == .fuel {
            guard let q = EntryNumber.parse(quantity), q > 0,
                  let p = EntryNumber.parse(price), p > 0, (q * p).isFinite,
                  EntryNumber.parse(odometer) != nil else { return "Podaj ilość i cenę większe od zera oraz nieujemny przebieg." }
        } else {
            guard let a = EntryNumber.parse(amount), a > 0 else { return "Podaj kwotę większą od zera." }
            if kind == .income {
                guard let t = EntryNumber.parse(tips), let c = EntryNumber.parse(commission),
                      c <= a + t, (a + t).isFinite else { return "Napiwki i prowizja muszą być nieujemne; prowizja nie może przekroczyć sumy przychodu i napiwków." }
            }
        }
        return nil
    }
    var body: some View {
        Form {
            Section("Przypisanie") {
                Picker("Pojazd", selection: $vehicleID) {
                    Text(kind == .income ? "Bez przypisania" : "Wybierz pojazd").tag(nil as UUID?)
                    ForEach(vehicles) { Text($0.displayName).tag(Optional($0.id)) }
                }
                DatePicker("Data i godzina", selection: $date, in: ...Date.now)
                Picker("Zmiana", selection: $shiftID) {
                    Text("Poza zmianą").tag(nil as UUID?)
                    ForEach(compatibleShifts) { shift in
                        Text(shift.startedAt.formatted(date: .abbreviated, time: .shortened))
                            .tag(Optional(shift.id))
                    }
                }
            }
            if kind == .income {
                Section {
                    Picker("Źródło przychodu", selection: $platform) {
                        ForEach(Array(Set(["Uber", "Bolt", "FreeNow", "Glovo", "Wolt", "Inne", platform])).sorted(), id: \.self) { Text($0) }
                    }
                    EntryField(title: "Przychód przed prowizją", text: $amount, unit: "zł", hint: "Bez napiwków. Nie wpisuj tutaj wypłaty już pomniejszonej o prowizję.", numeric: true)
                    EntryField(title: "Napiwki", text: $tips, unit: "zł", numeric: true)
                    EntryField(title: "Prowizja platformy", text: $commission, unit: "zł", hint: "Wpisz 0, jeśli nie pobrano prowizji.", numeric: true)
                    LabeledContent("Po prowizji", value: Formatters.money((EntryNumber.parse(amount) ?? 0) + (EntryNumber.parse(tips) ?? 0) - (EntryNumber.parse(commission) ?? 0)))
                } header: { Text("Rozliczenie przychodu") }
            } else if kind == .fuel {
                Section("Zakup paliwa lub energii") {
                    EntryField(title: electric ? "Pobrana energia" : "Ilość paliwa", text: $quantity, unit: electric ? "kWh" : "l", numeric: true)
                    EntryField(title: "Cena jednostkowa", text: $price, unit: electric ? "zł/kWh" : "zł/l", numeric: true)
                    EntryField(title: "Stan licznika", text: $odometer, unit: "km", hint: "Całkowity przebieg pojazdu przy tym zakupie.", numeric: true)
                    EntryField(title: electric ? "Punkt ładowania" : "Stacja paliw", text: $station, hint: "Opcjonalnie")
                    if !electric { Toggle("Tankowanie do pełna", isOn: $fullTank) }
                    LabeledContent("Łączna kwota", value: Formatters.money((EntryNumber.parse(quantity) ?? 0) * (EntryNumber.parse(price) ?? 0)))
                }
            } else {
                Section("Wydatek") {
                    Picker("Kategoria kosztu", selection: $category) {
                        ForEach(ExpenseCategory.allCases) { Text($0.rawValue).tag($0) }
                    }
                    EntryField(title: "Zapłacona kwota", text: $amount, unit: "zł", numeric: true)
                }
            }
            if kind != .fuel { Section("Dodatkowe informacje") { EntryField(title: "Opis / notatka", text: $details, hint: "Opcjonalnie") } }
            Section {
                if let problem { Text(problem).font(.footnote).foregroundStyle(.secondary) }
                Button(editing ? "Zapisz zmiany" : "Zapisz wpis", action: save)
                    .disabled(problem != nil).frame(maxWidth: .infinity)
            }
        }
        .navigationTitle(editing ? "Edytuj wpis" : kind.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .modifier(FormKeyboard())
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Anuluj") { dismiss() } } }
        .onAppear(perform: load)
        .onChange(of: vehicleID) { _, _ in
            if let shiftID, !compatibleShifts.contains(where: { $0.id == shiftID }) { self.shiftID = nil }
        }
        .alert("Nie udało się zapisać", isPresented: Binding(get: { !error.isEmpty }, set: { if !$0 { error = "" } })) { Button("OK") {} } message: { Text(error) }
    }
    private func load() {
        guard !loaded else { return }
        loaded = true
        if let item = income {
            vehicleID = item.vehicleID; shiftID = item.shiftID; date = item.date
            amount = EntryNumber.text(item.amount); tips = EntryNumber.text(item.tips)
            commission = EntryNumber.text(item.commission); platform = item.platform; details = item.note
        } else if let item = fuel {
            vehicleID = item.vehicleID; shiftID = item.shiftID; date = item.date
            quantity = EntryNumber.text(item.liters); price = EntryNumber.text(item.pricePerUnit)
            odometer = EntryNumber.text(item.odometer); station = item.station; fullTank = item.fullTank
        } else if let item = expense {
            vehicleID = item.vehicleID; shiftID = item.shiftID; date = item.date
            amount = EntryNumber.text(item.amount); category = item.category; details = item.details
        } else {
            vehicleID = vehicles.first(where: { $0.id.uuidString == activeVehicleID })?.id ?? vehicles.first?.id
            shiftID = compatibleShifts.first(where: { $0.isActive })?.id
            odometer = vehicle.map { EntryNumber.text($0.odometer) } ?? ""
        }
    }
    private func save() {
        guard problem == nil else { return }
        switch kind {
        case .income:
            let item = income ?? Income(amount: 0, platform: platform)
            if income == nil { context.insert(item) }
            item.vehicleID = vehicleID; item.shiftID = shiftID; item.date = date
            item.amount = EntryNumber.parse(amount)!; item.tips = EntryNumber.parse(tips)!
            item.commission = EntryNumber.parse(commission)!; item.platform = platform; item.note = details
        case .fuel:
            guard let vehicleID else { return }
            let item = fuel ?? FuelEntry(vehicleID: vehicleID, odometer: 0, liters: 0, pricePerUnit: 0)
            if fuel == nil { context.insert(item) }
            item.vehicleID = vehicleID; item.shiftID = shiftID; item.date = date
            item.liters = EntryNumber.parse(quantity)!; item.pricePerUnit = EntryNumber.parse(price)!
            item.total = item.liters * item.pricePerUnit; item.odometer = EntryNumber.parse(odometer)!
            item.station = station; item.fullTank = electric ? false : fullTank
            item.quantityUnit = electric ? "kWh" : "l"
            // A receipt correction must not silently rewrite the vehicle's odometer.
        case .expense:
            guard let vehicleID else { return }
            let item = expense ?? Expense(vehicleID: vehicleID, amount: 0, category: category)
            if expense == nil { context.insert(item) }
            item.vehicleID = vehicleID; item.shiftID = shiftID; item.date = date
            item.amount = EntryNumber.parse(amount)!; item.categoryRaw = category.rawValue; item.details = details
        }
        do { try context.save(); notice = "Zapisano wpis"; dismiss() }
        catch { context.rollback(); self.error = error.localizedDescription }
    }
}

struct ManualTripForm: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Vehicle.createdAt) private var vehicles: [Vehicle]
    @Query(sort: \WorkShift.startedAt, order: .reverse) private var shifts: [WorkShift]
    @AppStorage("activeVehicleID") private var activeVehicleID = ""
    @AppStorage("saveNotice") private var notice = ""
    @State private var vehicleID: UUID?
    @State private var started = Date()
    @State private var ended = Date()
    @State private var km = ""
    @State private var purpose = ""
    @State private var category: TripCategory = .business
    @State private var error = ""
    private var valid: Bool { vehicleID != nil && (EntryNumber.parse(km) ?? 0) > 0 && ((EntryNumber.parse(km) ?? 0) * 1000).isFinite && ended > started }
    var body: some View {
        Form {
            Section("Pojazd i termin") {
                Picker("Pojazd", selection: $vehicleID) {
                    Text("Wybierz pojazd").tag(nil as UUID?)
                    ForEach(vehicles) { Text($0.displayName).tag(Optional($0.id)) }
                }
                DatePicker("Początek przejazdu", selection: $started, in: ...Date.now)
                DatePicker("Koniec przejazdu", selection: $ended, in: ...Date.now)
            }
            Section("Dane przejazdu") {
                EntryField(title: "Przejechany dystans", text: $km, unit: "km", numeric: true)
                Picker("Rodzaj przejazdu", selection: $category) { ForEach(TripCategory.allCases) { Text($0.rawValue).tag($0) } }
                EntryField(title: "Cel przejazdu", text: $purpose, hint: "Opcjonalnie")
                Text("Jeśli cały przejazd mieści się w zmianie tego auta, zostanie do niej automatycznie przypisany.").font(.footnote).foregroundStyle(.secondary)
            }
            Section {
                if !valid { Text("Wybierz auto, podaj dodatni dystans i koniec późniejszy niż początek.").font(.footnote).foregroundStyle(.secondary) }
                Button("Zapisz trasę") {
                    guard let vehicleID, let distance = EntryNumber.parse(km), valid else { return }
                    let trip = Trip(startedAt: started, endedAt: ended, distanceMeters: distance * 1000, vehicleID: vehicleID, category: category, purpose: purpose)
                    trip.shiftID = shifts.first { $0.vehicleID == vehicleID && started >= $0.startedAt && ended <= ($0.endedAt ?? .now) }?.id
                    context.insert(trip)
                    do { try context.save(); notice = "Zapisano trasę"; dismiss() }
                    catch { context.rollback(); self.error = error.localizedDescription }
                }.disabled(!valid)
            }
        }.navigationTitle("Trasa ręczna").modifier(FormKeyboard())
            .onAppear { if vehicleID == nil { vehicleID = vehicles.first(where: { $0.id.uuidString == activeVehicleID })?.id ?? vehicles.first?.id } }
            .alert("Nie udało się zapisać", isPresented: Binding(get: { !error.isEmpty }, set: { if !$0 { error = "" } })) { Button("OK") {} } message: { Text(error) }
    }
}
