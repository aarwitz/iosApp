import SwiftUI

struct HomeFeedView: View {
    @EnvironmentObject private var store: AppStore
    @State private var sortOption: FeedSort = .recent
    @State private var selectedStoryFriend: FriendProfile? = nil
    @State private var currentStoryIndex: Int = 0
    
    enum FeedSort: String, CaseIterable {
        case recent = "Recent"
        case popular = "Popular"
    }

    var sortedFeed: [Post] {
        switch sortOption {
        case .recent:
            return store.feed.sorted { $0.timestamp > $1.timestamp }
        case .popular:
            // Demo: reverse-alphabetical by author as "popularity" stand-in
            return store.feed.sorted { $0.author < $1.author }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                // MARK: – Friend Stories (Instagram-style)
                friendStoriesSection

                // MARK: – Feed Header + Sort
                HStack {
                    Text("Community Activity")
                        .font(.system(.headline, design: .rounded))
                    Spacer()
                    Menu {
                        ForEach(FeedSort.allCases, id: \.self) { opt in
                            Button {
                                sortOption = opt
                            } label: {
                                HStack {
                                    Text(opt.rawValue)
                                    if sortOption == opt {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(sortOption.rawValue)
                                .font(.system(.subheadline, design: .rounded))
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.system(size: 12))
                        }
                        .foregroundStyle(EPTheme.accent)
                    }
                }

                // MARK: – Feed Posts
                ForEach(sortedFeed) { post in
                    feedPostCard(post)
                }
            }
            .padding(16)
        }
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $selectedStoryFriend) { friend in
            StoryViewer(friend: friend, currentIndex: $currentStoryIndex, onDismiss: {
                selectedStoryFriend = nil
            })
        }
    }

    // MARK: – Friend Stories Section

    private var friendStoriesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    // Prominent + button to find new friends
                    NavigationLink {
                        FindFriendsView()
                    } label: {
                        addFriendsButton
                    }
                    .buttonStyle(.plain)
                    
                    // Friends with stories first, then without
                    let sortedFriends = store.friends.sorted { ($0.hasStory ? 0 : 1) < ($1.hasStory ? 0 : 1) }
                    ForEach(sortedFriends) { friend in
                        friendStoryBubble(friend)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }

    private var addFriendsButton: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [EPTheme.accent, EPTheme.accent.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 62, height: 62)
                
                Image(systemName: "plus")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white)
            }

            Text("Find Friends")
                .font(.system(.caption2, design: .rounded).weight(.semibold))
                .foregroundStyle(EPTheme.accent)
                .lineLimit(1)
        }
        .frame(width: 70)
    }

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
                                lineWidth: 2.5
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

    // MARK: – Feed Post Card

    private func feedPostCard(_ post: Post) -> some View {
        EPCard {
            VStack(alignment: .leading, spacing: 10) {

                // Community + Group tag (tappable)
                HStack(spacing: 6) {
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(EPTheme.accent)

                    if !post.communityName.isEmpty {
                        NavigationLink {
                            // Navigate to the community
                            CommunityView()
                        } label: {
                            Text(post.communityName)
                                .font(.system(.caption, design: .rounded).weight(.semibold))
                                .foregroundStyle(EPTheme.accent)
                        }
                        .buttonStyle(.plain)

                        Text("›")
                            .foregroundStyle(EPTheme.softText)
                    }

                    NavigationLink {
                        // Navigate to the group within community
                        if let group = store.groups.first(where: { $0.name == post.groupName }) {
                            GroupDetailView(group: group)
                        } else {
                            Text("Group not found")
                        }
                    } label: {
                        Text(post.groupName)
                            .font(.system(.caption, design: .rounded).weight(.medium))
                            .foregroundStyle(EPTheme.accent.opacity(0.8))
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }

                // Author + timestamp
                HStack {
                    ZStack {
                        Circle()
                            .fill(EPTheme.accent.opacity(0.15))
                            .frame(width: 32, height: 32)
                        Text(String(post.author.prefix(1)))
                            .font(.system(.caption, design: .rounded).weight(.bold))
                            .foregroundStyle(EPTheme.accent)
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text(post.author)
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        Text(post.timestamp, style: .relative)
                            .font(.system(.caption2, design: .rounded))
                            .foregroundStyle(EPTheme.softText)
                    }
                    Spacer()
                }

                // Post text
                Text(post.text)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(Color.primary.opacity(0.92))

                // Image placeholder
                if let img = post.imagePlaceholder {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(LinearGradient(
                                colors: [Color.white.opacity(0.04), Color.white.opacity(0.02)],
                                startPoint: .top, endPoint: .bottom
                            ))
                            .frame(height: 140)
                        Image(systemName: img)
                            .font(.system(size: 36))
                            .foregroundStyle(EPTheme.softText.opacity(0.5))
                    }
                }

                // Interaction row
                HStack(spacing: 20) {
                    interactionButton(icon: "heart", label: "Like")
                    interactionButton(icon: "bubble.right", label: "Reply")
                    interactionButton(icon: "square.and.arrow.up", label: "Share")
                    Spacer()
                }
            }
        }
    }

    private func interactionButton(icon: String, label: String) -> some View {
        Button {} label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(label)
                    .font(.system(.caption, design: .rounded))
            }
            .foregroundStyle(EPTheme.softText)
        }
        .buttonStyle(.plain)
    }
}
