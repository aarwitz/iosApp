import SwiftUI

struct HomeFeedView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var colorScheme
    @State private var sortOption: FeedSort = .recent
    @State private var selectedStaffIndex: Int? = 0
    @State private var showBooking: Bool = false
    @State private var bookingStaff: StaffMember? = nil
    @State private var navigateToChat: Bool = false
    @State private var chatConversation: Conversation? = nil
    @State private var messagingStaffId: UUID? = nil   // tracks in-flight "Message" tap

    enum FeedSort: String, CaseIterable {
        case recent = "Recent"
        case popular = "Popular"
    }

    var sortedFeed: [Post] {
        switch sortOption {
        case .recent:
            return store.feed.sorted { $0.timestamp > $1.timestamp }
        case .popular:
            return store.feed.sorted { $0.author < $1.author }
        }
    }

    /// Two cards: current coach, current nutritionist
    private var staffCards: [StaffMember] {
        var cards: [StaffMember] = []
        if let coach = store.currentCoach { cards.append(coach) }
        if let nutri = store.currentNutritionist { cards.append(nutri) }
        return cards
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                // MARK: – Staff Carousel (Coach + Nutritionist on shift)
                staffCarousel
                    .padding(.bottom, 12)

                // MARK: – Quick Actions
//                quickActions
//                    .padding(.bottom, 16)

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
                .padding(.bottom, 10)

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
                    LazyVStack(spacing: 10) {
                        ForEach(sortedFeed) { post in
                            feedPostCard(post)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .padding(16)
        }
        .refreshable { await store.refreshFeed() }
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.inline)
        .background(EPTheme.pageBackground, ignoresSafeAreaEdges: .all)
        .toolbar {
            ToolbarItem(placement: .principal) {
                // logo image header
                resiLifeHeader
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    ChatListView()
                } label: {
                    ZStack(alignment: .topTrailing) {
//                        Image(systemName: "bubble.left")
                        Image(systemName: "bubble.left")
                            .font(.system(size: 16, weight: .semibold))

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
                .sheet(isPresented: $showBooking) {
            if let staff = bookingStaff {
                BookingSessionView(staff: staff)
                    .environmentObject(store)
            }
        }
        .navigationDestination(isPresented: $navigateToChat) {
            if let convo = chatConversation {
                ChatDetailView(conversation: convo)
            }
        }
    }

    // MARK: – ResiLife Header (logo image replaces text)
    private var resiLifeHeader: some View {
        HStack(spacing: 0) {
            Text("Resi")
                .foregroundColor(.primary) // Adapts to Light/Dark mode automatically
            Text("Life")
                .foregroundColor(Color(red: 0.73, green: 0.30, blue: 0.12))
        }
        // Matching the serif style from your original image
        .font(.system(size: 26, weight: .thin, design: .serif))
        .padding(.vertical, 2)
        .tracking(0.5)
    }

    // MARK: – Staff Carousel

    private var staffCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 0) {
                ForEach(Array(staffCards.enumerated()), id: \.element.id) { idx, staff in
                    staffCard(staff, index: idx)
                        .padding(.horizontal, 2)
                        .containerRelativeFrame(.horizontal)
                        .id(idx)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $selectedStaffIndex)
    }

    private func staffCard(_ staff: StaffMember, index: Int) -> some View {
        EPCard {
            VStack(alignment: .leading, spacing: 12) {
                // Header row: avatar + name + shift badge
                HStack(spacing: 12) {
                    // Avatar from Assets
                    Image(staff.name.replacingOccurrences(of: " ", with: ""))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 70, height: 70)
                        .offset(y: 15)          // shift upward to crop bottom of full‑body shots
                        .clipShape(Circle())
                         .overlay(Circle().stroke(staff.role == .coach ? EPTheme.accent : .green, lineWidth: 2.5)
                         )

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(staff.name)
                                .font(.system(.headline, design: .rounded))
                            Text(staff.role.rawValue)
                                .font(.system(.caption2, design: .rounded).weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(staff.role == .coach ? EPTheme.accent : .green))
                        }

                        Text(staff.shift.label + " Shift · " + staff.shift.displayRange)
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(EPTheme.softText)

                        // Credentials
                        HStack(spacing: 4) {
                            ForEach(staff.credentials.prefix(3), id: \.self) { cred in
                                Text(cred)
                                    .font(.system(size: 9, design: .rounded).weight(.medium))
                                    .foregroundStyle(EPTheme.softText)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(EPTheme.softText.opacity(0.10)))
                            }
                        }
                    }
                    Spacer()
                }

                // Bio
                Text(staff.bio)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(EPTheme.softText)
                .lineLimit(2)

                // Action buttons (match Coaching/Nutrition views)
                HStack(spacing: 12) {
                    Button {
                        guard messagingStaffId == nil else { return }
                        messagingStaffId = staff.id
                        Task {
                            let convo = await store.getOrCreateConversation(
                                with: FriendProfile(
                                    name: staff.name, age: 0, buildingName: "", buildingOwner: "",
                                    bio: "", interests: [], mutualFriends: 0, workoutsThisWeek: 0,
                                    favoriteActivity: "", avatarInitials: String(staff.name.prefix(2)).uppercased()
                                )
                            )
                            chatConversation = convo
                            messagingStaffId = nil
                            navigateToChat = true
                        }
                    } label: {
                        HStack(spacing: 6) {
                            if messagingStaffId == staff.id {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "bubble.left.fill")
                            }
                            Text("Message")
                                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(EPTheme.accent.opacity(0.12)))
                        .foregroundStyle(EPTheme.accent)
                    }
                    .buttonStyle(.plain)
                    .disabled(messagingStaffId != nil)

                    Button {
                        bookingStaff = staff
                        showBooking = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar.badge.plus")
                            Text("Book")
                                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(EPTheme.accent))
                        .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                }

                // Dots (inside card, below content)
                HStack(spacing: 6) {
                    ForEach(0..<staffCards.count, id: \.self) { i in
                        Circle()
                            .fill((selectedStaffIndex ?? 0) == i ? EPTheme.accent : Color.gray.opacity(0.4))
                            .frame(width: 7, height: 7)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
                .padding(.bottom, 2)
                .opacity((selectedStaffIndex ?? 0) == index ? 1 : 0)
                .animation(.easeInOut(duration: 0.15), value: selectedStaffIndex)
            }
        }
    }

    // MARK: – Quick Actions

    // private var quickActions: some View {
    //     VStack(alignment: .leading, spacing: 8) {
    //         Text("Quick Actions")
    //             .font(.system(.caption, design: .rounded).weight(.semibold))
    //             .foregroundStyle(EPTheme.softText)

    //         ScrollView(.horizontal, showsIndicators: false) {
    //             HStack(spacing: 10) {
    //                 NavigationLink {
    //                     JoinGroupView()
    //                 } label: {
    //                     quickActionPill(icon: "person.3.fill", label: "Join Group")
    //                 }
    //                 .buttonStyle(.plain)

    //                 NavigationLink {
    //                     CreateGroupView()
    //                 } label: {
    //                     quickActionPill(icon: "plus.circle.fill", label: "Create Group")
    //                 }
    //                 .buttonStyle(.plain)

    //                 NavigationLink {
    //                 ChallengesView()
    //                 } label: {
    //                     quickActionPill(icon: "flag.fill", label: "Accept Challenge")
    //                 }
    //                 .buttonStyle(.plain)

    //                 NavigationLink {
    //                     LogMealView()
    //                 } label: {
    //                     quickActionPill(icon: "camera.fill", label: "Log Meal")
    //                 }
    //                 .buttonStyle(.plain)

    //                 Button {
    //                     store.selectedTab = .nutrition
    //                 } label: {
    //                     quickActionPill(icon: "bag.fill", label: "Order Meal")
    //                 }
    //                 .buttonStyle(.plain)
    //             }
    //             .padding(.horizontal, 14)
    //             .padding(.vertical, 10)
    //         }
    //         .background(
    //             RoundedRectangle(cornerRadius: 14, style: .continuous)
    //                 .fill(EPTheme.card)
    //         )
    //         .overlay(
    //             RoundedRectangle(cornerRadius: 14, style: .continuous)
    //                 .stroke(EPTheme.cardStroke, lineWidth: 1)
    //         )
    //     }
    // }

    // private func quickActionPill(icon: String, label: String) -> some View {
    //     HStack(spacing: 6) {
    //         Image(systemName: icon)
    //             .font(.system(size: 14))
    //         Text(label)
    //             .font(.system(.caption, design: .rounded).weight(.medium))
    //     }
    //     .foregroundStyle(Color.primary.opacity(0.9))
    //     .padding(.horizontal, 9)
    //     .padding(.vertical, 8)
    //     .background(Capsule().fill(EPTheme.card))
    //     .overlay(Capsule().stroke(EPTheme.cardStroke, lineWidth: 1))
    // }

    // MARK: – Feed Post Card

    private func feedPostCard(_ post: Post) -> some View {
        EPCard {
            VStack(alignment: .leading, spacing: 10) {

                HStack(spacing: 6) {
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(EPTheme.accent)

                    if !post.communityName.isEmpty {
                        NavigationLink {
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
                            .frame(height: 140)
                        Image(systemName: img)
                            .font(.system(size: 36))
                            .foregroundStyle(EPTheme.softText.opacity(0.5))
                    }
                }

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

// MARK: – Join Group View

struct JoinGroupView: View {
    @EnvironmentObject private var store: AppStore
    @State private var searchText: String = ""
    @State private var showScanner: Bool = false

    private var allGroups: [Group] {
        let fromCommunities = store.communities.flatMap { $0.groups }
        let merged = store.groups + fromCommunities
        let unique = Dictionary(grouping: merged, by: \.name).compactMapValues(\.first).values
        if searchText.isEmpty { return Array(unique).sorted { $0.name < $1.name } }
        return Array(unique).filter { $0.name.localizedCaseInsensitiveContains(searchText) }.sorted { $0.name < $1.name }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Search + Scan
                HStack(spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(EPTheme.softText)
                        TextField("Search groups…", text: $searchText)
                            .font(.system(.body, design: .rounded))
                    }
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(EPTheme.card))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(EPTheme.cardStroke, lineWidth: 1))

                    Button {
                        showScanner = true
                    } label: {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(EPTheme.accent)
                            .padding(10)
                            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(EPTheme.card))
                            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(EPTheme.cardStroke, lineWidth: 1))
                    }
                }

                ForEach(allGroups) { group in
                    NavigationLink {
                        GroupDetailView(group: group)
                    } label: {
                        EPCard {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(EPTheme.accent.opacity(0.12))
                                        .frame(width: 48, height: 48)
                                    Image(systemName: group.kind == .activity ? "figure.run" : "building.2")
                                        .font(.system(size: 22))
                                        .foregroundStyle(EPTheme.accent)
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(group.name)
                                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                        .foregroundStyle(Color.primary)
                                    Text("\(group.members) members · \(group.locationHint)")
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundStyle(EPTheme.softText)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(EPTheme.softText)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
        .navigationTitle("Join Group")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showScanner) {
            QRScannerView(
                onScan: { _ in showScanner = false },
                onCancel: { showScanner = false }
            )
        }
    }
}

// MARK: – Log Meal View (Photo meal tracker)

struct LogMealView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showCamera: Bool = false
    @State private var mealNote: String = ""
    @State private var submitted: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Scan Your Meal hero
                EPCard {
                    VStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [EPTheme.accent.opacity(0.15), EPTheme.accent.opacity(0.05)],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    )
                                )
                                .frame(height: 180)

                            VStack(spacing: 12) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 44))
                                    .foregroundStyle(EPTheme.accent)
                                Text("Scan Your Meal")
                                    .font(.system(.title3, design: .rounded).weight(.bold))
                                Text("Take a photo — AI tags it. No calorie counting needed.")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundStyle(EPTheme.softText)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                            }
                        }

                        Button {
                            showCamera = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "camera.fill")
                                Text("Take Photo")
                            }
                            .font(.system(.headline, design: .rounded).weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(EPTheme.accent))
                        }
                        .buttonStyle(.plain)
                    }
                }

                if submitted {
                    EPCard {
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(.green)
                            Text("Meal Logged!")
                                .font(.system(.headline, design: .rounded))
                            Text("Your coach can view and comment on your meal.")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(EPTheme.softText)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                } else {
                    EPCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Quick Note (optional)")
                                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            TextField("e.g. Post-workout lunch", text: $mealNote, axis: .vertical)
                                .lineLimit(2...4)
                                .textFieldStyle(.roundedBorder)
                            Button {
                                store.earnCredits(3)
                                submitted = true
                            } label: {
                                Text("Submit Without Photo")
                            }
                            .buttonStyle(EPButtonStyle())
                        }
                    }
                }

                // How it works
                EPCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("How It Works")
                            .font(.system(.headline, design: .rounded))
                        stepRow(num: "1", text: "Take a photo of your meal")
                        stepRow(num: "2", text: "AI automatically tags the food items")
                        stepRow(num: "3", text: "Your nutritionist can review and comment")
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Log Meal")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func stepRow(num: String, text: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(EPTheme.accent.opacity(0.15))
                    .frame(width: 28, height: 28)
                Text(num)
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundStyle(EPTheme.accent)
            }
            Text(text)
                .font(.system(.subheadline, design: .rounded))
            Spacer()
        }
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
                    .onChange(of: selectedCommunity) { newValue, oldValue in
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
                if let first = store.communities.first {
                    selectedCommunity = first.name
                    selectedGroup = first.groups.first?.name ?? ""
                }
            }
        }
    }
}

#Preview {HomeFeedView()
    .environmentObject(AppStore())}
