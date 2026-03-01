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
    @State private var hasCompletedHowItWorks = false
    @State private var selectedTab = 0

    private var tabSelection: Binding<Int> {
        Binding(
            get: { selectedTab },
            set: { newValue in
                // Prevent switching to Logbook (1) or Insights (2) during onboarding
                if !hasCompletedHowItWorks && (newValue == 1 || newValue == 2) {
                    // Keep on Measure tab (0)
                    return
                }
                selectedTab = newValue
            }
        )
    }

    var body: some View {
        if !hasSeenOnboarding {
            OnboardingView(showOnboarding: Binding(
                get: { !hasSeenOnboarding },
                set: { val in hasSeenOnboarding = !val }
            ))
        } else {
            TabView(selection: tabSelection) {
                NavigationView {
                    CaptureView(hasCompletedHowItWorks: $hasCompletedHowItWorks)
                }
                .navigationViewStyle(.stack)
                .tabItem {
                    Label("Measure", systemImage: "heart.fill")
                }
                .tag(0)

                NavigationView {
                    if hasCompletedHowItWorks {
                        LogbookView()
                    } else {
                        OnboardingPlaceholderView()
                    }
                }
                .navigationViewStyle(.stack)
                .tabItem {
                    Label("Logbook", systemImage: "list.bullet.rectangle")
                }
                .tag(1)

                NavigationView {
                    if hasCompletedHowItWorks {
                        InsightsView()
                    } else {
                        OnboardingPlaceholderView()
                    }
                }
                .navigationViewStyle(.stack)
                .tabItem {
                    Label("Insights", systemImage: "chart.xyaxis.line")
                }
                .tag(2)
            }
            .tint(PulseColors.primary)
        }
    }
}

struct OnboardingPlaceholderView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.fill")
                .font(.system(size: 48))
                .foregroundColor(PulseColors.secondaryLabel.opacity(0.5))
            
            Text("Complete onboarding to access this feature")
                .font(PulseTypography.body)
                .foregroundColor(PulseColors.secondaryLabel)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PulseColors.background)
        .contentShape(Rectangle())
        .onTapGesture {
            // Prevent any interaction
        }
    }
}
