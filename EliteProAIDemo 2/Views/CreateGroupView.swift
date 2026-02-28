import SwiftUI

struct CreateGroupView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var kind: GroupKind = .activity
    @State private var location: String = "Boston • Seaport"
    @State private var selectedCommunityIndex: Int = 0
    @State private var searchFriends: String = ""
    @State private var invitedFriends: Set<UUID> = []
    @State private var groupDescription: String = ""
    @State private var showCreated = false

    var filteredFriends: [FriendProfile] {
        if searchFriends.isEmpty { return store.friends }
        return store.friends.filter { $0.name.localizedCaseInsensitiveContains(searchFriends) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {

                // MARK: – Hero
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [EPTheme.accent, EPTheme.accent.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 130)

                    VStack(spacing: 8) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(.white)
                        Text("Start Something New")
                            .font(.system(.title3, design: .serif).weight(.bold))
                            .foregroundStyle(.white)
                        Text("Create a group, invite friends, build community")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }

                // MARK: – Group Details
                EPCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Label("Group Details", systemImage: "pencil.and.outline")
                            .font(.system(.headline, design: .serif))

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Name")
                                .font(.system(.caption, design: .rounded).weight(.semibold))
                                .foregroundStyle(EPTheme.softText)
                            TextField("e.g. Sunrise Runners", text: $name)
                                .textFieldStyle(.roundedBorder)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Type")
                                .font(.system(.caption, design: .rounded).weight(.semibold))
                                .foregroundStyle(EPTheme.softText)
                            Picker("Type", selection: $kind) {
                                ForEach(GroupKind.allCases, id: \.self) { k in
                                    Text(k.rawValue.capitalized).tag(k)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Description")
                                .font(.system(.caption, design: .rounded).weight(.semibold))
                                .foregroundStyle(EPTheme.softText)
                            TextField("What is your group about?", text: $groupDescription, axis: .vertical)
                                .lineLimit(2...4)
                                .textFieldStyle(.roundedBorder)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Location")
                                .font(.system(.caption, design: .rounded).weight(.semibold))
                                .foregroundStyle(EPTheme.softText)
                            TextField("Location hint", text: $location)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                }

                // MARK: – Select Community
                EPCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Community", systemImage: "building.2")
                            .font(.system(.headline, design: .serif))

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(Array(store.communities.enumerated()), id: \.element.id) { idx, community in
                                    Button {
                                        selectedCommunityIndex = idx
                                    } label: {
                                        VStack(spacing: 4) {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                    .fill(selectedCommunityIndex == idx ? EPTheme.accent : EPTheme.accent.opacity(0.1))
                                                    .frame(width: 52, height: 52)
                                                Image(systemName: "building.2.fill")
                                                    .font(.system(size: 20))
                                                    .foregroundStyle(selectedCommunityIndex == idx ? .white : EPTheme.accent)
                                            }
                                            Text(community.name)
                                                .font(.system(.caption2, design: .rounded).weight(.medium))
                                                .foregroundStyle(selectedCommunityIndex == idx ? EPTheme.accent : Color.primary)
                                                .lineLimit(1)
                                        }
                                        .frame(width: 72)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }

                // MARK: – Invite Friends
                EPCard {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Label("Invite Friends", systemImage: "person.badge.plus")
                                .font(.system(.headline, design: .serif))
                            Spacer()
                            if !invitedFriends.isEmpty {
                                Text("\(invitedFriends.count) invited")
                                    .font(.system(.caption, design: .rounded).weight(.semibold))
                                    .foregroundStyle(EPTheme.accent)
                            }
                        }

                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(EPTheme.softText)
                            TextField("Search friends…", text: $searchFriends)
                                .font(.system(.subheadline, design: .serif))
                        }
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(EPTheme.card.opacity(0.5)))

                        if filteredFriends.isEmpty {
                            Text("No friends found")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(EPTheme.softText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(filteredFriends.prefix(6)) { friend in
                                Button {
                                    if invitedFriends.contains(friend.id) {
                                        invitedFriends.remove(friend.id)
                                    } else {
                                        invitedFriends.insert(friend.id)
                                    }
                                } label: {
                                    HStack(spacing: 10) {
                                        ZStack {
                                            Circle()
                                                .fill(EPTheme.accent.opacity(0.15))
                                                .frame(width: 34, height: 34)
                                            Text(friend.avatarInitials)
                                                .font(.system(.caption2, design: .rounded).weight(.bold))
                                                .foregroundStyle(EPTheme.accent)
                                        }
                                        Text(friend.name)
                                            .font(.system(.subheadline, design: .serif))
                                            .foregroundStyle(Color.primary)
                                        Spacer()
                                        Image(systemName: invitedFriends.contains(friend.id) ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(invitedFriends.contains(friend.id) ? EPTheme.accent : EPTheme.softText)
                                            .font(.system(size: 20))
                                    }
                                    .padding(.vertical, 2)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                // MARK: – Create Button
                Button {
                    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    store.groups.insert(
                        Group(name: trimmed, kind: kind, locationHint: location, members: 1 + invitedFriends.count),
                        at: 0
                    )
                    store.persist()
                    store.earnCredits(12)
                    withAnimation { showCreated = true }
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Create Group")
                            .font(.system(.headline, design: .serif).weight(.bold))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(EPButtonStyle())
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)

                if showCreated {
                    EPCard {
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 38))
                                .foregroundStyle(EPTheme.accent)
                            Text("Group Created!")
                                .font(.system(.headline, design: .serif))
                            Text("You earned 12 credits")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(EPTheme.softText)
                            Button("Done") { dismiss() }
                                .font(.system(.subheadline, design: .serif).weight(.semibold))
                                .foregroundStyle(EPTheme.accent)
                                .padding(.top, 4)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(16)
        }
        .navigationTitle("Create Group")
        .navigationBarTitleDisplayMode(.inline)
    }
}
