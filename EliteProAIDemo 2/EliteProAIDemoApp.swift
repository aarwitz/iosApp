import SwiftUI

@main
struct EliteProAIDemoApp: App {
    @StateObject private var store = AppStore()
    @StateObject private var auth = AuthService.shared
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("darkModeEnabled") private var darkModeEnabled: Bool = true

    var body: some Scene {
        WindowGroup {
            Group {
                if !hasSeenOnboarding {
                    OnboardingView(showOnboarding: Binding(
                        get: { !hasSeenOnboarding },
                        set: { if !$0 { hasSeenOnboarding = true } }
                    ))
                } else {
                    switch auth.authState {
                    case .unknown:
                        // Splash / loading while checking stored session
                        launchScreen
                            .task { await auth.bootstrap() }

                    case .unauthenticated:
                        LoginView()

                    case .authenticated:
                        RootView()
                            .environmentObject(store)
                            .task { await store.loadFromAPI() }
                    }
                }
            }
            .preferredColorScheme(darkModeEnabled ? .dark : .light)
        }
    }

    private var launchScreen: some View {
        ZStack {
            Color(UIColor.systemBackground).ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "bolt.heart.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(EPTheme.accent)
                ProgressView()
                    .tint(EPTheme.accent)
            }
        }
    }
}
