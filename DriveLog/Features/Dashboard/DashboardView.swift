import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Environment(\.modelContext) private var context
    @Query private var trips: [Trip]
    @Query private var fuel: [FuelEntry]
    @Query private var expenses: [Expense]
    @Query private var incomes: [Income]
    @Query private var vehicles: [Vehicle]
    @Query(sort: \WorkShift.startedAt, order: .reverse) private var shifts: [WorkShift]
    @AppStorage("activeVehicleID") private var activeVehicleID = ""
    @AppStorage("hasRecordingDraft") private var hasRecordingDraft = false
    @State private var period: ReportPeriod = .day
    @State private var filterActive = false
    @State private var finishedShift: WorkShift?
    @State private var saveError = ""

    private var interval: DateInterval { period.interval() }
    private var summary: ProfitabilitySummary { ProfitabilityCalculator.calculate(trips: trips, fuel: fuel, expenses: expenses, incomes: incomes, interval: interval, vehicleID: filterActive ? activeVehicle?.id : nil) }

    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 16) {
                header
                activeVehicleCard
                if hasRecordingDraft { recoveryBanner }
                Picker("Okres", selection: $period) { ForEach(ReportPeriod.allCases) { Text($0.rawValue).tag($0) } }.pickerStyle(.segmented)
                Toggle("Tylko aktywny samochód", isOn: $filterActive).font(.subheadline)
                profitCard
                HStack(spacing: 12) {
                    MiniMetric(icon: "road.lanes", label: "Dystans", value: Formatters.distance(summary.distanceKM))
                    MiniMetric(icon: "clock.fill", label: "Czas jazdy", value: Formatters.duration(summary.workSeconds))
                }
                HStack(spacing: 12) {
                    MiniMetric(icon: "hourglass", label: "Saldo / h jazdy", value: summary.workSeconds > 0 ? Formatters.money(summary.profitPerHour) : "—")
                    MiniMetric(icon: "speedometer", label: "Saldo / km", value: summary.distanceKM > 0 ? Formatters.money(summary.profitPerKM) : "—")
                }
                shiftCard
                NavigationLink { RecordingView() } label: { Label("Rozpocznij trasę", systemImage: "location.fill") }.buttonStyle(PrimaryButtonStyle())
                if unclassifiedCount > 0 { classificationBanner }
                quickActions
                Text("Saldo to przychody po prowizji minus zapisane wydatki. Nie uwzględnia podatków ani amortyzacji. Paliwo jest kosztem w dniu zakupu, a nie zużycia. Kilometry i czas dotyczą tras oznaczonych jako służbowe.")
                    .font(.footnote).foregroundStyle(.secondary)
                Text("DriveLog 0.5.4").font(.caption2).foregroundStyle(.secondary).accessibilityIdentifier("dashboard.bottom")
            }.padding(.horizontal, 18).padding(.bottom, 96)
        }
        .scrollIndicators(.visible)
        .scrollBounceBehavior(.always)
        .accessibilityIdentifier("dashboard.scroll")
        .background(Brand.background)
        .navigationTitle("Start").navigationBarTitleDisplayMode(.inline)
        .sheet(item: $finishedShift) { shift in NavigationStack { ShiftSummaryView(shift: shift) } }
        .alert("Nie udało się zapisać zmiany", isPresented: Binding(get: { !saveError.isEmpty }, set: { if !$0 { saveError = "" } })) { Button("OK") {} } message: { Text(saveError) }
    }

    private var activeVehicle: Vehicle? {
        vehicles.first { $0.id.uuidString == activeVehicleID } ?? vehicles.first
    }

    private var recoveryBanner: some View {
        NavigationLink { RecordingView() } label: {
            HStack(spacing: 13) {
                Image(systemName: "arrow.clockwise.circle.fill")
                    .font(.title2).foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Niedokończona trasa").font(.headline).foregroundStyle(.primary)
                    Text("Otwórz, aby kontynuować, zapisać albo odrzucić kopię roboczą.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(.tertiary)
            }
            .padding(15)
            .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 18))
        }.buttonStyle(.plain)
    }

    private var activeShift: WorkShift? { shifts.first { $0.isActive } }

    private var activeVehicleCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "car.side.fill").foregroundStyle(Brand.green).frame(width: 38, height: 38).background(Brand.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 11))
            VStack(alignment: .leading, spacing: 2) {
                Text("Aktywny samochód").font(.caption).foregroundStyle(.secondary)
                Text(activeVehicle?.displayName ?? "Brak pojazdu").font(.headline)
            }
            Spacer()
            if vehicles.count > 1 && activeShift == nil {
                Menu {
                    ForEach(vehicles) { vehicle in
                        Button { activeVehicleID = vehicle.id.uuidString } label: {
                            if vehicle.id == activeVehicle?.id { Label(vehicle.displayName, systemImage: "checkmark") }
                            else { Text(vehicle.displayName) }
                        }
                    }
                } label: { Label("Zmień", systemImage: "chevron.up.chevron.down").font(.subheadline.weight(.semibold)) }
            }
        }.padding(14).background(.background, in: RoundedRectangle(cornerRadius: 18))
    }

    private var shiftCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(activeShift == nil ? "ZMIANA NIEAKTYWNA" : "ZMIANA W TOKU").font(.caption.bold()).foregroundStyle(activeShift == nil ? Color.secondary : Brand.green)
                    if let shift = activeShift {
                        TimelineView(.periodic(from: .now, by: 1)) { timeline in
                            Text(Formatters.duration(timeline.date.timeIntervalSince(shift.startedAt))).font(.title2.bold().monospacedDigit())
                        }
                    } else { Text("Rozpocznij, aby mierzyć czas pracy").font(.subheadline).foregroundStyle(.secondary) }
                }
                Spacer(); Image(systemName: activeShift == nil ? "timer" : "timer.circle.fill").font(.title).foregroundStyle(activeShift == nil ? Color.secondary : Brand.green)
            }
            Button(action: toggleShift) {
                Text(activeShift == nil ? "Rozpocznij zmianę" : "Zakończ zmianę")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        activeShift == nil ? Brand.green.opacity(0.12) : Color.red.opacity(0.12),
                        in: RoundedRectangle(cornerRadius: 13)
                    )
                    .foregroundStyle(activeShift == nil ? Brand.green : .red)
                    .contentShape(Rectangle())
            }
                .buttonStyle(.plain)
                .disabled(activeVehicle == nil)
        }.padding(16).background(.background, in: RoundedRectangle(cornerRadius: 20))
    }

    private func toggleShift() {
        if let activeShift {
            activeShift.endedAt = .now
            do { try context.save(); finishedShift = activeShift }
            catch { context.rollback(); saveError = error.localizedDescription }
        } else if let vehicle = activeVehicle {
            context.insert(WorkShift(vehicleID: vehicle.id))
            do { try context.save(); activeVehicleID = vehicle.id.uuidString }
            catch { context.rollback(); saveError = error.localizedDescription }
        }
    }

    private var unclassifiedCount: Int { trips.filter { $0.category == .unclassified }.count }

    private var classificationBanner: some View {
        NavigationLink { TripsView() } label: {
            HStack(spacing: 13) {
                Image(systemName: "questionmark.circle.fill").font(.title2).foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Trasy do sklasyfikowania").font(.headline).foregroundStyle(.primary)
                    Text("\(unclassifiedCount) \(unclassifiedCount == 1 ? "przejazd wymaga" : "przejazdów wymaga") decyzji").font(.caption).foregroundStyle(.secondary)
                }
                Spacer(); Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(.tertiary)
            }.padding(15).background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 18))
        }.buttonStyle(.plain)
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text(Date.now, format: .dateTime.weekday(.wide).day().month(.wide)).font(.subheadline).foregroundStyle(.secondary)
                Text("Dzień dobry").font(.largeTitle.bold())
            }
            Spacer()
            Image("BrandIcon").resizable().scaledToFit().frame(width: 50, height: 50).clipShape(RoundedRectangle(cornerRadius: 14))
        }.padding(.top, 12)
    }

    private var profitCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("SALDO • \(period.rawValue.uppercased())").font(.caption.bold()).foregroundStyle(.white.opacity(0.8))
                Spacer()
                Label(resultStatus.title, systemImage: resultStatus.icon)
                    .font(.caption2.bold())
                    .foregroundStyle(resultStatus.color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.09), in: Capsule())
            }
            Text(Formatters.money(summary.profit)).font(.system(size: 42, weight: .bold, design: .rounded)).foregroundStyle(.white).minimumScaleFactor(0.7)
            HStack(spacing: 0) {
                ProfitPart(label: "Przychód", value: summary.income, color: Brand.mint)
                Rectangle().fill(.white.opacity(0.18)).frame(width: 1, height: 40).padding(.horizontal, 18)
                ProfitPart(label: "Koszty", value: summary.costs, color: .orange)
            }
            Chart {
                BarMark(x: .value("Typ", "Przychód"), y: .value("Kwota", summary.income)).foregroundStyle(Brand.mint)
                BarMark(x: .value("Typ", "Koszty"), y: .value("Kwota", summary.costs)).foregroundStyle(.orange)
            }.chartXAxis(.hidden).chartYAxis(.hidden).frame(height: 48).allowsHitTesting(false)
        }.padding(20).background(Brand.gradient, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var resultStatus: (title: String, icon: String, color: Color) {
        guard summary.income > 0 || summary.costs > 0 else { return ("BRAK DANYCH", "minus", .white.opacity(0.65)) }
        if abs(summary.profit) < 0.005 { return ("NA ZERO", "equal", Brand.mint) }
        return summary.profit >= 0 ? ("NA PLUSIE", "checkmark.circle.fill", Brand.mint) : ("NA MINUSIE", "exclamationmark.circle.fill", .orange)
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Szybkie akcje", subtitle: "Dodaj wpis bez szukania go w menu")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                NavigationLink { IncomeForm() } label: { QuickAction(title: "Przychód", icon: "banknote.fill", color: .green) }
                NavigationLink { FuelForm() } label: { QuickAction(title: "Tankowanie", icon: "fuelpump.fill", color: .orange) }
                NavigationLink { ExpenseForm() } label: { QuickAction(title: "Koszt", icon: "wrench.and.screwdriver.fill", color: .red) }
                NavigationLink { ManualTripForm() } label: { QuickAction(title: "Trasa ręczna", icon: "map.fill", color: .blue) }
            }.buttonStyle(.plain)
        }
    }
}

