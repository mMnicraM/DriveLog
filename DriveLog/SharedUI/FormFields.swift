import SwiftUI
import UIKit

enum EntryNumber {
    static func parse(_ text: String) -> Double? {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        guard !clean.isEmpty, clean.allSatisfy({ $0.isASCII && ($0.isNumber || $0 == ".") }),
              let value = Double(clean), value.isFinite else { return nil }
        return value
    }
    static func text(_ value: Double) -> String {
        value.formatted(.number.grouping(.never).precision(.fractionLength(0...6)).locale(Locale(identifier: "pl_PL")))
    }
}

/// The title remains visible when the field contains a value.
struct EntryField: View {
    let title: String
    @Binding var text: String
    var unit = ""
    var hint = ""
    var numeric = false
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title).font(.subheadline.weight(.semibold))
            HStack(alignment: .firstTextBaseline) {
                TextField(numeric ? "Wpisz wartość" : "Wpisz tutaj", text: $text)
                    .keyboardType(numeric ? .decimalPad : .default)
                    .accessibilityLabel(Text(unit.isEmpty ? title : "\(title), \(unit)"))
                if !unit.isEmpty { Text(unit).foregroundStyle(.secondary) }
            }
            if !hint.isEmpty { Text(hint).font(.caption).foregroundStyle(.secondary) }
        }.padding(.vertical, 5)
    }
}

struct FormKeyboard: ViewModifier {
    func body(content: Content) -> some View {
        content.scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Gotowe") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            }
    }
}

struct SaveNotice: ViewModifier {
    @AppStorage("saveNotice") private var notice = ""
    func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            if !notice.isEmpty {
                Label(notice, systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .padding().background(.regularMaterial, in: Capsule())
                    .padding(.top, 8).allowsHitTesting(false)
            }
        }.task(id: notice) {
            guard !notice.isEmpty else { return }
            do { try await Task.sleep(for: .seconds(2)); notice = "" } catch {}
        }
    }
}
