import SwiftUI

struct HomeFeedView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showBooking: Bool = false
    @State private var bookingStaff: StaffMember? = nil

    private var firstName: String {
        store.profile.name.components(separatedBy: " ").first ?? store.profile.name
    }

    private var timeOfDayGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Good night"
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // MARK: – Greeting
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(timeOfDayGreeting), \(firstName)")
                            .font(.system(.title3, design: .serif).weight(.semibold))
                        Text(Date(), format: .dateTime.weekday(.wide).month(.abbreviated).day())
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(EPTheme.softText)
                    }
                    Spacer()
                }
                .padding(.horizontal, 4)

                // MARK: – Primary CTAs (Book Coaching & Nutrition)
                VStack(spacing: 10) {
                    quickActionCoachingButton
                    quickActionNutritionButton
                }

                // MARK: – Secondary CTAs (Group Class & Create Group)
                HStack(spacing: 12) {
                    NavigationLink { GroupClassView() } label: {
                        secondaryActionTile(
                            icon: "person.3.fill",
                            iconColor: .purple,
                            title: "Join Group Class",
                            subtitle: nextClassLabel
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink { CreateGroupView() } label: {
                        secondaryActionTile(
                            icon: "plus.circle.fill",
                            iconColor: .teal,
                            title: "Create Group",
                            subtitle: createGroupSubtitle
                        )
                    }
                    .buttonStyle(.plain)
                }

                // MARK: – Today's Actions
                todaysActionsSection

                // MARK: – Your Community
                communityPulseCard

                // MARK: – Ways to Earn
                waysToEarnSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
        .refreshable { await store.refreshFeed() }
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.inline)
        .background(EPTheme.pageBackground, ignoresSafeAreaEdges: .all)
        .toolbar {
            ToolbarItem(placement: .principal) {
                resiLifeHeader
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    ChatListView()
                } label: {
                    ZStack(alignment: .topTrailing) {
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
    }

    // MARK: – ResiLife Header
    private var resiLifeHeader: some View {
        HStack(spacing: 0) {
            Text("Resi")
                .foregroundColor(.primary)
            Text("Life")
                .foregroundColor(Color(red: 0.73, green: 0.30, blue: 0.12))
        }
        .font(.system(size: 26, weight: .thin, design: .serif))
        .padding(.vertical, 2)
        .tracking(0.5)
    }

    // MARK: – Primary CTA: Book Coaching

    private var quickActionCoachingButton: some View {
        Button {
            if let coach = store.currentCoach {
                bookingStaff = coach
                showBooking = true
            }
        } label: {
            HStack(spacing: 12) {
                // Avatar
                if let coach = store.currentCoach {
                    Image(coach.name.replacingOccurrences(of: " ", with: ""))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                        .overlay(
                            Circle().stroke(
                                LinearGradient(colors: [EPTheme.accent, EPTheme.accent.opacity(0.4)],
                                               startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 2
                            )
                        )
                } else {
                    ZStack {
                        Circle()
                            .fill(EPTheme.accent.opacity(0.12))
                            .frame(width: 48, height: 48)
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(EPTheme.accent)
                    }
                }

                // Text stack
                VStack(alignment: .leading, spacing: 4) {
                    Text("Book 1-1 Coaching Session")
                        .font(.system(.subheadline, design: .serif).weight(.semibold))
                        .foregroundStyle(Color.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    if let coach = store.currentCoach, coach.isOnShift {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(.green)
                                .frame(width: 6, height: 6)
                            Text("Available Now")
                                .font(.system(size: 11, design: .rounded).weight(.semibold))
                                .foregroundStyle(.green)
                        }
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                                .foregroundStyle(EPTheme.softText)
                            Text(store.currentCoach?.shift.displayRange ?? "See schedule")
                                .font(.system(size: 11, design: .rounded))
                                .foregroundStyle(EPTheme.softText)
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [EPTheme.accent.opacity(0.06), EPTheme.accent.opacity(0.01)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
            )
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(EPTheme.card))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(EPTheme.accent.opacity(0.15), lineWidth: 1))
            .shadow(color: EPTheme.cardShadow, radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }

    // MARK: – Primary CTA: Book Nutrition

    private let nutritionGreen = Color(red: 0.2, green: 0.65, blue: 0.45)

    private var quickActionNutritionButton: some View {
        Button {
            if let nutri = store.currentNutritionist {
                bookingStaff = nutri
                showBooking = true
            }
        } label: {
            HStack(spacing: 12) {
                // Avatar
                if let nutri = store.currentNutritionist {
                    Image(nutri.name.replacingOccurrences(of: " ", with: ""))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                        .overlay(
                            Circle().stroke(
                                LinearGradient(colors: [nutritionGreen, nutritionGreen.opacity(0.4)],
                                               startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 2
                            )
                        )
                } else {
                    ZStack {
                        Circle()
                            .fill(nutritionGreen.opacity(0.12))
                            .frame(width: 48, height: 48)
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(nutritionGreen)
                    }
                }

                // Text stack
                VStack(alignment: .leading, spacing: 4) {
                    Text("Book Nutrition Check-in")
                        .font(.system(.subheadline, design: .serif).weight(.semibold))
                        .foregroundStyle(Color.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    if let nutri = store.currentNutritionist, nutri.isOnShift {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(.green)
                                .frame(width: 6, height: 6)
                            Text("Available Now")
                                .font(.system(size: 11, design: .rounded).weight(.semibold))
                                .foregroundStyle(.green)
                        }
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                                .foregroundStyle(EPTheme.softText)
                            Text(store.currentNutritionist?.shift.displayRange ?? "See schedule")
                                .font(.system(size: 11, design: .rounded))
                                .foregroundStyle(EPTheme.softText)
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [nutritionGreen.opacity(0.06), nutritionGreen.opacity(0.01)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
            )
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(EPTheme.card))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(nutritionGreen.opacity(0.15), lineWidth: 1))
            .shadow(color: EPTheme.cardShadow, radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }

    // MARK: – Secondary Action Tile (Group Class / Create Group)

    private func secondaryActionTile(icon: String, iconColor: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(iconColor.opacity(0.10))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.caption, design: .serif).weight(.semibold))
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(EPTheme.softText)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(EPTheme.softText)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(EPTheme.card))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(EPTheme.cardStroke, lineWidth: 1))
        .shadow(color: EPTheme.cardShadow, radius: 4, x: 0, y: 2)
    }

    /// Subtitle for the "Join Group Class" tile — shows next class hint
    private var nextClassLabel: String {
        // Surface the next upcoming class from today's schedule
        let classEvents = store.todaySchedule
            .filter { Calendar.current.isDateInToday($0.time) && $0.time > Date() }
            .sorted { $0.time < $1.time }
        if let next = classEvents.first {
            let fmt = DateFormatter()
            fmt.dateFormat = "h:mm a"
            return "\(next.shortLabel) · \(fmt.string(from: next.time))"
        }
        return "See today's lineup"
    }

    /// Subtitle for the "Create Group" tile
    private var createGroupSubtitle: String {
        let count = store.communities.first?.groups.count ?? store.groups.count
        return "\(count) groups in your building"
    }

    // MARK: – Today's Actions

    private var todaysActionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Today's Actions")
                .font(.system(.headline, design: .serif))
                .padding(.horizontal, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    NavigationLink { WorkoutLogView() } label: {
                        actionTile(icon: "figure.strengthtraining.traditional", title: "Log Workout", subtitle: "Track your session", color: .red)
                    }
                    .buttonStyle(.plain)

                    NavigationLink { LogMealView() } label: {
                        actionTile(icon: "camera.fill", title: "Scan a Meal", subtitle: "Earn 3 credits", color: .orange)
                    }
                    .buttonStyle(.plain)

                    NavigationLink { HabitsTrackerView() } label: {
                        actionTile(icon: "chart.line.uptrend.xyaxis", title: "Track Habits", subtitle: "Keep your streak", color: .cyan)
                    }
                    .buttonStyle(.plain)

                    NavigationLink { GroupClassView() } label: {
                        actionTile(icon: "person.3.fill", title: "Join a Class", subtitle: "See today's lineup", color: .purple)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func actionTile(icon: String, title: String, subtitle: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(color.opacity(0.12))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.subheadline, design: .serif).weight(.semibold))
                    .foregroundStyle(Color.primary)
                Text(subtitle)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(EPTheme.softText)
            }
        }
        .frame(width: 130, alignment: .leading)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(EPTheme.card))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(EPTheme.cardStroke, lineWidth: 1))
        .shadow(color: EPTheme.cardShadow, radius: 4, x: 0, y: 2)
    }

    // MARK: – Community Pulse

    private var communityPulseCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your Community")
                .font(.system(.headline, design: .serif))
                .padding(.horizontal, 4)

            Button {
                store.selectedTab = .community
            } label: {
                EPCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(EPTheme.accent.opacity(0.12))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "building.2.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(EPTheme.accent)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(store.communities.first?.name ?? "The Seaport")
                                    .font(.system(.subheadline, design: .serif).weight(.semibold))
                                    .foregroundStyle(Color.primary)

                                let groupCount = store.communities.first?.groups.count ?? 0
                                let friendCount = store.friends.count
                                Text("\(groupCount) groups · \(friendCount) friends connected")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(EPTheme.softText)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(EPTheme.softText)
                        }

                        if let latest = store.feed.sorted(by: { $0.timestamp > $1.timestamp }).first {
                            Divider().overlay(EPTheme.divider)

                            HStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(Color.primary.opacity(0.08))
                                        .frame(width: 26, height: 26)
                                    Text(String(latest.author.prefix(1)))
                                        .font(.system(.caption2, design: .rounded).weight(.bold))
                                        .foregroundStyle(Color.primary.opacity(0.6))
                                }

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(latest.author)
                                        .font(.system(.caption, design: .rounded).weight(.semibold))
                                        .foregroundStyle(Color.primary)
                                    Text(latest.text)
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundStyle(EPTheme.softText)
                                        .lineLimit(1)
                                }

                                Spacer()

                                Text(latest.timestamp, style: .relative)
                                    .font(.system(.caption2, design: .rounded))
                                    .foregroundStyle(EPTheme.softText)
                            }
                        }
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: – Ways to Earn

    private var waysToEarnSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Ways to Earn")
                    .font(.system(.headline, design: .serif))
                Spacer()
                Button {
                    store.selectedTab = .rewards
                } label: {
                    Text("See All")
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundStyle(EPTheme.accent)
                }
            }
            .padding(.horizontal, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(store.earningOpportunities.filter { !$0.isCompleted }.prefix(4))) { opp in
                        earnTile(opp)
                    }
                }
            }
        }
    }

    private func earnTile(_ opportunity: EarningOpportunity) -> some View {
        Button {
            store.selectedTab = .rewards
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: opportunity.sponsorLogo)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(EPTheme.accent)

                    Spacer()

                    Text("+\(opportunity.creditsReward)")
                        .font(.system(.caption2, design: .rounded).weight(.bold))
                        .foregroundStyle(EPTheme.accent)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(EPTheme.accent.opacity(0.12)))
                }

                Text(opportunity.title)
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(Color.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if let sponsor = opportunity.sponsorName {
                    Text(sponsor)
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(EPTheme.softText)
                } else {
                    Text(opportunity.requirements)
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(EPTheme.softText)
                }
            }
            .frame(width: 152, alignment: .leading)
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(EPTheme.card))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(EPTheme.cardStroke, lineWidth: 1))
            .shadow(color: EPTheme.cardShadow, radius: 4, x: 0, y: 2)
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
                                        .font(.system(.subheadline, design: .serif).weight(.semibold))
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
                                    .font(.system(.title3, design: .serif).weight(.bold))
                                Text("Take a photo — AI tags it. No calorie counting needed.")
                                    .font(.system(.subheadline, design: .serif))
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
                            .font(.system(.headline, design: .serif).weight(.semibold))
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
                                .font(.system(.headline, design: .serif))
                            Text("Your coach can view and comment on your meal.")
                                .font(.system(.subheadline, design: .serif))
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
                                .font(.system(.subheadline, design: .serif).weight(.semibold))
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
                            .font(.system(.headline, design: .serif))
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
                .font(.system(.subheadline, design: .serif))
            Spacer()
        }
    }
}


#Preview {HomeFeedView()
    .environmentObject(AppStore())}