private struct ProfitPart: View {
    let label: String, value: Double, color: Color
    var body: some View { VStack(alignment: .leading, spacing: 4) { Text(label).font(.caption).foregroundStyle(.white.opacity(0.62)); Text(Formatters.money(value)).font(.headline).foregroundStyle(color) }.frame(maxWidth: .infinity, alignment: .leading) }
}

private struct MiniMetric: View {
    let icon: String, label: String, value: String
    var body: some View { HStack(spacing: 12) { Image(systemName: icon).foregroundStyle(Brand.green).frame(width: 34, height: 34).background(Brand.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 10)); VStack(alignment: .leading, spacing: 2) { Text(label).font(.caption).foregroundStyle(.secondary); Text(value).font(.headline) } }.frame(maxWidth: .infinity, alignment: .leading).padding(14).background(.background, in: RoundedRectangle(cornerRadius: 18)) }
}

private struct QuickAction: View {
    let title: String, icon: String, color: Color
    var body: some View { HStack(spacing: 10) { Image(systemName: icon).font(.title3).foregroundStyle(color).frame(width: 30); Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(.primary); Spacer(); Image(systemName: "chevron.right").font(.caption2.bold()).foregroundStyle(.tertiary) }.frame(maxWidth: .infinity).padding(14).background(.background, in: RoundedRectangle(cornerRadius: 16)).contentShape(Rectangle()) }
}

