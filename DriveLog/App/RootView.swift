import SwiftUI
import SwiftData

struct RootView: View {
    @Query private var vehicles: [Vehicle]
    @AppStorage("didCompleteOnboarding") private var didCompleteOnboarding = false
    @State private var showsSplash = true

    var body: some View {
        ZStack {
            if didCompleteOnboarding && !vehicles.isEmpty { MainTabView() }
            else { OnboardingView { didCompleteOnboarding = true } }
            if showsSplash { LaunchView().transition(.opacity.combined(with: .scale(scale: 1.03))) }
        }
        .task {
            try? await Task.sleep(for: .seconds(1.25))
            withAnimation(.easeInOut(duration: 0.45)) { showsSplash = false }
        }
    }
}

private struct LaunchView: View {
    var body: some View {
        ZStack {
            Brand.gradient.ignoresSafeArea()
            VStack(spacing: 18) {
                Image("BrandIcon").resizable().scaledToFit().frame(width: 152, height: 152)
                    .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
                    .shadow(color: Brand.green.opacity(0.35), radius: 30, y: 16)
                Text("DriveLog").font(.system(size: 38, weight: .bold, design: .rounded)).foregroundStyle(.white)
                Text("Jedź. Zapisuj. Zarabiaj świadomie.").font(.subheadline.weight(.medium)).foregroundStyle(.white.opacity(0.68))
            }
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack { DashboardView() }.tabItem { Label("Start", systemImage: "gauge.with.dots.needle.67percent") }
            NavigationStack { TripsView() }.tabItem { Label("Trasy", systemImage: "map.fill") }
            NavigationStack { AddEntryView() }.tabItem { Label("Dodaj", systemImage: "plus.circle.fill") }
            NavigationStack { StatisticsView() }.tabItem { Label("Analiza", systemImage: "chart.xyaxis.line") }
            NavigationStack { VehiclesView() }.tabItem { Label("Więcej", systemImage: "ellipsis.circle.fill") }
        }.tint(Brand.green).modifier(SaveNotice())
    }
}
