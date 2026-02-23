import SwiftUI

struct HomeFeedView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var colorScheme
    @State private var sortOption: FeedSort = .recent
    @State private var selectedStoryFriend: FriendProfile? = nil
    @State private var currentStoryIndex: Int = 0
    @State private var showCompose: Bool = false
    
    enum FeedSort: String, CaseIterable {
        case recent = "Recent"
        case popular = "Popular"
    }

    var sortedFeed: [Post] {
        var filtered = store.feed
        
        // Apply community filter
        if !store.communityFilter.includedCommunities.isEmpty {
            filtered = filtered.filter { post in
                store.communityFilter.includedCommunities.contains(post.communityName)
            }
        }
        
        // Apply sort
        switch sortOption {
        case .recent:
            return filtered.sorted { $0.timestamp > $1.timestamp }
        case .popular:
            // Demo: reverse-alphabetical by author as "popularity" stand-in
            return filtered.sorted { $0.author < $1.author }
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
                if store.isLoading && sortedFeed.isEmpty {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Loading feed…")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(EPTheme.softText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else if sortedFeed.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "text.bubble")
                            .font(.system(size: 36))
                            .foregroundStyle(EPTheme.softText.opacity(0.5))
                        Text("No posts yet")
                            .font(.system(.headline, design: .rounded))
                        Text("Tap the compose button to create the first post!")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(EPTheme.softText)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    ForEach(sortedFeed) { post in
                        feedPostCard(post)
                    }
                }
            }
            .padding(16)
        }
        .refreshable { await store.refreshFeed() }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showCompose = true
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            ToolbarItem(placement: .principal) {
                communityFilterHeader
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    ChatListView()
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 18, weight: .semibold))
                        
                        // Unread badge
                        let unreadCount = store.conversations.reduce(0) { $0 + $1.unreadCount }
                        if unreadCount > 0 {
                            Circle()
                                .fill(EPTheme.accent)
                                .frame(width: 8, height: 8)
                                .offset(x: 4, y: -4)
                        }
                    }
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
    
    // MARK: – Community Filter Header
    
    private var communityFilterHeader: some View {
        Menu {
            ForEach(CommunityFilter.allCases, id: \.self) { filter in
                Button {
                    withAnimation {
                        store.communityFilter = filter
                    }
                } label: {
                    HStack {
                        Text(filter.displayName)
                        if store.communityFilter == filter {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image("Circl")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 32)
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
            }
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

// MARK: – Compose Post Sheet

struct ComposePostView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var postText: String = ""
    @State private var selectedCommunity: String = ""
    @State private var selectedGroup: String = ""
    @State private var isPosting: Bool = false

    private var availableGroups: [Group] {
        if selectedCommunity.isEmpty {
            return store.communities.flatMap { $0.groups }
        }
        return store.communities.first(where: { $0.name == selectedCommunity })?.groups ?? []
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Community") {
                    Picker("Community", selection: $selectedCommunity) {
                        Text("All Communities").tag("")
                        ForEach(store.communities, id: \.name) { community in
                            Text(community.name).tag(community.name)
                        }
                    }
                    .onChange(of: selectedCommunity) { _ in
                        // Reset group when community changes
                        if !availableGroups.contains(where: { $0.name == selectedGroup }) {
                            selectedGroup = availableGroups.first?.name ?? ""
                        }
                    }
                }

                Section("Group") {
                    Picker("Group", selection: $selectedGroup) {
                        Text("Select a group…").tag("")
                        ForEach(availableGroups) { group in
                            Text(group.name).tag(group.name)
                        }
                    }
                }

                Section("What's on your mind?") {
                    TextField("Write your post…", text: $postText, axis: .vertical)
                        .lineLimit(3...10)
                }
            }
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        isPosting = true
                        Task {
                            await store.addPost(
                                groupName: selectedGroup,
                                text: postText.trimmingCharacters(in: .whitespacesAndNewlines),
                                communityName: selectedCommunity
                            )
                            store.earnCredits(1)
                            isPosting = false
                            dismiss()
                        }
                    } label: {
                        if isPosting {
                            ProgressView()
                        } else {
                            Text("Post")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(postText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedGroup.isEmpty || isPosting)
                }
            }
            .onAppear {
                // Default to the first community and its first group
                if let first = store.communities.first {
                    selectedCommunity = first.name
                    selectedGroup = first.groups.first?.name ?? ""
                }
            }
        }
    }
}
