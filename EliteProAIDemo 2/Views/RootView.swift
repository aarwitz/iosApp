import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: AppStore
    @AppStorage("appearanceMode") private var appearanceMode: String = "system"

    private var resolvedColorScheme: ColorScheme? {
        switch appearanceMode {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    var body: some View {
        ZStack {
            TabView(selection: $store.selectedTab) {
                NavigationStack {
                    HomeFeedView()
                        .navigationDestination(isPresented: $store.showProfile) {
                            ProfileView()
                        }
                        .navigationDestination(isPresented: $store.showRewards) {
                            RewardsView()
                        }
                        .navigationDestination(isPresented: $store.showSettings) {
                            SettingsView()
                        }
                        .navigationDestination(isPresented: $store.showBookmarks) {
                            BookmarksView()
                        }
                        .navigationDestination(isPresented: $store.showChallenges) {
                            ChallengesView()
                        }
                        .navigationDestination(isPresented: $store.showConnector) {
                            ConnectorView()
                        }
                        .navigationDestination(isPresented: $store.showNotifications) {
                            NotificationsView()
                        }
                        .navigationDestination(isPresented: $store.showSchedule) {
                            ScheduleView()
                        }
                }
                .tabItem { Label("Home", systemImage: "house") }
                .tag(AppTab.home)

                NavigationStack {
                    CoachingView()
                        .toolbar { menuToolbar }
                }
                .tabItem { Label("Coaching", systemImage: "dumbbell") }
                .tag(AppTab.coaching)

                NavigationStack {
                    NutritionView()
                        .toolbar { menuToolbar }
                }
                .tabItem { Label("Nutrition", systemImage: "leaf") }
                .tag(AppTab.nutrition)

                NavigationStack {
                    CommunityView()
                        .toolbar { menuToolbar }
                }
                .tabItem { Label("Community", systemImage: "person.2") }
                .tag(AppTab.community)

                NavigationStack {
                    RewardsView()
                        .toolbar { menuToolbar }
                }
                .tabItem { Label("Rewards", systemImage: "gift") }
                .tag(AppTab.rewards)
            }
            .tint(EPTheme.accent)

            if store.isMenuOpen {
                SideMenuOverlay()
                    .transition(.opacity)
            }
        }
        .preferredColorScheme(resolvedColorScheme)
    }

    private var menuToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                store.toggleMenu()
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 18, weight: .semibold))
            }
            .accessibilityLabel("Menu")
        }
    }
}
#Preview {RootView()
    .environmentObject(AppStore())}
