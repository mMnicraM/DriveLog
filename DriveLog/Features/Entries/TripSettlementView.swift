import Foundation
import SwiftUI
import SwiftData

struct TripSettlementView: View {
    let trip: Trip
    var onFinish: () -> Void = {}

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var vehicles: [Vehicle]
    @AppStorage("activeIncomePlatform") private var activePlatform = IncomePlatform.uber.rawValue
    @AppStorage("saveNotice") private var notice = ""

    @State private var platform = IncomePlatform.uber.rawValue
    @State private var fare = ""
    @State private var tips = "0"
    @State private var commissionPercentage = "0"
    @State private var note = ""
    @State private var loaded = false
    @State private var error = ""

    private var fareValue: Double { EntryNumber.parse(fare) ?? 0 }
    private var tipsValue: Double { EntryNumber.parse(tips) ?? 0 }
    private var percentageValue: Double { EntryNumber.parse(commissionPercentage) ?? 0 }
    private var commissionValue: Double {
        TripSettlementCalculator.commission(fare: fareValue, percentage: percentageValue)
    }
    private var netValue: Double {
        TripSettlementCalculator.net(fare: fareValue, tips: tipsValue, percentage: percentageValue)
    }
    private var problem: String? {
        guard let fare = EntryNumber.parse(fare), fare > 0 else { return "Podaj kwotę kursu większą od zera." }
        guard let tips = EntryNumber.parse(tips), tips >= 0 else {
            return "Napiwek nie może być liczbą ujemną. Wpisz 0, jeśli go nie było."
        }
        guard let rate = EntryNumber.parse(commissionPercentage), (0...100).contains(rate) else {
            return "Prowizja musi mieścić się w zakresie od 0 do 100%."
        }
        return nil
    }
    private var vehicleName: String {
        vehicles.first { $0.id == trip.vehicleID }?.displayName ?? "Przypisany pojazd"
    }

