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
                        .navigationDestination(isPresented: $store.showConnector) {
                            ConnectorView()
                        }
                }
                .tabItem { Label("Home", systemImage: "house") }
                .tag(AppTab.home)

                NavigationStack {
                    ChallengesView()
                        .toolbar { menuToolbar }
                }
                .tabItem { Label("Challenges", systemImage: "flag") }
                .tag(AppTab.challenges)

                NavigationStack {
                    CommunityView()
                        .toolbar { menuToolbar }
                }
                .tabItem { Label("Community", systemImage: "person.2") }
                .tag(AppTab.community)

                NavigationStack {
                    ChatListView()
                        .toolbar { menuToolbar }
                }
                .tabItem { Label("Chat", systemImage: "bubble.left.and.bubble.right") }
                .tag(AppTab.chat)
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
