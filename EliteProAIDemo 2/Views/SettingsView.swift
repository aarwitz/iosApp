import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var notificationsEnabled: Bool = true
    @AppStorage("darkModeEnabled") private var darkModeEnabled: Bool = true
    @State private var showEditProfile = false
    @State private var showDeleteConfirmation = false
    @State private var showLogoutConfirmation = false
    @State private var showClearCacheConfirmation = false
    @State private var cacheCleared = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                // Account
                EPCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Account")
                            .font(.system(.headline, design: .rounded))

                        Button {
                            showEditProfile = true
                        } label: {
                            settingsRowContent(icon: "person.circle", title: "Edit Profile")
                        }
                        .buttonStyle(.plain)

                        Divider().overlay(EPTheme.divider)

                        NavigationLink {
                            ChangePasswordView()
                        } label: {
                            settingsRowContent(icon: "lock", title: "Change Password")
                        }
                        .buttonStyle(.plain)

                        Divider().overlay(EPTheme.divider)

                        settingsRow(icon: "envelope", title: "Email Preferences", action: {})
                        Divider().overlay(EPTheme.divider)
                        settingsRow(icon: "hand.raised", title: "Privacy & Security", action: {})
                    }
                }

                // App Preferences
                EPCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Preferences")
                            .font(.system(.headline, design: .rounded))

                        Toggle(isOn: $notificationsEnabled) {
                            HStack(spacing: 10) {
                                Image(systemName: "bell")
                                    .foregroundStyle(EPTheme.accent)
                                    .frame(width: 24)
                                Text("Push Notifications")
                                    .font(.system(.body, design: .rounded))
                            }
                        }
                        .tint(EPTheme.accent)

                        Divider().overlay(EPTheme.divider)

                        Toggle(isOn: $darkModeEnabled) {
                            HStack(spacing: 10) {
                                Image(systemName: "moon.fill")
                                    .foregroundStyle(EPTheme.accent)
                                    .frame(width: 24)
                                Text("Dark Mode")
                                    .font(.system(.body, design: .rounded))
                            }
                        }
                        .tint(EPTheme.accent)

                        Divider().overlay(EPTheme.divider)

                        settingsRow(icon: "globe", title: "Language", action: {})
                    }
                }

                // Data & Storage
                EPCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Data & Storage")
                            .font(.system(.headline, design: .rounded))

                        settingsRow(icon: "arrow.down.circle", title: "Download My Data", action: {})
                        Divider().overlay(EPTheme.divider)

                        Button {
                            showClearCacheConfirmation = true
                        } label: {
                            settingsRowContent(icon: "trash", title: cacheCleared ? "Cache Cleared ✓" : "Clear Cache")
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Support
                EPCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Support")
                            .font(.system(.headline, design: .rounded))

                        settingsRow(icon: "questionmark.circle", title: "Help Center", action: {})
                        Divider().overlay(EPTheme.divider)
                        settingsRow(icon: "envelope.circle", title: "Contact Us", action: {})
                        Divider().overlay(EPTheme.divider)
                        settingsRow(icon: "doc.text", title: "Terms of Service", action: {})
                        Divider().overlay(EPTheme.divider)
                        settingsRow(icon: "hand.raised.fill", title: "Privacy Policy", action: {})
                    }
                }

                // Danger Zone
                EPCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Button {
                            showLogoutConfirmation = true
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .foregroundStyle(.red)
                                    .frame(width: 24)
                                Text("Log Out")
                                    .font(.system(.body, design: .rounded))
                                    .foregroundStyle(.red)
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)

                        Divider().overlay(EPTheme.divider)

                        Button {
                            showDeleteConfirmation = true
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "trash.fill")
                                    .foregroundStyle(.red)
                                    .frame(width: 24)
                                Text("Delete Account")
                                    .font(.system(.body, design: .rounded))
                                    .foregroundStyle(.red)
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Version info
                Text("Version 1.0.0 (Build 1)")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(EPTheme.softText)
                    .padding(.top, 8)
            }
            .padding(16)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEditProfile) {
            EditProfileView()
                .environmentObject(store)
        }
        .alert("Log Out?", isPresented: $showLogoutConfirmation) {
            Button("Log Out", role: .destructive) {
                AuthService.shared.logout()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You'll need to sign in again to access your account.")
        }
        .alert("Delete Account?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                // TODO: Call delete account API then logout
                AuthService.shared.logout()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete your account and all associated data. This action cannot be undone.")
        }
        .alert("Clear Cache?", isPresented: $showClearCacheConfirmation) {
            Button("Clear", role: .destructive) {
                // Clear persisted data
                let url = Persistence.documentsURL(filename: "elitepro_demo_store.json")
                try? FileManager.default.removeItem(at: url)
                withAnimation { cacheCleared = true }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove locally cached data. Your account data on the server will not be affected.")
        }
    }

    private func settingsRowContent(icon: String, title: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(EPTheme.accent)
                .frame(width: 24)
            Text(title)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(Color.primary.opacity(0.9))
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(EPTheme.softText)
        }
    }

    private func settingsRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundStyle(EPTheme.accent)
                    .frame(width: 24)
                Text(title)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(Color.primary.opacity(0.9))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(EPTheme.softText)
            }
        }
        .buttonStyle(.plain)
    }
}
