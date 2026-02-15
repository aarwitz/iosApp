import SwiftUI

struct HomeFeedView: View {
    @EnvironmentObject private var store: AppStore
    @State private var sortOption: FeedSort = .recent
    @State private var selectedStatsTab: Int = 1

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

                // MARK: – Weekly Stats
                statsSection

                // MARK: – Quick Actions
                quickActions

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
    }

    // MARK: – Weekly Stats Section

    private var statsSection: some View {
        TabView(selection: $selectedStatsTab) {
            // Last Week (left side, index 0)
            EPCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Last Week")
                            .font(.system(.title3, design: .rounded).weight(.semibold))
                        Spacer()
                        Text("Feb 3 – 9")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(EPTheme.softText)
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        statBox(icon: "flame.fill", value: "\(store.lastWeekStats.workoutsCompleted)", label: "Workouts", color: .orange)
                        statBox(icon: "heart.fill", value: "\(store.lastWeekStats.avgHeartRate) bpm", label: "Avg Heart Rate", color: .red)
                        statBox(icon: "moon.zzz.fill", value: String(format: "%.1fh", store.lastWeekStats.sleepHours), label: "Avg Sleep", color: .indigo)
                        statBox(icon: "person.3.fill", value: "\(store.lastWeekStats.activitiesJoined)", label: "Activities Joined", color: .teal)
                    }
                }
            }
            .tag(0)
            
            // This Week (right side, index 1 - default)
            EPCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("This Week")
                            .font(.system(.title3, design: .rounded).weight(.semibold))
                        Spacer()
                        Text("Feb 10 – 16")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(EPTheme.softText)
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        statBox(icon: "flame.fill", value: "\(store.weeklyStats.workoutsCompleted)", label: "Workouts", color: .orange)
                        statBox(icon: "heart.fill", value: "\(store.weeklyStats.avgHeartRate) bpm", label: "Avg Heart Rate", color: .red)
                        statBox(icon: "moon.zzz.fill", value: String(format: "%.1fh", store.weeklyStats.sleepHours), label: "Avg Sleep", color: .indigo)
                        statBox(icon: "person.3.fill", value: "\(store.weeklyStats.activitiesJoined)", label: "Activities Joined", color: .teal)
                    }
                }
            }
            .tag(1)

        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .frame(height: 200)
    }

    private func statBox(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(color)
                Text(value)
                    .font(.system(.headline, design: .rounded).weight(.bold))
            }
            Text(label)
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(EPTheme.softText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(color.opacity(0.08)))
    }

    // MARK: – Quick Actions

    private var quickActions: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                quickActionPill(icon: "plus.circle.fill", label: "Log Workout") {}
                quickActionPill(icon: "fork.knife", label: "Nutrition") {}
                quickActionPill(icon: "flag.fill", label: "Challenges") {
                    store.selectedTab = .challenges
                }
                quickActionPill(icon: "person.2.fill", label: "Find Friends") {}
            }
        }
    }

    private func quickActionPill(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(label)
                    .font(.system(.caption, design: .rounded).weight(.medium))
            }
            .foregroundStyle(Color.primary.opacity(0.9))
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(Capsule().fill(EPTheme.card))
            .overlay(Capsule().stroke(EPTheme.cardStroke, lineWidth: 1))
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
