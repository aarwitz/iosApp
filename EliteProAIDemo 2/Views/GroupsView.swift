import SwiftUI

struct GroupsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var openCommunity: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {

                EPCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Groups")
                            .font(.system(.title3, design: .rounded).weight(.semibold))
                        Text("Region-based or activity-based communities.")
                            .foregroundStyle(EPTheme.softText)
                            .font(.system(.subheadline, design: .rounded))

                        NavigationLink {
                            CommunityFeedView()
                        } label: {
                            Text("Open Community Feed")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(EPButtonStyle())
                    }
                }

                ForEach(store.groups) { g in
                    NavigationLink {
                        GroupDetailView(group: g)
                    } label: {
                        EPCard {
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(g.name)
                                        .font(.system(.headline, design: .rounded))
                                    Text("\(g.kind.rawValue) · \(g.locationHint)")
                                        .font(.system(.subheadline, design: .rounded))
                                        .foregroundStyle(EPTheme.softText)
                                    Text("\(g.members) members")
                                        .font(.system(.footnote, design: .rounded))
                                        .foregroundStyle(EPTheme.softText)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(EPTheme.softText)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
        .navigationTitle("Groups")
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(NotificationCenter.default.publisher(for: .openCommunityFeed)) { _ in
            openCommunity = true
        }
        .background(
            NavigationLink("", destination: CommunityFeedView(), isActive: $openCommunity)
                .opacity(0)
        )
    }
}

struct GroupDetailView: View {
    @EnvironmentObject private var store: AppStore
    let group: Group
    @State private var draft: String = ""
    @State private var isPosting: Bool = false

    var posts: [Post] {
        store.feed.filter { $0.groupName == group.name }.sorted { $0.timestamp > $1.timestamp }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                EPCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(group.name)
                            .font(.system(.title3, design: .rounded).weight(.semibold))
                        Text("\(group.kind.rawValue) · \(group.locationHint)")
                            .foregroundStyle(EPTheme.softText)
                        Text("\(group.members) members")
                            .font(.system(.footnote, design: .rounded))
                            .foregroundStyle(EPTheme.softText)
                    }
                }

                EPCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("New post")
                            .font(.system(.headline, design: .rounded))
                        TextField("What’s happening?", text: $draft, axis: .vertical)
                            .lineLimit(2...6)
                            .textFieldStyle(.roundedBorder)

                        Button {
                            let t = draft.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !t.isEmpty else { return }
                            isPosting = true
                            Task {
                                await store.addPost(groupName: group.name, text: t)
                                store.earnCredits(1)
                                draft = ""
                                isPosting = false
                            }
                        } label: {
                            if isPosting {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                            } else {
                                Text("Post")
                            }
                        }
                        .buttonStyle(EPButtonStyle())
                        .disabled(isPosting)
                    }
                }

                ForEach(posts) { p in
                    EPCard {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(p.author)
                                    .font(.system(.headline, design: .rounded))
                                Spacer()
                                Text(p.timestamp, style: .relative)
                                    .font(.system(.footnote, design: .rounded))
                                    .foregroundStyle(EPTheme.softText)
                            }
                            Text(p.text)
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(Color.primary.opacity(0.92))
                        }
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Group")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CommunityFeedView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(store.feed.sorted(by: { $0.timestamp > $1.timestamp })) { p in
                    EPCard {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(p.groupName)
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(EPTheme.softText)
                            HStack {
                                Text(p.author)
                                    .font(.system(.headline, design: .rounded))
                                Spacer()
                                Text(p.timestamp, style: .relative)
                                    .font(.system(.footnote, design: .rounded))
                                    .foregroundStyle(EPTheme.softText)
                            }
                            Text(p.text)
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(Color.primary.opacity(0.92))
                        }
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Community")
        .navigationBarTitleDisplayMode(.inline)
    }
}
