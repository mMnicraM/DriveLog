import Foundation
import SwiftUI

enum Formatters {
    static let currency: NumberFormatter = { let f = NumberFormatter(); f.numberStyle = .currency; f.currencyCode = "PLN"; f.locale = Locale(identifier: "pl_PL"); return f }()
    static func money(_ value: Double) -> String { currency.string(from: NSNumber(value: value)) ?? "\(value) zł" }
    static func distance(_ km: Double) -> String { String(format: "%.1f km", km) }
    static func duration(_ seconds: TimeInterval) -> String { let h = Int(seconds) / 3600; let m = (Int(seconds) % 3600) / 60; return "\(h) h \(m) min" }
}

struct MetricCard: View {
    let title: String, value: String
    var accent: Color = .primary
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased()).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title2.bold()).foregroundStyle(accent).minimumScaleFactor(0.7)
        }.frame(maxWidth: .infinity, alignment: .leading).padding().background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
    }
}
