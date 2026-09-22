import SwiftUI
import SwiftData

struct RecordsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Income.date, order: .reverse) private var incomes: [Income]
    @Query(sort: \FuelEntry.date, order: .reverse) private var fuel: [FuelEntry]
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query(sort: \WorkShift.startedAt, order: .reverse) private var shifts: [WorkShift]
    @Query private var vehicles: [Vehicle]

    @State private var pendingDelete: (() -> Void)?
    @State private var showDelete = false
    @State private var error = ""

    var body: some View {
        List {
            if incomes.isEmpty && fuel.isEmpty && expenses.isEmpty && shifts.isEmpty {
                ContentUnavailableView("Brak wpisów", systemImage: "tray", description: Text("Dodane przychody, tankowania, koszty i zmiany pojawią się tutaj."))
            }
            if !incomes.isEmpty {
                Section("Przychody") {
                    ForEach(incomes) { item in
                        NavigationLink { FinanceEditor(kind: .income, income: item) } label: { RecordRow(icon: "banknote.fill", color: .green, title: item.platform, subtitle: item.date.formatted(date: .abbreviated, time: .shortened), amount: item.netAmount) }
                    }.onDelete { delete(incomes, at: $0) }
                }
            }
            if !fuel.isEmpty {
                Section("Tankowania i ładowania") {
                    ForEach(fuel) { item in
                        NavigationLink { FinanceEditor(kind: .fuel, fuel: item) } label: { RecordRow(icon: "fuelpump.fill", color: .orange, title: item.station.isEmpty ? "Tankowanie" : item.station, subtitle: "\(item.liters.formatted(.number.precision(.fractionLength(2)))) \(item.quantityUnit ?? (vehicles.first(where: { $0.id == item.vehicleID })?.fuelType == .electric ? "kWh" : "l")) · \(item.date.formatted(date: .abbreviated, time: .omitted))", amount: -item.total) }
                    }.onDelete { delete(fuel, at: $0) }
                }
            }
            if !expenses.isEmpty {
                Section("Koszty") {
                    ForEach(expenses) { item in
                        NavigationLink { FinanceEditor(kind: .expense, expense: item) } label: { RecordRow(icon: "wrench.and.screwdriver.fill", color: .red, title: item.category.rawValue, subtitle: item.details.isEmpty ? item.date.formatted(date: .abbreviated, time: .omitted) : item.details, amount: -item.amount) }
                    }.onDelete { delete(expenses, at: $0) }
                }
            }
            if !shifts.isEmpty {
                Section("Zmiany") {
                    ForEach(shifts) { shift in
                        NavigationLink { ShiftSummaryView(shift: shift) } label: {
                        HStack { VStack(alignment: .leading) { Text(shift.startedAt, format: .dateTime.day().month().hour().minute()).font(.headline); Text(shift.isActive ? "W toku" : Formatters.duration(shift.duration)).font(.caption).foregroundStyle(shift.isActive ? Brand.green : .secondary) }; Spacer(); Image(systemName: shift.isActive ? "timer.circle.fill" : "checkmark.circle").foregroundStyle(shift.isActive ? Brand.green : Color.secondary) }
                        }
                    } // Shifts are retained to preserve linked records.
                }
            }
        }.navigationTitle("Historia wpisów")
        .confirmationDialog("Usunąć wybrane wpisy? Tej operacji nie można cofnąć.", isPresented: $showDelete, titleVisibility: .visible) {
            Button("Usuń", role: .destructive) { pendingDelete?(); pendingDelete = nil }
            Button("Anuluj", role: .cancel) { pendingDelete = nil }
        }
        .alert("Nie udało się usunąć", isPresented: Binding(get: { !error.isEmpty }, set: { if !$0 { error = "" } })) { Button("OK") {} } message: { Text(error) }
    }

    private func delete<T: PersistentModel>(_ items: [T], at offsets: IndexSet) {
        let selected = offsets.map { items[$0] }
        pendingDelete = {
            selected.forEach { context.delete($0) }
            do { try context.save() } catch { context.rollback(); self.error = error.localizedDescription }
        }
        showDelete = true
    }
}

private struct RecordRow: View {
    let icon: String, color: Color, title: String, subtitle: String, amount: Double
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundStyle(color).frame(width: 34, height: 34).background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) { Text(title).font(.headline); Text(subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(1) }
            Spacer(); Text(Formatters.money(amount)).font(.subheadline.bold()).foregroundStyle(amount >= 0 ? Brand.green : Color.primary)
        }.padding(.vertical, 3)
    }
}
