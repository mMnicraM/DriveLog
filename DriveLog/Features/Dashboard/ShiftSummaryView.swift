import SwiftUI
import SwiftData

struct ShiftSummaryView: View {
    let shift: WorkShift
    @Environment(\.dismiss) private var dismiss
    @Query private var incomes: [Income]
    @Query private var expenses: [Expense]
    @Query private var fuel: [FuelEntry]
    @Query private var trips: [Trip]
    private var income: Double { incomes.filter { $0.shiftID == shift.id }.reduce(0) { $0 + $1.netAmount } }
    private var costs: Double {
        fuel.filter { $0.shiftID == shift.id }.reduce(0) { $0 + $1.total } +
        expenses.filter { $0.shiftID == shift.id }.reduce(0) { $0 + $1.amount }
    }
    private var km: Double { trips.filter { $0.shiftID == shift.id }.reduce(0) { $0 + $1.distanceKM } }
    private var pendingSettlements: Int {
        trips.filter { $0.shiftID == shift.id && $0.settlementState == .pending }.count
    }
    var body: some View {
        Form {
            Section("Czas pracy") {
                LabeledContent("Początek", value: shift.startedAt.formatted(date: .abbreviated, time: .shortened))
                if let end = shift.endedAt { LabeledContent("Koniec", value: end.formatted(date: .abbreviated, time: .shortened)) }
                LabeledContent("Czas zmiany", value: Formatters.duration(shift.duration))
            }
            Section("Wpisy przypisane do zmiany") {
                LabeledContent("Przychód po prowizji", value: Formatters.money(income))
                LabeledContent("Wydatki", value: Formatters.money(costs))
                LabeledContent("Saldo", value: Formatters.money(income - costs))
                LabeledContent("Dystans", value: Formatters.distance(km))
                LabeledContent("Saldo / godzinę zmiany", value: shift.duration > 0 ? Formatters.money((income - costs) / (shift.duration / 3600)) : "—")
            }
            if pendingSettlements > 0 {
                Section {
                    Label("\(pendingSettlements) \(pendingSettlements == 1 ? "przejazd czeka" : "przejazdy czekają") na rozliczenie", systemImage: "exclamationmark.circle.fill")
                        .foregroundStyle(.orange)
                    Text("Saldo zmiany może być zaniżone, dopóki nie uzupełnisz tych przychodów.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            Section { Text("Uwzględniono wyłącznie wpisy powiązane ze zmianą. Starsze dane nie są przypisywane automatycznie. Nie jest to wynik podatkowy ani pełny koszt eksploatacji.").font(.footnote).foregroundStyle(.secondary) }
        }.navigationTitle("Podsumowanie zmiany")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Gotowe") { dismiss() } } }
    }
}
