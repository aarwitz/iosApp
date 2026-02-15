import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var notificationsEnabled: Bool = true
    @AppStorage("darkModeEnabled") private var darkModeEnabled: Bool = true

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                // Account
                EPCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Account")
                            .font(.system(.headline, design: .rounded))

                        settingsRow(icon: "person.circle", title: "Edit Profile", action: {})
                        Divider().overlay(EPTheme.divider)
                        settingsRow(icon: "envelope", title: "Email Preferences", action: {})
                        Divider().overlay(EPTheme.divider)
                        settingsRow(icon: "lock", title: "Privacy & Security", action: {})
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

                        settingsRow(icon: "arrow.down.circle", title: "Download Data", action: {})
                        Divider().overlay(EPTheme.divider)
                        settingsRow(icon: "trash", title: "Clear Cache", action: {})
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
                    }
                }

                // Version info
                Text("Version 1.0.0")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(EPTheme.softText)
                    .padding(.top, 8)
            }
            .padding(16)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
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
