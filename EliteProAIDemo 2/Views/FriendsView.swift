import SwiftUI

struct FriendsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var selectedStoryFriend: FriendProfile? = nil
    @State private var currentStoryIndex: Int = 0


    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                // MARK: – Stories Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Stories")
                        .font(.system(.headline, design: .rounded))
                        .padding(.horizontal, 4)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            // Friends with stories first, then without
                            let sortedFriends = store.friends.sorted { ($0.hasStory ? 0 : 1) < ($1.hasStory ? 0 : 1) }
                            ForEach(sortedFriends) { friend in
                                friendStoryBubble(friend)
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
                
                // MARK: – Friends List
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("All Friends")
                            .font(.system(.headline, design: .rounded))
                        Spacer()
                        Text("\(store.friends.count)")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundStyle(EPTheme.softText)
                    }
                    .padding(.horizontal, 4)
                    
                    EPCard {
                        VStack(spacing: 0) {
                            ForEach(Array(store.friends.enumerated()), id: \.element.id) { index, friend in
                                NavigationLink {
                                    FriendProfileView(friend: friend)
                                } label: {
                                    friendRow(friend)
                                }
                                .buttonStyle(.plain)
                                if index < store.friends.count - 1 {
                                    Divider().overlay(EPTheme.divider)
                                }
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Friends")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $selectedStoryFriend) { friend in
            StoryViewer(friend: friend, currentIndex: $currentStoryIndex, onDismiss: {
                selectedStoryFriend = nil
            })
        }

    }
    
    // MARK: – Story Bubble
    
    private func friendStoryBubble(_ friend: FriendProfile) -> some View {
        Button {
            if friend.hasStory {
                currentStoryIndex = 0
                selectedStoryFriend = friend
            }
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    if friend.hasStory {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.orange, .pink, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                            .frame(width: 62, height: 62)
                    } else {
                        Circle()
                            .stroke(EPTheme.cardStroke, lineWidth: 2)
                            .frame(width: 62, height: 62)
                    }

                    Circle()
                        .fill(EPTheme.accent.opacity(0.15))
                        .frame(width: 54, height: 54)

                    Text(friend.avatarInitials)
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundStyle(EPTheme.accent)
                }

                Text(friend.name.components(separatedBy: " ").first ?? "")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)
            }
            .frame(width: 70)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: – Friend Row
    
    private func friendRow(_ friend: FriendProfile) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(EPTheme.accent.opacity(0.15))
                    .frame(width: 40, height: 40)
                Text(friend.avatarInitials)
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundStyle(EPTheme.accent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(friend.name)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(Color.primary)
                HStack(spacing: 4) {
                    Image(systemName: "building.2")
                        .font(.system(size: 10))
                    Text(friend.buildingName)
                        .font(.system(.caption2, design: .rounded))
                }
                .foregroundStyle(EPTheme.softText)
            }

            Spacer()

            if friend.hasStory {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.orange, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 8, height: 8)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(EPTheme.softText)
        }
        .padding(.vertical, 8)
    }
}
