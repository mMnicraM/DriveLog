import SwiftUI

enum Brand {
    static let green = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(red: 0.22, green: 0.83, blue: 0.53, alpha: 1) : UIColor(red: 0.02, green: 0.43, blue: 0.26, alpha: 1)
    })
    static let background = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor.systemGroupedBackground : UIColor(red: 0.965, green: 0.961, blue: 0.945, alpha: 1)
    })
    static let deepGreen = Color(red: 0.02, green: 0.24, blue: 0.18)
    static let mint = Color(red: 0.64, green: 1.0, blue: 0.78)
    static let ink = Color(red: 0.04, green: 0.08, blue: 0.07)
    static let gradient = LinearGradient(colors: [deepGreen, Color(red: 0.01, green: 0.08, blue: 0.07)], startPoint: .topLeading, endPoint: .bottomTrailing)
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Brand.green.opacity(configuration.isPressed ? 0.72 : 1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .foregroundStyle(.white)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct SectionHeader: View {
    let title: String
    let subtitle: String?
    init(_ title: String, subtitle: String? = nil) { self.title = title; self.subtitle = subtitle }
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.title3.bold())
            if let subtitle { Text(subtitle).font(.subheadline).foregroundStyle(.secondary) }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}
