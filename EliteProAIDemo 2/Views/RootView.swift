import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: AppStore
    @AppStorage("darkModeEnabled") private var darkModeEnabled: Bool = true

    var body: some View {
        ZStack {
            TabView(selection: $store.selectedTab) {
                NavigationStack {
                    HomeFeedView()
                        .toolbar { menuToolbar }
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
                    ConnectorView()
                        .toolbar { menuToolbar }
                }
                .tabItem { Label("Connect", systemImage: "person.2.wave.2") }
                .tag(AppTab.connector)

                NavigationStack {
                    CommunityView()
                        .toolbar { menuToolbar }
                }
                .tabItem { Label("Community", systemImage: "hands.sparkles") }
                .tag(AppTab.community)

                NavigationStack {
                    ChallengesView()
                        .toolbar { menuToolbar }
                }
                .tabItem { Label("Challenges", systemImage: "flag.checkered") }
                .tag(AppTab.challenges)
            }
            .tint(EPTheme.accent)

            if store.isMenuOpen {
                SideMenuOverlay()
                    .transition(.opacity)
            }
        }
        .preferredColorScheme(darkModeEnabled ? .dark : .light)
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
