import SwiftUI

@main
struct EliteProAIDemoApp: App {
    @StateObject private var store = AppStore()
    @StateObject private var auth = AuthService.shared
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("appearanceMode") private var appearanceMode: String = "system"

    var body: some Scene {
        WindowGroup {
            mainView
                .preferredColorScheme(resolvedColorScheme)
                .onChange(of: auth.authState) { newState, oldState in
                    if newState == .unauthenticated {
                        store.resetForNewSession()
                        hasSeenOnboarding = false
                    }
                }
        }
    }
    
    @ViewBuilder
    private var mainView: some View {
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

    private var resolvedColorScheme: ColorScheme? {
        switch appearanceMode {
        case "light": return .light
        case "dark": return .dark
        default: return nil   // system default
        }
    }
}