struct StatisticsView: View {
    @Query private var trips: [Trip]
    @Query private var fuel: [FuelEntry]
    @Query private var expenses: [Expense]
    @Query private var incomes: [Income]
    @Query private var vehicles: [Vehicle]
    @State private var period: ReportPeriod = .month
    @State private var vehicleID: UUID?
    private let calendar = Calendar.current

    private var monthInterval: DateInterval {
        period.interval()
    }

    private var month: ProfitabilitySummary {
        ProfitabilityCalculator.calculate(trips: trips, fuel: fuel, expenses: expenses, incomes: incomes, interval: monthInterval, vehicleID: vehicleID)
    }

    private var lastSevenDays: [DailyAnalyticsPoint] {
        (0..<7).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: calendar.startOfDay(for: .now)),
                  let end = calendar.date(byAdding: .day, value: 1, to: date) else { return nil }
            let result = ProfitabilityCalculator.calculate(trips: trips, fuel: fuel, expenses: expenses, incomes: incomes, interval: DateInterval(start: date, end: end), vehicleID: vehicleID)
            return DailyAnalyticsPoint(date: date, income: result.income, costs: result.costs, profit: result.profit)
        }
    }

    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 18) {
                Picker("Okres podsumowania", selection: $period) {
                    ForEach(ReportPeriod.allCases) { Text($0.rawValue).tag($0) }
                }.pickerStyle(.segmented)
                Picker("Pojazd", selection: $vehicleID) {
                    Text("Wszystkie pojazdy").tag(nil as UUID?)
                    ForEach(vehicles) { Text($0.displayName).tag(Optional($0.id)) }
                }
                SectionHeader("Podsumowanie", subtitle: period.rawValue)
                HStack(spacing: 12) {
                    MetricCard(title: "Przychód", value: Formatters.money(month.income), accent: Brand.green)
                    MetricCard(title: "Koszty", value: Formatters.money(month.costs), accent: .orange)
                }
                MetricCard(title: "Saldo", value: Formatters.money(month.profit), accent: month.profit >= 0 ? Brand.green : .red)
                Text("Starsze przychody bez przypisanego auta są widoczne tylko przy wyborze wszystkich pojazdów. Saldo to przychód po prowizji minus zapisane wydatki, nie pełny zysk.").font(.footnote).foregroundStyle(.secondary)
                incomeCostChart
                profitTrendChart
                HStack(spacing: 12) {
                    MiniMetric(icon: "road.lanes", label: "Kilometry", value: Formatters.distance(month.distanceKM))
                    MiniMetric(icon: "clock.fill", label: "Czas jazdy", value: Formatters.duration(month.workSeconds))
                }
                HStack(spacing: 12) {
                    MiniMetric(icon: "speedometer", label: "Saldo / km", value: month.distanceKM > 0 ? Formatters.money(month.profitPerKM) : "—")
                    MiniMetric(icon: "hourglass", label: "Saldo / h jazdy", value: month.workSeconds > 0 ? Formatters.money(month.profitPerHour) : "—")
                }
            }.padding(18)
        }
        .scrollIndicators(.visible)
        .background(Brand.background)
        .navigationTitle("Analiza")
    }

    private var incomeCostChart: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader("Przychody i koszty", subtitle: "Ostatnie 7 dni • zł")
            if lastSevenDays.allSatisfy({ $0.income == 0 && $0.costs == 0 }) { Text("Brak wpisów w ostatnich 7 dniach. Dodaj pierwszy przychód lub koszt.").font(.footnote).foregroundStyle(.secondary) }
            Chart(lastSevenDays) { point in
                BarMark(x: .value("Dzień", point.date, unit: .day), y: .value("Kwota", point.income))
                    .foregroundStyle(by: .value("Typ", "Przychód"))
                    .position(by: .value("Typ", "Przychód"))
                BarMark(x: .value("Dzień", point.date, unit: .day), y: .value("Kwota", point.costs))
                    .foregroundStyle(by: .value("Typ", "Koszty"))
                    .position(by: .value("Typ", "Koszty"))
            }
            .chartForegroundStyleScale(["Przychód": Brand.green, "Koszty": Color.orange])
            .chartXAxis { AxisMarks(values: .stride(by: .day)) { _ in AxisGridLine().foregroundStyle(.clear); AxisValueLabel(format: .dateTime.weekday(.narrow)) } }
            .chartYAxis { AxisMarks(position: .leading) { value in AxisGridLine(); AxisValueLabel { if let amount = value.as(Double.self) { Text(amount.formatted(.number.notation(.compactName))) } } } }
            .frame(height: 210)
            .allowsHitTesting(false)
        }.padding(16).background(.background, in: RoundedRectangle(cornerRadius: 22))
    }

    private var profitTrendChart: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader("Trend salda", subtitle: "Ostatnie 7 dni • zł")
            Chart(lastSevenDays) { point in
                AreaMark(x: .value("Dzień", point.date, unit: .day), y: .value("Saldo", point.profit))
                    .foregroundStyle(LinearGradient(colors: [Brand.green.opacity(0.34), Brand.green.opacity(0.02)], startPoint: .top, endPoint: .bottom))
                LineMark(x: .value("Dzień", point.date, unit: .day), y: .value("Saldo", point.profit))
                    .foregroundStyle(Brand.green).lineStyle(.init(lineWidth: 3, lineCap: .round, lineJoin: .round)).symbol(Circle())
                RuleMark(y: .value("Zero", 0)).foregroundStyle(.secondary.opacity(0.35)).lineStyle(.init(dash: [4]))
            }
            .chartXAxis { AxisMarks(values: .stride(by: .day)) { _ in AxisValueLabel(format: .dateTime.weekday(.narrow)) } }
            .chartYAxis { AxisMarks(position: .leading) }
            .frame(height: 165)
            .allowsHitTesting(false)
        }.padding(16).background(.background, in: RoundedRectangle(cornerRadius: 22))
    }
}

private struct DailyAnalyticsPoint: Identifiable {
    let date: Date
    let income: Double
    let costs: Double
    let profit: Double
    var id: Date { date }
}
