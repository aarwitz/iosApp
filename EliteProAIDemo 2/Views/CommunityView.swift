import SwiftUI
import MapKit

struct CommunityView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var colorScheme
    @State private var showMap: Bool = false
    @State private var selectedTab: CommunityTab = .groups
    
    enum CommunityTab: String, CaseIterable {
        case groups = "Groups"
        case neighborhoods = "Neighborhoods"
        case feed = "Feed"
    }
    
    // Subcommunities based on current filter
    var subcommunities: [SubcommunityInfo] {
        switch store.communityFilter {
        case .usa:
            return [
                SubcommunityInfo(name: "Massachusetts", icon: "🌲", memberCount: 2847),
                SubcommunityInfo(name: "New York", icon: "🗽", memberCount: 5632),
                SubcommunityInfo(name: "California", icon: "☀️", memberCount: 8421)
            ]
        case .massachusetts:
            return [
                SubcommunityInfo(name: "Boston", icon: "🏙️", memberCount: 1523),
                SubcommunityInfo(name: "Cambridge", icon: "🎓", memberCount: 892),
                SubcommunityInfo(name: "Somerville", icon: "🏘️", memberCount: 432)
            ]
        case .boston:
            return [
                SubcommunityInfo(name: "Seaport", icon: "🌊", memberCount: 486),
                SubcommunityInfo(name: "Back Bay", icon: "🏛️", memberCount: 623),
                SubcommunityInfo(name: "South End", icon: "🏘️", memberCount: 341),
                SubcommunityInfo(name: "North End", icon: "🍝", memberCount: 287),
                SubcommunityInfo(name: "Beacon Hill", icon: "⛰️", memberCount: 198)
            ]
        case .seaport:
            return [
                SubcommunityInfo(name: "Echelon Seaport", icon: "🏢", memberCount: 86),
                SubcommunityInfo(name: "Barkan Buildings", icon: "🏗️", memberCount: 142),
                SubcommunityInfo(name: "Seaport Blvd", icon: "🛣️", memberCount: 258)
            ]
        case .barkan:
            return [
                SubcommunityInfo(name: "Echelon Seaport", icon: "🏢", memberCount: 86),
                SubcommunityInfo(name: "The Hudson", icon: "🏢", memberCount: 67),
                SubcommunityInfo(name: "Watermark", icon: "🏢", memberCount: 89)
            ]
        case .echelon:
            return []
        }
    }
    
    // Filter groups based on current community
    var filteredGroups: [Group] {
        let allGroups = store.groups + store.communities.flatMap { $0.groups }
        
        switch store.communityFilter {
        case .echelon:
            return allGroups.filter { $0.locationHint.contains("Echelon") || $0.locationHint.contains("Seaport") }
        case .barkan:
            return allGroups.filter { $0.locationHint.contains("Barkan") || $0.locationHint.contains("Echelon") }
        case .seaport:
            return allGroups.filter { $0.locationHint.contains("Seaport") }
        case .boston:
            return allGroups.filter { $0.locationHint.contains("Boston") }
        case .massachusetts:
            return allGroups.filter { $0.locationHint.contains("Massachusetts") || $0.locationHint.contains("Boston") }
        case .usa:
            return allGroups
        }
    }
    
    // Filter posts based on current community
    var filteredPosts: [Post] {
        store.feed.filter { post in
            store.communityFilter.includedCommunities.isEmpty || 
            store.communityFilter.includedCommunities.contains(post.communityName)
        }.sorted { $0.timestamp > $1.timestamp }
    }
    
    struct SubcommunityInfo: Identifiable {
        let id = UUID()
        let name: String
        let icon: String
        let memberCount: Int
    }

    var body: some View {
        VStack(spacing: 0) {
            
            // MARK: – Tab Picker
            tabPicker
            
            if showMap {
                mapSection
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        
                        // Community Overview Card
                        communityOverviewCard
                        
                        switch selectedTab {
                        case .groups:
                            groupsSection
                        case .neighborhoods:
                            neighborhoodsSection
                        case .feed:
                            feedSection
                        }
                    }
                    .padding(16)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                communityFilterHeader
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
    }
    
    // MARK: – Community Filter Header
    
    private var communityFilterHeader: some View {
        Menu {
            ForEach(CommunityFilter.allCases, id: \.rawValue) { filter in
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
                Text("Community")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(Color.primary)
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
            }
        }
    }
    
    // MARK: – Tab Picker
    
    private var tabPicker: some View {
        HStack(spacing: 0) {
            ForEach(CommunityTab.allCases, id: \.rawValue) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 6) {
                        Text(tab.rawValue)
                            .font(.system(.subheadline, design: .rounded).weight(selectedTab == tab ? .bold : .regular))
                            .foregroundStyle(selectedTab == tab ? Color.primary : EPTheme.softText)
                        
                        Rectangle()
                            .fill(selectedTab == tab ? EPTheme.accent : Color.clear)
                            .frame(height: 3)
                            .clipShape(Capsule())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)
                }
                .buttonStyle(.plain)
            }
        }
        .background(EPTheme.card.opacity(0.6))
    }
    
    // MARK: – Community Overview Card
    
    private var communityOverviewCard: some View {
        EPCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(store.communityFilter.displayName)
                        .font(.system(.title2, design: .rounded).weight(.bold))
                    Spacer()
                }
                
                HStack(spacing: 20) {
                    statBadge(icon: "person.3.fill", value: "\(filteredGroups.reduce(0) { $0 + $1.members })", label: "Members")
                    statBadge(icon: "person.2.fill", value: "\(filteredGroups.count)", label: "Groups")
                    statBadge(icon: "mappin.and.ellipse", value: "\(subcommunities.count)", label: "Areas")
                }
            }
        }
    }
    
    private func statBadge(icon: String, value: String, label: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(EPTheme.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                Text(label)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(EPTheme.softText)
            }
        }
    }

    // MARK: – Groups Section
    
    private var groupsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Active Groups")
                    .font(.system(.headline, design: .rounded))
                Spacer()
                Text("\(filteredGroups.count) groups")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(EPTheme.softText)
            }
            
            if filteredGroups.isEmpty {
                EPCard {
                    VStack(spacing: 8) {
                        Image(systemName: "person.3")
                            .font(.system(size: 36))
                            .foregroundStyle(EPTheme.softText)
                        Text("No groups in this area yet")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(EPTheme.softText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            } else {
                ForEach(filteredGroups) { group in
                    NavigationLink {
                        GroupDetailView(group: group)
                    } label: {
                        groupCard(group)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: – Neighborhoods Section
    
    private var neighborhoodsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(subcommunityHeaderTitle)
                    .font(.system(.headline, design: .rounded))
                Spacer()
                Text("\(subcommunities.count) areas")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(EPTheme.softText)
            }
            
            if subcommunities.isEmpty {
                EPCard {
                    VStack(spacing: 8) {
                        Image(systemName: "map")
                            .font(.system(size: 36))
                            .foregroundStyle(EPTheme.softText)
                        Text("No subcommunities to explore")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(EPTheme.softText)
                        Text("This is the most specific level")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(EPTheme.softText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            } else {
                ForEach(subcommunities) { subcommunity in
                    Button {
                        // Navigate to this subcommunity by updating the filter
                        withAnimation {
                            if let newFilter = filterForSubcommunity(subcommunity.name) {
                                store.communityFilter = newFilter
                            }
                        }
                    } label: {
                        subcommunityCard(subcommunity)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private var subcommunityHeaderTitle: String {
        switch store.communityFilter {
        case .usa: return "States"
        case .massachusetts: return "Cities"
        case .boston: return "Neighborhoods"
        case .seaport, .barkan: return "Buildings"
        case .echelon: return "Community Spaces"
        }
    }
    
    private func filterForSubcommunity(_ name: String) -> CommunityFilter? {
        switch name.lowercased() {
        case let n where n.contains("massachusetts"): return .massachusetts
        case let n where n.contains("boston"): return .boston
        case let n where n.contains("seaport"): return .seaport
        case let n where n.contains("barkan"): return .barkan
        case let n where n.contains("echelon"): return .echelon
        default: return nil
        }
    }
    
    // MARK: – Feed Section
    
    private var feedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Community Feed")
                    .font(.system(.headline, design: .rounded))
                Spacer()
                Text("\(filteredPosts.count) posts")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(EPTheme.softText)
            }
            
            if filteredPosts.isEmpty {
                EPCard {
                    VStack(spacing: 8) {
                        Image(systemName: "text.bubble")
                            .font(.system(size: 36))
                            .foregroundStyle(EPTheme.softText)
                        Text("No posts yet in this community")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(EPTheme.softText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            } else {
                ForEach(filteredPosts) { post in
                    communityPost(post)
                }
            }
        }
    }
    
    // MARK: – Group Card
    
    private func groupCard(_ group: Group) -> some View {
        EPCard {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(EPTheme.accent.opacity(0.12))
                        .frame(width: 54, height: 54)
                    Image(systemName: group.kind == .activity ? "figure.run" : "building.2")
                        .font(.system(size: 24))
                        .foregroundStyle(EPTheme.accent)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.name)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(Color.primary)
                    HStack(spacing: 8) {
                        Label("\(group.members)", systemImage: "person.2.fill")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(EPTheme.softText)
                        Text("•")
                            .foregroundStyle(EPTheme.softText)
                        Text(group.locationHint)
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(EPTheme.softText)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(EPTheme.softText)
            }
        }
    }
    
    // MARK: – Subcommunity Card
    
    private func subcommunityCard(_ subcommunity: SubcommunityInfo) -> some View {
        EPCard {
            HStack(spacing: 12) {
                Text(subcommunity.icon)
                    .font(.system(size: 38))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(subcommunity.name)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(Color.primary)
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 10))
                        Text("\(subcommunity.memberCount) members")
                            .font(.system(.caption, design: .rounded))
                    }
                    .foregroundStyle(EPTheme.softText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(EPTheme.softText)
            }
        }
    }

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

            // Bottom legend
            VStack(spacing: 0) {
                EPCard {
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundStyle(EPTheme.accent)
                        Text("\(store.activityPins.count) activities nearby")
                            .font(.system(.subheadline, design: .rounded))
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

                // Group tag
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

                // Author
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
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                }

                // Text
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
                            .frame(height: 120)
                        Image(systemName: img)
                            .font(.system(size: 32))
                            .foregroundStyle(EPTheme.softText.opacity(0.4))
                    }
                }

                // Interaction row
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
