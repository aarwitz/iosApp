import SwiftUI
import MapKit

struct CommunityView: View {
    @EnvironmentObject private var store: AppStore
    @State private var selectedCommunityIndex: Int = 0
    @State private var showMap: Bool = false
    @State private var selectedStoryFriend: FriendProfile? = nil
    @State private var currentStoryIndex: Int = 0
    @State private var showCompose: Bool = false

    var currentCommunity: Community? {
        guard store.communities.indices.contains(selectedCommunityIndex) else { return nil }
        return store.communities[selectedCommunityIndex]
    }

    var body: some View {
        VStack(spacing: 0) {

            // MARK: – Community Tabs (Twitter/X style)
            communityTabs

            if showMap {
                mapSection
            } else {
                feedSection
            }
        }
        .navigationTitle("Community")
        .navigationBarTitleDisplayMode(.inline)
        .background(EPTheme.pageBackground, ignoresSafeAreaEdges: .all)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showCompose = true
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) { showMap.toggle() }
                } label: {
                    Image(systemName: showMap ? "list.bullet" : "map")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
        }
        .fullScreenCover(item: $selectedStoryFriend) { friend in
            StoryViewer(friend: friend, currentIndex: $currentStoryIndex, onDismiss: {
                selectedStoryFriend = nil
            })
        }
        .sheet(isPresented: $showCompose) {
            ComposePostView()
                .environmentObject(store)
        }
    }

    // MARK: – Swipeable Community Tabs

    private var communityTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(store.communities.enumerated()), id: \.element.id) { idx, community in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCommunityIndex = idx
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Text(community.name)
                                .font(.system(.subheadline, design: .serif).weight(selectedCommunityIndex == idx ? .bold : .regular))
                                .foregroundStyle(selectedCommunityIndex == idx ? Color.primary : EPTheme.softText)
                                .lineLimit(1)
                                .padding(.horizontal, 16)

                            Rectangle()
                                .fill(selectedCommunityIndex == idx ? EPTheme.accent : Color.clear)
                                .frame(height: 3)
                                .clipShape(Capsule())
                        }
                        .padding(.top, 10)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .background(EPTheme.card.opacity(0.6))
    }

    // MARK: – Friend Stories Section (moved from Home)

    private var friendStoriesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    NavigationLink {
                        FindFriendsView()
                    } label: {
                        addFriendsButton
                    }
                    .buttonStyle(.plain)

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
                                LinearGradient(colors: [.orange, .pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing),
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
                        .font(.system(.subheadline, design: .serif).weight(.bold))
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

    // MARK: – Feed for selected community

    private var feedSection: some View {
        ScrollView {
            if let community = currentCommunity {
                VStack(spacing: 14) {

                    // Friend Stories
                    friendStoriesSection
                        .padding(.top, 4)

                    // Community header
                    EPCard {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 10) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(EPTheme.accent.opacity(0.15))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: "building.2.fill")
                                        .font(.system(size: 20))
                                        .foregroundStyle(EPTheme.accent)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(community.name)
                                        .font(.system(.headline, design: .serif))
                                    Text(community.locationHint)
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundStyle(EPTheme.softText)
                                }
                                Spacer()
                            }
                        }
                    }

                    // Groups in this community
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(community.groups) { group in
                                NavigationLink {
                                    GroupDetailView(group: group)
                                } label: {
                                    groupChip(group)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Posts from this community
                    let communityPosts = store.feed
                        .filter { $0.communityName == community.name }
                        .sorted { $0.timestamp > $1.timestamp }

                    if communityPosts.isEmpty {
                        EPCard {
                            VStack(spacing: 8) {
                                Image(systemName: "text.bubble")
                                    .font(.system(size: 32))
                                    .foregroundStyle(EPTheme.softText)
                                Text("No posts yet in \(community.name)")
                                    .font(.system(.subheadline, design: .serif))
                                    .foregroundStyle(EPTheme.softText)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                        }
                    }

                    ForEach(communityPosts) { post in
                        communityPost(post)
                    }
                }
                .padding(16)
            }
        }
    }

    // MARK: – Map Section

    private var mapSection: some View {
        ZStack(alignment: .bottom) {
            Map {
                ForEach(store.activityPins) { pin in
                    Annotation(pin.title, coordinate: pin.coordinate) {
                        NavigationLink {
                            if let group = allCommunityGroups.first(where: { $0.name == pin.groupName }) {
                                GroupDetailView(group: group)
                            }
                        } label: {
                            VStack(spacing: 2) {
                                ZStack {
                                    Circle()
                                        .fill(EPTheme.accent)
                                        .frame(width: 32, height: 32)
                                    Image(systemName: "figure.run")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                                Text(pin.title)
                                    .font(.system(size: 10, design: .rounded).weight(.medium))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color.black.opacity(0.7)))
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .mapStyle(.standard(pointsOfInterest: .excludingAll))

            VStack(spacing: 0) {
                EPCard {
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundStyle(EPTheme.accent)
                        Text("\(store.activityPins.count) activities nearby")
                            .font(.system(.subheadline, design: .serif))
                        Spacer()
                        Text("Tap a pin for details")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(EPTheme.softText)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
    }

    private var allCommunityGroups: [Group] {
        store.communities.flatMap { $0.groups }
    }

    // MARK: – Group Chip

    private func groupChip(_ group: Group) -> some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(EPTheme.accent.opacity(0.1))
                    .frame(width: 60, height: 60)
                Image(systemName: group.kind == .activity ? "figure.run" : "building.2")
                    .font(.system(size: 22))
                    .foregroundStyle(EPTheme.accent.opacity(0.7))
            }
            Text(group.name)
                .font(.system(.caption2, design: .rounded).weight(.medium))
                .foregroundStyle(Color.primary.opacity(0.9))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 80)
            Text("\(group.members) members")
                .font(.system(size: 9, design: .rounded))
                .foregroundStyle(EPTheme.softText)
        }
        .padding(.vertical, 6)
    }

    // MARK: – Community Post Card

    private func communityPost(_ post: Post) -> some View {
        EPCard {
            VStack(alignment: .leading, spacing: 8) {

                HStack(spacing: 6) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(EPTheme.accent)

                    NavigationLink {
                        if let group = allCommunityGroups.first(where: { $0.name == post.groupName }) {
                            GroupDetailView(group: group)
                        }
                    } label: {
                        Text(post.groupName)
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .foregroundStyle(EPTheme.accent)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Text(post.timestamp, style: .relative)
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(EPTheme.softText)
                }

                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(EPTheme.accent.opacity(0.15))
                            .frame(width: 28, height: 28)
                        Text(String(post.author.prefix(1)))
                            .font(.system(.caption2, design: .rounded).weight(.bold))
                            .foregroundStyle(EPTheme.accent)
                    }
                    Text(post.author)
                        .font(.system(.subheadline, design: .serif).weight(.medium))
                }

                Text(post.text)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(Color.primary.opacity(0.92))

                if let img = post.imagePlaceholder {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(LinearGradient(
                                colors: [Color.white.opacity(0.04), Color.white.opacity(0.02)],
                                startPoint: .top, endPoint: .bottom
                            ))
                            .frame(height: 120)
                        Image(systemName: img)
                            .font(.system(size: 32))
                            .foregroundStyle(EPTheme.softText.opacity(0.4))
                    }
                }

                HStack(spacing: 18) {
                    Label("Like", systemImage: "heart")
                    Label("Reply", systemImage: "bubble.right")
                    Spacer()
                }
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(EPTheme.softText)
            }
        }
    }
}
