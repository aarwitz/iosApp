import SwiftUI

/// Profile view for viewing another user's profile.
/// Shows friend status indicator with options to mute or unfriend.
struct FriendProfileView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    let friend: FriendProfile

    @State private var showFriendshipMenu = false
    @State private var showUnfriendConfirmation = false
    @State private var isMuted = false
    @State private var chatDestination: Conversation? = nil
    @State private var navigateToChat = false

    private var currentFriendStatus: Bool {
        guard let uid = friend.userID else { return false }
        return store.isFriend(userId: uid)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                // MARK: – Avatar + Name + Building
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(EPTheme.accent.opacity(0.18))
                            .frame(width: 100, height: 100)
                        Text(friend.avatarInitials)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(EPTheme.accent)
                    }

                    Text(friend.name)
                        .font(.system(.title2, design: .rounded).weight(.bold))

                    if !friend.bio.isEmpty {
                        Text(friend.bio)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(EPTheme.softText)
                    }

                    // Building info
                    if !friend.buildingName.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "building.2.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(EPTheme.accent)
                            Text(friend.buildingName)
                                .font(.system(.caption, design: .rounded).weight(.semibold))
                            if !friend.buildingOwner.isEmpty {
                                Text("•")
                                    .foregroundStyle(EPTheme.softText)
                                Text(friend.buildingOwner)
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(EPTheme.softText)
                            }
                        }
                    }

                    // MARK: – Friend Status + Actions
                    HStack(spacing: 12) {
                        // Friend status indicator (like Instagram "Following" button)
                        if currentFriendStatus {
                            Button {
                                showFriendshipMenu = true
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "person.fill.checkmark")
                                        .font(.system(size: 12))
                                    Text("Friends")
                                        .font(.system(.caption, design: .rounded).weight(.semibold))
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 8, weight: .bold))
                                }
                                .foregroundStyle(EPTheme.accent)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(EPTheme.accent.opacity(0.15))
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(EPTheme.accent.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        } else {
                            HStack(spacing: 6) {
                                Image(systemName: "person.badge.plus")
                                    .font(.system(size: 12))
                                Text("Not Friends")
                                    .font(.system(.caption, design: .rounded).weight(.medium))
                            }
                            .foregroundStyle(EPTheme.softText)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(EPTheme.card)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(EPTheme.cardStroke, lineWidth: 1)
                            )
                        }

                        // Message button
                        Button {
                            Task {
                                let convo = await store.getOrCreateConversation(with: friend)
                                await MainActor.run {
                                    chatDestination = convo
                                    navigateToChat = true
                                }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "bubble.left.fill")
                                    .font(.system(size: 12))
                                Text("Message")
                                    .font(.system(.caption, design: .rounded).weight(.semibold))
                            }
                            .foregroundStyle(.black.opacity(0.85))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule().fill(EPTheme.accent)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 8)

                // MARK: – Stats Summary
                EPCard {
                    HStack(spacing: 0) {
                        statItem(value: "\(friend.workoutsThisWeek)", label: "Workouts\nThis Week")
                        
                        Divider()
                            .frame(height: 40)
                            .overlay(EPTheme.divider)
                        
                        statItem(value: "\(friend.mutualFriends)", label: "Mutual\nFriends")
                        
                        if !friend.favoriteActivity.isEmpty {
                            Divider()
                                .frame(height: 40)
                                .overlay(EPTheme.divider)
                            
                            statItem(value: friend.favoriteActivity, label: "Favorite\nActivity")
                        }
                    }
                }

                // MARK: – Interests
                if !friend.interests.isEmpty {
                    EPCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Interests")
                                .font(.system(.headline, design: .rounded))

                            FlowLayout(spacing: 8) {
                                ForEach(friend.interests, id: \.self) { interest in
                                    Text(interest)
                                        .font(.system(.caption, design: .rounded).weight(.medium))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule().fill(EPTheme.accent.opacity(0.12))
                                        )
                                        .overlay(
                                            Capsule().stroke(EPTheme.accent.opacity(0.2), lineWidth: 1)
                                        )
                                }
                            }
                        }
                    }
                }

                // MARK: – Mute Status
                if currentFriendStatus && isMuted {
                    EPCard {
                        HStack(spacing: 10) {
                            Image(systemName: "bell.slash.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(EPTheme.softText)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Muted")
                                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                Text("You won't receive notifications from this user")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(EPTheme.softText)
                            }
                            Spacer()
                            Button("Unmute") {
                                isMuted = false
                            }
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .foregroundStyle(EPTheme.accent)
                        }
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle(friend.name)
        .navigationBarTitleDisplayMode(.inline)
        .background(
            NavigationLink(
                destination: chatDestination.map { ChatDetailView(conversation: $0) },
                isActive: $navigateToChat
            ) { EmptyView() }
        )
        .confirmationDialog("", isPresented: $showFriendshipMenu, titleVisibility: .hidden) {
            Button(isMuted ? "Unmute" : "Mute") {
                isMuted.toggle()
            }
            Button("Unfriend", role: .destructive) {
                showUnfriendConfirmation = true
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Unfriend \(friend.name)?", isPresented: $showUnfriendConfirmation) {
            Button("Unfriend", role: .destructive) {
                guard let uid = friend.userID else { return }
                Task {
                    await store.removeFriend(uid)
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("They won't be notified. You can always add them back later.")
        }
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.headline, design: .rounded).weight(.bold))
            Text(label)
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(EPTheme.softText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}
