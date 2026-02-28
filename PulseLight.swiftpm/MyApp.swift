import SwiftUI

@main
struct PulseApp: App {
    @StateObject private var sessionStore = SessionStore()
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some Scene {
        WindowGroup {
            ContentRootView(hasSeenOnboarding: $hasSeenOnboarding)
                .environmentObject(sessionStore)
        }
    }
}

struct ContentRootView: View {
    @Binding var hasSeenOnboarding: Bool

    var body: some View {
        if !hasSeenOnboarding {
            OnboardingView(showOnboarding: Binding(
                get: { !hasSeenOnboarding },
                set: { val in hasSeenOnboarding = !val }
            ))
        } else {
            TabView {
                NavigationView {
                    CaptureView()
                }
                .navigationViewStyle(.stack)
                .tabItem {
                    Label("Measure", systemImage: "heart.fill")
                }

                NavigationView {
                    LogbookView()
                }
                .navigationViewStyle(.stack)
                .tabItem {
                    Label("Logbook", systemImage: "list.bullet.rectangle")
                }

                NavigationView {
                    InsightsView()
                }
                .navigationViewStyle(.stack)
                .tabItem {
                    Label("Insights", systemImage: "chart.xyaxis.line")
                }
            }
            .tint(PulseColors.primary)
        }
    }
}
