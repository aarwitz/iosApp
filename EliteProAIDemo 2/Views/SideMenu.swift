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
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            // Name / avatar header — tappable → opens Profile
            Button {
                store.closeMenu()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    store.showProfile = true
                }
            } label: {
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
                        Text(store.profile.name)
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(EPTheme.primaryText(for: colorScheme))
                        Text(store.profile.email)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(EPTheme.softText(for: colorScheme))
                            .lineLimit(1)
                    }

                    Spacer()

                    Button {
                        store.closeMenu()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(EPTheme.softText(for: colorScheme))
                            .padding(10)
                            .background(Circle().fill((colorScheme == .dark ? Color.white : Color.black).opacity(0.06)))
                    }
                    .accessibilityLabel("Close menu")
                }
            }
            .buttonStyle(.plain)
            .padding(.bottom, 8)

            Divider().overlay(EPTheme.divider)

            MenuRow(icon: "person.crop.circle", title: "Profile") {
                store.selectedTab = .home
                store.closeMenu()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    store.showProfile = true
                }
            }

            MenuRow(icon: "gift", title: "Rewards") {
                store.selectedTab = .home
                store.closeMenu()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    store.showRewards = true
                }
            }

            MenuRow(icon: "questionmark.circle", title: "Connector") {
                store.selectedTab = .home
                store.closeMenu()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    store.showConnector = true
                }
            }

            MenuRow(icon: "bookmark", title: "Bookmarks") {
                store.selectedTab = .home
                store.closeMenu()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    store.showBookmarks = true
                }
            }

            MenuRow(icon: "gearshape", title: "Settings") {
                store.selectedTab = .home
                store.closeMenu()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    store.showSettings = true
                }
            }

            Spacer()

            // Footer links
            VStack(spacing: 8) {
                HStack(spacing: 16) {
                    Button {
                        // Help action
                    } label: {
                        Text("Help")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(EPTheme.softText(for: colorScheme))
                    }
                    .buttonStyle(.plain)

                    Text("•")
                        .foregroundStyle(EPTheme.softText(for: colorScheme).opacity(0.5))
                        .font(.system(.caption))

                    Button {
                        // Privacy action
                    } label: {
                        Text("Privacy")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(EPTheme.softText(for: colorScheme))
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 4)
        }
        .padding(16)
        .frame(maxHeight: .infinity)
        .background(
            (colorScheme == .dark ? Color.black.opacity(0.92) : Color.white.opacity(0.97))
                .ignoresSafeArea()
        )
    }
}

private struct MenuRow: View {
    @Environment(\.colorScheme) var colorScheme
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .frame(width: 22)
                    .foregroundStyle(EPTheme.primaryText(for: colorScheme).opacity(0.9))
                Text(title)
                    .foregroundStyle(EPTheme.primaryText(for: colorScheme))
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