    var body: some View {
        Form {
            Section("Zakończony przejazd") {
                LabeledContent("Samochód", value: vehicleName)
                LabeledContent("Zakończenie", value: trip.endedAt.formatted(date: .abbreviated, time: .shortened))
                LabeledContent("Dystans", value: Formatters.distance(trip.distanceKM))
                LabeledContent("Czas", value: Formatters.duration(trip.duration))
            }

            Section {
                Picker("Źródło przychodu", selection: $platform) {
                    ForEach(IncomePlatform.allCases) { Text($0.rawValue).tag($0.rawValue) }
                }
                EntryField(
                    title: "Kwota kursu przed prowizją",
                    text: $fare,
                    unit: "zł",
                    hint: "Kwota za przejazd bez napiwku.",
                    numeric: true
                )
                EntryField(title: "Napiwek", text: $tips, unit: "zł", numeric: true)
                EntryField(
                    title: "Prowizja platformy",
                    text: $commissionPercentage,
                    unit: "%",
                    hint: "Podstawiona z ustawień platformy; możesz ją zmienić dla tego kursu.",
                    numeric: true
                )
                LabeledContent("Prowizja", value: Formatters.money(commissionValue))
                LabeledContent("Zostaje po prowizji", value: Formatters.money(netValue))
                    .fontWeight(.semibold)
            } header: {
                Text("Szybkie rozliczenie")
            }

            Section("Dodatkowe informacje") {
                EntryField(title: "Notatka", text: $note, hint: "Opcjonalnie")
            }

            Section {
                if let problem { Text(problem).font(.footnote).foregroundStyle(.secondary) }
                Button("Zapisz przychód", action: saveIncome)
                    .disabled(problem != nil)
                    .frame(maxWidth: .infinity)
                Button("Przejazd prywatny — bez przychodu", action: markPrivate)
                    .frame(maxWidth: .infinity)
                Button("Uzupełnię później", action: markForLater)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Rozlicz przejazd")
        .navigationBarTitleDisplayMode(.inline)
        .modifier(FormKeyboard())
        .interactiveDismissDisabled()
        .onAppear(perform: load)
        .onChange(of: platform) { _, value in
            guard loaded else { return }
            activePlatform = value
            commissionPercentage = EntryNumber.text(PlatformCommissionStore.percentage(for: value))
        }
        .alert("Nie udało się zapisać", isPresented: Binding(
            get: { !error.isEmpty },
            set: { if !$0 { error = "" } }
        )) { Button("OK") {} } message: { Text(error) }
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        platform = IncomePlatform(rawValue: activePlatform)?.rawValue ?? IncomePlatform.uber.rawValue
        commissionPercentage = EntryNumber.text(PlatformCommissionStore.percentage(for: platform))
    }

    private func saveIncome() {
        guard problem == nil,
              let fare = EntryNumber.parse(fare),
              let tips = EntryNumber.parse(tips),
              let percentage = EntryNumber.parse(commissionPercentage) else { return }

        let income = Income(
            date: trip.endedAt,
            amount: fare,
            platform: platform,
            tips: tips,
            commission: TripSettlementCalculator.commission(fare: fare, percentage: percentage),
            note: note,
            tripID: trip.id
        )
        income.vehicleID = trip.vehicleID
        income.shiftID = trip.shiftID
        context.insert(income)
        trip.category = .business
        trip.settlementState = .settled

        do {
            try context.save()
            activePlatform = platform
            notice = "Zapisano trasę i przychód"
            finish()
        } catch {
            context.rollback()
            self.error = error.localizedDescription
        }
    }

    private func markPrivate() {
        trip.category = .privateTrip
        trip.settlementState = .noIncome
        do {
            try context.save()
            notice = "Zapisano przejazd prywatny"
            finish()
        } catch {
            context.rollback()
            self.error = error.localizedDescription
        }
    }

    private func markForLater() {
        trip.settlementState = .pending
        do {
            try context.save()
            notice = "Trasa czeka na rozliczenie"
            finish()
        } catch {
            context.rollback()
            self.error = error.localizedDescription
        }
    }

    private func finish() {
        dismiss()
        DispatchQueue.main.async { onFinish() }
    }
}

struct PlatformSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("activeIncomePlatform") private var activePlatform = IncomePlatform.uber.rawValue
    @AppStorage("saveNotice") private var notice = ""
    @State private var rates: [String: String] = [:]
    @State private var loaded = false

    private var problem: String? {
        for platform in IncomePlatform.allCases {
            guard let value = EntryNumber.parse(rates[platform.rawValue] ?? ""), (0...100).contains(value) else {
                return "Każda prowizja musi mieścić się w zakresie od 0 do 100%."
            }
        }
        return nil
    }

    var body: some View {
        Form {
            Section("Domyślne źródło") {
                Picker("Aktywna platforma", selection: $activePlatform) {
                    ForEach(IncomePlatform.allCases) { Text($0.rawValue).tag($0.rawValue) }
                }
                Text("Ta platforma będzie podpowiadana po zakończeniu trasy. Nadal można zmienić ją w rozliczeniu.")
                    .font(.footnote).foregroundStyle(.secondary)
            }

            Section {
                ForEach(IncomePlatform.allCases) { platform in
                    EntryField(
                        title: platform.rawValue,
                        text: rateBinding(for: platform),
                        unit: "%",
                        numeric: true
                    )
                }
            } header: {
                Text("Domyślna prowizja")
            } footer: {
                Text("Stawki zależą od umowy, miasta i promocji. DriveLog nie narzuca wartości — wpisz swoje rzeczywiste prowizje.")
            }

            Section {
                if let problem { Text(problem).font(.footnote).foregroundStyle(.secondary) }
                Button("Zapisz ustawienia", action: save)
                    .disabled(problem != nil)
                    .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Platformy i prowizje")
        .navigationBarTitleDisplayMode(.inline)
        .modifier(FormKeyboard())
        .onAppear(perform: load)
    }

    private func rateBinding(for platform: IncomePlatform) -> Binding<String> {
        Binding(
            get: { rates[platform.rawValue] ?? "0" },
            set: { rates[platform.rawValue] = $0 }
        )
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        for platform in IncomePlatform.allCases {
            rates[platform.rawValue] = EntryNumber.text(
                PlatformCommissionStore.percentage(for: platform.rawValue)
            )
        }
    }

    private func save() {
        guard problem == nil else { return }
        for platform in IncomePlatform.allCases {
            guard let value = EntryNumber.parse(rates[platform.rawValue] ?? "") else { return }
            PlatformCommissionStore.setPercentage(value, for: platform.rawValue)
        }
        notice = "Zapisano ustawienia platform"
        dismiss()
    }
}
