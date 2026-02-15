import SwiftUI

struct BookmarksView: View {
    @EnvironmentObject private var store: AppStore

    // Demo bookmarked items
    let bookmarkedChallenges = ["Walk 1,000 Steps Today", "7-Day Hydration Streak"]
    let bookmarkedPosts = ["Nina's mobility session invite", "Sam's 5K run at reservoir"]
    let bookmarkedGroups = ["Seaport Tower — Residents", "Back Bay Running"]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                // Header
                EPCard {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 10) {
                            Image(systemName: "bookmark.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(EPTheme.accent)
                            Text("Bookmarks")
                                .font(.system(.title3, design: .rounded).weight(.semibold))
                        }
                        Text("Your saved challenges, posts, and groups")
                            .foregroundStyle(EPTheme.softText)
                            .font(.system(.subheadline, design: .rounded))
                    }
                }

                // Challenges
                if !bookmarkedChallenges.isEmpty {
                    sectionHeader(title: "Challenges")
                    ForEach(bookmarkedChallenges, id: \.self) { challenge in
                        bookmarkCard(icon: "flag.fill", title: challenge, subtitle: "Tap to view challenge details")
                    }
                }

                // Posts
                if !bookmarkedPosts.isEmpty {
                    sectionHeader(title: "Posts")
                    ForEach(bookmarkedPosts, id: \.self) { post in
                        bookmarkCard(icon: "bubble.left.fill", title: post, subtitle: "Saved from your feed")
                    }
                }

                // Groups
                if !bookmarkedGroups.isEmpty {
                    sectionHeader(title: "Groups")
                    ForEach(bookmarkedGroups, id: \.self) { group in
                        bookmarkCard(icon: "person.2.fill", title: group, subtitle: "Quick access to group")
                    }
                }

                if bookmarkedChallenges.isEmpty && bookmarkedPosts.isEmpty && bookmarkedGroups.isEmpty {
                    EPCard {
                        VStack(spacing: 12) {
                            Image(systemName: "bookmark")
                                .font(.system(size: 48))
                                .foregroundStyle(EPTheme.softText)
                            Text("No bookmarks yet")
                                .font(.system(.headline, design: .rounded))
                            Text("Bookmark posts, challenges, and groups to find them later")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(EPTheme.softText)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Bookmarks")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sectionHeader(title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(EPTheme.softText)
            Spacer()
        }
        .padding(.top, 4)
    }

    private func bookmarkCard(icon: String, title: String, subtitle: String) -> some View {
        EPCard {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(EPTheme.accent.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundStyle(EPTheme.accent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                    Text(subtitle)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(EPTheme.softText)
                }
                Spacer()

                Button {
                    // Remove bookmark action
                } label: {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(EPTheme.accent)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
