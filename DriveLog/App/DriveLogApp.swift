import SwiftUI
import SwiftData

@main
struct DriveLogApp: App {
    private let container: ModelContainer?
    private let startupError: String?

    init() {
        do {
            let schema = Schema([
                Vehicle.self,
                Trip.self,
                FuelEntry.self,
                Expense.self,
                Income.self,
                WorkShift.self
            ])
            container = try ModelContainer(for: schema)
            startupError = nil
        } catch {
            container = nil
            startupError = error.localizedDescription
        }
    }

    var body: some Scene {
        WindowGroup {
            if let container {
                RootView()
                    .modelContainer(container)
            } else {
                DataStoreFailureView(message: startupError ?? "Nieznany błąd bazy danych.")
            }
        }
    }
}

private struct DataStoreFailureView: View {
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Image(systemName: "externaldrive.fill.badge.exclamationmark")
                .font(.system(size: 52))
                .foregroundStyle(.orange)
            Text("Nie udało się otworzyć danych")
                .font(.title.bold())
            Text("Nie usuwaj aplikacji ani jej danych. Zamknij DriveLog, zachowaj kopię urządzenia i przekaż poniższy komunikat do diagnostyki.")
                .foregroundStyle(.secondary)
            Text(message)
                .font(.footnote.monospaced())
                .textSelection(.enabled)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
            Text("DriveLog nie utworzył zastępczej pustej bazy.")
                .font(.footnote.weight(.semibold))
        }
        .padding(24)
        .frame(maxWidth: 620, maxHeight: .infinity, alignment: .center)
        .background(Brand.background.ignoresSafeArea())
    }
}
