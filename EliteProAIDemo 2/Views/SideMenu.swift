import SwiftUI

struct SideMenuOverlay: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ZStack(alignment: .leading) {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { store.closeMenu() }

            SideMenu()
                .frame(maxWidth: 320)
                .transition(.move(edge: .leading))
        }
    }
}

struct SideMenu: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(EPTheme.accent.opacity(0.18))
                    Image(systemName: "bolt.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(EPTheme.accent)
                }
                .frame(width: 42, height: 42)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Elite Pro AI +")
                        .font(.system(.headline, design: .rounded))
                    Text(store.profile.email)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(EPTheme.softText)
                        .lineLimit(1)
                }

                Spacer()

                Button {
                    store.closeMenu()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(EPTheme.softText)
                        .padding(10)
                        .background(Circle().fill(Color.white.opacity(0.06)))
                }
                .accessibilityLabel("Close menu")
            }
            .padding(.bottom, 8)

            Divider().overlay(EPTheme.divider)

            MenuRow(icon: "gift", title: "Rewards") {
                store.selectedTab = .rewards
                store.closeMenu()
            }

            MenuRow(icon: "flag", title: "Challenges") {
                store.selectedTab = .challenges
                store.closeMenu()
            }

            MenuRow(icon: "questionmark.circle", title: "Connector") {
                store.selectedTab = .connector
                store.closeMenu()
            }

            MenuRow(icon: "person.2", title: "Groups") {
                store.selectedTab = .groups
                store.closeMenu()
            }

            MenuRow(icon: "bubble.left.and.bubble.right", title: "Community") {
                store.selectedTab = .groups
                store.closeMenu()
                // GroupsView has a link into community feed
                NotificationCenter.default.post(name: .openCommunityFeed, object: nil)
            }

            Spacer()

            EPCard {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(EPTheme.softText)
                    Text("Demo build · mock data only")
                        .foregroundStyle(EPTheme.softText)
                        .font(.system(.footnote, design: .rounded))
                    Spacer()
                }
            }
        }
        .padding(16)
        .frame(maxHeight: .infinity)
        .background(Color.black.opacity(0.92).ignoresSafeArea())
    }
}

private struct MenuRow: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .frame(width: 22)
                    .foregroundStyle(Color.white.opacity(0.9))
                Text(title)
                    .foregroundStyle(Color.white.opacity(0.95))
                    .font(.system(.headline, design: .rounded))
                Spacer()
            }
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }
}

extension Notification.Name {
    static let openCommunityFeed = Notification.Name("openCommunityFeed")
}
