import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ZStack {
            TabView(selection: $store.selectedTab) {
                NavigationStack {
                    HomeView()
                        .toolbar { menuToolbar }
                }
                .tabItem { Label("Challenges", systemImage: "flag") }
                .tag(AppTab.challenges)

                NavigationStack {
                    ConnectorView()
                        .toolbar { menuToolbar }
                }
                .tabItem { Label("Connector", systemImage: "questionmark.circle") }
                .tag(AppTab.connector)

                NavigationStack {
                    RewardsView()
                        .toolbar { menuToolbar }
                }
                .tabItem { Label("Rewards", systemImage: "gift") }
                .tag(AppTab.rewards)

                NavigationStack {
                    GroupsView()
                        .toolbar { menuToolbar }
                }
                .tabItem { Label("Groups", systemImage: "person.2") }
                .tag(AppTab.groups)
            }
            .tint(EPTheme.accent)

            if store.isMenuOpen {
                SideMenuOverlay()
                    .transition(.opacity)
            }
        }
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
