// import SwiftUI

// struct HomeFeedView: View {
//     @EnvironmentObject private var store: AppStore
//     @State private var selectedStaffIndex: Int? = 0
//     @State private var showBooking: Bool = false
//     @State private var bookingStaff: StaffMember? = nil
//     @State private var navigateToChat: Bool = false
//     @State private var chatConversation: Conversation? = nil
//     @State private var messagingStaffId: UUID? = nil   // tracks in-flight "Message" tap
//     @State private var dotsVisible: Bool = false          // shows page dots during swipe

//     /// Two cards: current coach, current nutritionist
//     private var staffCards: [StaffMember] {
//         var cards: [StaffMember] = []
//         if let coach = store.currentCoach { cards.append(coach) }
//         if let nutri = store.currentNutritionist { cards.append(nutri) }
//         return cards
//     }

//     var body: some View {
//         ScrollView {
//             VStack(spacing: 10) {

//                 // MARK: – Personalized Greeting + Status Widget
//                 HStack
//                 {
//                     Spacer(minLength: 10)
//                     heroHeader
//                 }

//                 // MARK: – Your Wellness Team
//                 VStack(alignment: .leading, spacing: 10) {
//                     Text("Your Wellness Team")

//                     staffCarousel
//                 }

//                 // MARK: – Today's Actions
//                 todaysActionsSection

//                 // MARK: – Your Community
//                 communityPulseCard

//                 // MARK: – Ways to Earn
//                 waysToEarnSection
//             }
//             .padding(.horizontal, 16)
//             .padding(.top, 4)
//             .padding(.bottom, 20)
//         }
//         .refreshable { await store.refreshFeed() }
//         .navigationTitle("Home")
//         .navigationBarTitleDisplayMode(.inline)
//         .background(EPTheme.pageBackground, ignoresSafeAreaEdges: .all)
//         .toolbar {
//             ToolbarItem(placement: .principal) {
//                 // logo image header
//                 resiLifeHeader
//             }
//             ToolbarItem(placement: .topBarTrailing) {
//                 NavigationLink {
//                     ChatListView()
//                 } label: {
//                     ZStack(alignment: .topTrailing) {
//                         Image(systemName: "bubble.left")
//                             .font(.system(size: 16, weight: .semibold))

//                         let unreadCount = store.conversations.reduce(0) { $0 + $1.unreadCount }
//                         if unreadCount > 0 {
//                             Circle()
//                                 .fill(EPTheme.accent)
//                                 .frame(width: 8, height: 8)
//                                 .offset(x: 4, y: -4)
//                         }
//                     }
//                 }
//             }
//         }
//         .sheet(isPresented: $showBooking) {
//             if let staff = bookingStaff {
//                 BookingSessionView(staff: staff)
//                     .environmentObject(store)
//             }
//         }
//         .navigationDestination(isPresented: $navigateToChat) {
//             if let convo = chatConversation {
//                 ChatDetailView(conversation: convo)
//             }
//         }
//     }

//     // MARK: – ResiLife Header (logo image replaces text)
//     private var resiLifeHeader: some View {
//         HStack(spacing: 0) {
//             Text("Resi")
//                 .foregroundColor(.primary) // Adapts to Light/Dark mode automatically
//             Text("Life")
//                 .foregroundColor(Color(red: 0.73, green: 0.30, blue: 0.12))
//         }
//         // Matching the serif style from your original image
//         .font(.system(size: 26, weight: .thin, design: .serif))
//         .padding(.vertical, 2)
//         .tracking(0.5)
//     }

//     // MARK: – Staff Carousel

//     private var staffCarousel: some View {
//         ScrollView(.horizontal, showsIndicators: false) {
//             LazyHStack(spacing: 0) {
//                 ForEach(Array(staffCards.enumerated()), id: \.element.id) { idx, staff in
//                     staffCard(staff, index: idx)
//                         .padding(.horizontal, 2)
//                         .containerRelativeFrame(.horizontal)
//                         .id(idx)
//                 }
//             }
//             .scrollTargetLayout()
//         }
//         .scrollTargetBehavior(.viewAligned)
//         .scrollPosition(id: $selectedStaffIndex)
//         .overlay(alignment: .bottom) {
//             if staffCards.count > 1 {
//                 HStack(spacing: 7) {
//                     ForEach(0..<staffCards.count, id: \.self) { i in
//                         Circle()
//                             .fill((selectedStaffIndex ?? 0) == i ? EPTheme.accent : Color.gray.opacity(0.45))
//                             .frame(width: 7, height: 7)
//                     }
//                 }
//                 .padding(.vertical, 6)
//                 .padding(.horizontal, 14)
//                 .background(Capsule().fill(.ultraThinMaterial))
//                 .opacity(dotsVisible ? 1 : 0)
//                 .animation(.easeInOut(duration: 0.25), value: dotsVisible)
//                 .padding(.bottom, 8)
//             }
//         }
//         .onChange(of: selectedStaffIndex) { _, _ in
//             dotsVisible = true
//             DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
//                 dotsVisible = false
//             }
//         }
//     }

//     private func staffCard(_ staff: StaffMember, index: Int) -> some View {
//         EPCard {
//             VStack(alignment: .leading, spacing: 10) {
//                 // Header row: avatar + name/credentials/specialties
//                 HStack(spacing: 12) {
//                     // Avatar from Assets
//                     Image(staff.name.replacingOccurrences(of: " ", with: ""))
//                         .resizable()
//                         .aspectRatio(contentMode: .fill)
//                         .frame(width: 65, height: 65)
//                         .offset(y: 15)
//                         .clipShape(Circle())
//                         .overlay(Circle().stroke(EPTheme.accent.opacity(0.4), lineWidth: 2))

//                     VStack(alignment: .leading, spacing: 4) {
//                         // Name + Role badge
//                         HStack(spacing: 6) {
//                             Text(staff.name)
//                                 .font(.system(.headline, design: .serif))
//                             Text(staff.role.rawValue)
//                                 .font(.system(.caption2, design: .rounded).weight(.semibold))
//                                 .foregroundStyle(.white)
//                                 .padding(.horizontal, 8)
//                                 .padding(.vertical, 2)
//                                 .background(Capsule().fill(EPTheme.accent))
//                         }

//                         // Credentials as subtitle
//                         Text(staff.credentials.joined(separator: " · "))
//                             .font(.system(.caption, design: .rounded))
//                             .foregroundStyle(EPTheme.softText)
//                             .lineLimit(1)

//                         // Specialty pills
//                         HStack(spacing: 4) {
//                             ForEach(staff.specialties.prefix(3), id: \.self) { spec in
//                                 Text(spec)
//                                     .font(.system(size: 10, design: .rounded).weight(.medium))
//                                     .foregroundStyle(Color.primary.opacity(0.7))
//                                     .padding(.horizontal, 8)
//                                     .padding(.vertical, 3)
//                                     .background(Capsule().fill(Color.primary.opacity(0.06)))
//                             }
//                         }
//                     }
//                     Spacer()
//                 }

//                 // Shift / Available Now line
//                 HStack(spacing: 6) {
//                     if staff.isOnShift {
//                         Image(systemName: "checkmark.circle.fill")
//                             .font(.system(size: 12))
//                             .foregroundStyle(.green)
//                             .offset(x: 6)
//                         Text("Available Now")
//                             .font(.system(.caption, design: .rounded).weight(.semibold))
//                             .foregroundStyle(.green)
//                             .offset(x: 4)
//                         Text("·")
//                             .foregroundStyle(EPTheme.softText)
//                             .offset(x: 4)
//                     }
//                     Text(staff.shift.label + " Shift · " + staff.shift.displayRange)
//                         .font(.system(.caption, design: .rounded))
//                         .foregroundStyle(EPTheme.softText)
//                         .offset(x: 4)
//                 }

//                 // Motivational quote (replaces bio)
// //                Text(staff.motivationalQuote)
// //                    .font(.system(.subheadline, design: .serif).weight(.medium))
// //                    .foregroundStyle(Color.primary.opacity(0.8))
// //                    .padding(.vertical, 4)

//                 // Action buttons — icon + label, .caption sized to fit
//                 HStack(spacing: 10) {
//                     Button {
//                         guard messagingStaffId == nil else { return }
//                         messagingStaffId = staff.id
//                         Task {
//                             let convo = await store.getOrCreateConversation(
//                                 with: FriendProfile(
//                                     name: staff.name, age: 0, buildingName: "", buildingOwner: "",
//                                     bio: "", interests: [], mutualFriends: 0, workoutsThisWeek: 0,
//                                     favoriteActivity: "", avatarInitials: String(staff.name.prefix(2)).uppercased()
//                                 )
//                             )
//                             chatConversation = convo
//                             messagingStaffId = nil
//                             navigateToChat = true
//                         }
//                     } label: {
//                         HStack(spacing: 4) {
//                             if messagingStaffId == staff.id {
//                                 ProgressView()
//                                     .scaleEffect(0.7)
//                             } else {
//                                 Image(systemName: "bubble.left.fill")
//                                     .font(.system(size: 13))
//                             }
//                             Text(staff.role == .coach ? "Message Coach" : "Message Nutritionist")
//                                 .font(.system(.caption, design: .rounded).weight(.semibold))
//                                 .lineLimit(1)
//                                 .minimumScaleFactor(0.75)
//                         }
//                         .frame(maxWidth: .infinity)
//                         .frame(height: 36)
//                         .background(Capsule().fill(EPTheme.accent.opacity(0.12)))
//                         .foregroundStyle(EPTheme.accent)
//                     }
//                     .buttonStyle(.plain)
//                     .disabled(messagingStaffId != nil)

//                     Button {
//                         bookingStaff = staff
//                         showBooking = true
//                     } label: {
//                         HStack(spacing: 4) {
//                             Image(systemName: "calendar")
//                                 .font(.system(size: 16))
//                             Text(staff.role == .coach ? "Book 1-1 Session" : "Book Nutrition Session")
//                                 .font(.system(.caption, design: .rounded).weight(.semibold))
//                                 .lineLimit(1)
//                                 .minimumScaleFactor(0.75)
//                         }
//                         .frame(maxWidth: .infinity)
//                         .frame(height: 36)
//                         .background(Capsule().fill(EPTheme.accent))
//                         .foregroundStyle(.white)
//                     }
//                     .buttonStyle(.plain)
//                 }
//             }
//         }
//     }

//     // MARK: – Hero Header (Greeting + Status Widget)

//     private var heroHeader: some View {
//         HStack(alignment: .top, spacing: 14) {
//             // Left: Greeting + date
//             VStack(alignment: .leading, spacing: 4) {
//                 Text("\(timeOfDayGreeting),")
//                     .font(.system(.title3, design: .serif).weight(.semibold))
//                 Text(firstName)
//                     .font(.system(.title2, design: .serif).weight(.bold))
//                     .foregroundStyle(EPTheme.accent)
//                 Text(Date(), format: .dateTime.weekday(.wide).month(.wide).day())
//                     .font(.system(.caption, design: .rounded))
//                     .foregroundStyle(EPTheme.softText)
//                     .padding(.top, 10)
//             }

//             Spacer()

//             // Right: Compact status widget
//             statusWidget
//         }
//     }

//     @ViewBuilder
//     private var statusWidget: some View {
//         let todayEvents = store.todaySchedule
//             .filter { Calendar.current.isDateInToday($0.time) }
//             .sorted { $0.time < $1.time }

//         VStack(alignment: .leading, spacing: 0) {
//             // Header
//             HStack(spacing: 4) {
//                 Text("TODAY")
//                     .font(.system(size: 9, design: .rounded).weight(.black))
//                     .foregroundStyle(EPTheme.accent)
//                     .tracking(0.8)
//                 Spacer()
//                 Text("\(todayEvents.count)")
//                     .font(.system(size: 10, design: .rounded).weight(.bold))
//                     .foregroundStyle(.white)
//                     .frame(width: 16, height: 16)
//                     .background(Circle().fill(EPTheme.accent))
//             }
//             .padding(.bottom, 6)

//             if todayEvents.isEmpty {
//                 VStack(spacing: 4) {
//                     Text("All clear \u{2615}")
//                         .font(.system(size: 11, design: .rounded).weight(.semibold))
//                     HStack(spacing: 3) {
//                         Image(systemName: "figure.run")
//                             .font(.system(size: 8))
//                             .foregroundStyle(EPTheme.accent)
//                         Text("Morning Runners")
//                             .font(.system(size: 9, design: .rounded).weight(.semibold))
//                             .foregroundStyle(EPTheme.accent)
//                     }
//                     Text("63 neighbors · Seaport")
//                         .font(.system(size: 8, design: .rounded))
//                         .foregroundStyle(EPTheme.softText)
//                 }
//                 .frame(maxWidth: .infinity, alignment: .center)
//                 .padding(.top, 2)
//             } else {
//                 let visibleEvents = Array(todayEvents.prefix(2))
//                 let remaining = todayEvents.count - visibleEvents.count

//                 VStack(alignment: .leading, spacing: 5) {
//                     ForEach(visibleEvents) { event in
//                         HStack(spacing: 6) {
//                             Circle()
//                                 .fill(event.type.color)
//                                 .frame(width: 5, height: 5)
//                             VStack(alignment: .leading, spacing: 0) {
//                                 Text(event.shortLabel)
//                                     .font(.system(size: 10, design: .rounded).weight(.semibold))
//                                     .lineLimit(1)
//                                 Text(event.time, format: .dateTime.hour().minute())
//                                     .font(.system(size: 9, design: .rounded))
//                                     .foregroundStyle(EPTheme.softText)
//                             }
//                         }
//                     }

//                     if remaining > 0 {
//                         Text("+\(remaining) more")
//                             .font(.system(size: 9, design: .rounded).weight(.medium))
//                             .foregroundStyle(EPTheme.softText)
//                             .frame(maxWidth: .infinity, alignment: .trailing)
//                     }
//                 }
//             }
//         }
//         .padding(10)
//         .frame(width: 128, height: 100, alignment: .top)
//         .background(
//             RoundedRectangle(cornerRadius: 14, style: .continuous)
//                 .fill(EPTheme.card)
//         )
//         .overlay(
//             RoundedRectangle(cornerRadius: 14, style: .continuous)
//                 .stroke(EPTheme.cardStroke, lineWidth: 1)
//         )
//         .shadow(color: EPTheme.cardShadow, radius: 4, x: 0, y: 2)
//     }

//     private var timeOfDayGreeting: String {
//         let hour = Calendar.current.component(.hour, from: Date())
//         switch hour {
//         case 5..<12: return "Good morning"
//         case 12..<17: return "Good afternoon"
//         case 17..<22: return "Good evening"
//         default: return "Good night"
//         }
//     }

//     private var firstName: String {
//         store.profile.name.components(separatedBy: " ").first ?? store.profile.name
//     }

//     // MARK: – Today's Actions

//     private var todaysActionsSection: some View {
//         VStack(alignment: .leading, spacing: 10) {
//             Text("Today's Actions")
//                 .font(.system(.headline, design: .serif))
//                 .padding(.horizontal, 4)

//             ScrollView(.horizontal, showsIndicators: false) {
//                 HStack(spacing: 12) {
//                     NavigationLink { WorkoutLogView() } label: {
//                         actionTile(icon: "figure.strengthtraining.traditional", title: "Log Workout", subtitle: "Track your session", color: .red)
//                     }
//                     .buttonStyle(.plain)

//                     NavigationLink { LogMealView() } label: {
//                         actionTile(icon: "camera.fill", title: "Scan a Meal", subtitle: "Earn 3 credits", color: .orange)
//                     }
//                     .buttonStyle(.plain)

//                     NavigationLink { HabitsTrackerView() } label: {
//                         actionTile(icon: "chart.line.uptrend.xyaxis", title: "Track Habits", subtitle: "Keep your streak", color: .cyan)
//                     }
//                     .buttonStyle(.plain)

//                     NavigationLink { GroupClassView() } label: {
//                         actionTile(icon: "person.3.fill", title: "Join a Class", subtitle: "See today's lineup", color: .purple)
//                     }
//                     .buttonStyle(.plain)
//                 }
//             }
//         }
//     }

//     private func actionTile(icon: String, title: String, subtitle: String, color: Color) -> some View {
//         VStack(alignment: .leading, spacing: 10) {
//             ZStack {
//                 RoundedRectangle(cornerRadius: 10, style: .continuous)
//                     .fill(color.opacity(0.12))
//                     .frame(width: 38, height: 38)
//                 Image(systemName: icon)
//                     .font(.system(size: 17, weight: .semibold))
//                     .foregroundStyle(color)
//             }

//             VStack(alignment: .leading, spacing: 2) {
//                 Text(title)
//                     .font(.system(.subheadline, design: .serif).weight(.semibold))
//                     .foregroundStyle(Color.primary)
//                 Text(subtitle)
//                     .font(.system(.caption2, design: .rounded))
//                     .foregroundStyle(EPTheme.softText)
//             }
//         }
//         .frame(width: 130, alignment: .leading)
//         .padding(14)
//         .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(EPTheme.card))
//         .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(EPTheme.cardStroke, lineWidth: 1))
//         .shadow(color: EPTheme.cardShadow, radius: 4, x: 0, y: 2)
//     }

//     // MARK: – Community Pulse

//     private var communityPulseCard: some View {
//         VStack(alignment: .leading, spacing: 10) {
//             Text("Your Community")
//                 .font(.system(.headline, design: .serif))
//                 .padding(.horizontal, 4)

//             Button {
//                 store.selectedTab = .community
//             } label: {
//                 EPCard {
//                     VStack(alignment: .leading, spacing: 12) {
//                         HStack(spacing: 10) {
//                             ZStack {
//                                 RoundedRectangle(cornerRadius: 10, style: .continuous)
//                                     .fill(EPTheme.accent.opacity(0.12))
//                                     .frame(width: 40, height: 40)
//                                 Image(systemName: "building.2.fill")
//                                     .font(.system(size: 18))
//                                     .foregroundStyle(EPTheme.accent)
//                             }

//                             VStack(alignment: .leading, spacing: 2) {
//                                 Text(store.communities.first?.name ?? "The Seaport")
//                                     .font(.system(.subheadline, design: .serif).weight(.semibold))
//                                     .foregroundStyle(Color.primary)

//                                 let groupCount = store.communities.first?.groups.count ?? 0
//                                 let friendCount = store.friends.count
//                                 Text("\(groupCount) groups · \(friendCount) friends connected")
//                                     .font(.system(.caption, design: .rounded))
//                                     .foregroundStyle(EPTheme.softText)
//                             }

//                             Spacer()

//                             Image(systemName: "chevron.right")
//                                 .font(.system(size: 13, weight: .semibold))
//                                 .foregroundStyle(EPTheme.softText)
//                         }

//                         if let latest = store.feed.sorted(by: { $0.timestamp > $1.timestamp }).first {
//                             Divider().overlay(EPTheme.divider)

//                             HStack(spacing: 8) {
//                                 ZStack {
//                                     Circle()
//                                         .fill(Color.primary.opacity(0.08))
//                                         .frame(width: 26, height: 26)
//                                     Text(String(latest.author.prefix(1)))
//                                         .font(.system(.caption2, design: .rounded).weight(.bold))
//                                         .foregroundStyle(Color.primary.opacity(0.6))
//                                 }

//                                 VStack(alignment: .leading, spacing: 1) {
//                                     Text(latest.author)
//                                         .font(.system(.caption, design: .rounded).weight(.semibold))
//                                         .foregroundStyle(Color.primary)
//                                     Text(latest.text)
//                                         .font(.system(.caption, design: .rounded))
//                                         .foregroundStyle(EPTheme.softText)
//                                         .lineLimit(1)
//                                 }

//                                 Spacer()

//                                 Text(latest.timestamp, style: .relative)
//                                     .font(.system(.caption2, design: .rounded))
//                                     .foregroundStyle(EPTheme.softText)
//                             }
//                         }
//                     }
//                 }
//             }
//             .buttonStyle(.plain)
//         }
//     }

//     // MARK: – Ways to Earn

//     private var waysToEarnSection: some View {
//         VStack(alignment: .leading, spacing: 10) {
//             HStack {
//                 Text("Ways to Earn")
//                     .font(.system(.headline, design: .serif))
//                 Spacer()
//                 Button {
//                     store.selectedTab = .rewards
//                 } label: {
//                     Text("See All")
//                         .font(.system(.caption, design: .rounded).weight(.semibold))
//                         .foregroundStyle(EPTheme.accent)
//                 }
//             }
//             .padding(.horizontal, 4)

//             ScrollView(.horizontal, showsIndicators: false) {
//                 HStack(spacing: 12) {
//                     ForEach(Array(store.earningOpportunities.filter { !$0.isCompleted }.prefix(4))) { opp in
//                         earnTile(opp)
//                     }
//                 }
//             }
//         }
//     }

//     private func earnTile(_ opportunity: EarningOpportunity) -> some View {
//         Button {
//             store.selectedTab = .rewards
//         } label: {
//             VStack(alignment: .leading, spacing: 10) {
//                 HStack {
//                     Image(systemName: opportunity.sponsorLogo)
//                         .font(.system(size: 16, weight: .semibold))
//                         .foregroundStyle(EPTheme.accent)

//                     Spacer()

//                     Text("+\(opportunity.creditsReward)")
//                         .font(.system(.caption2, design: .rounded).weight(.bold))
//                         .foregroundStyle(EPTheme.accent)
//                         .padding(.horizontal, 7)
//                         .padding(.vertical, 3)
//                         .background(Capsule().fill(EPTheme.accent.opacity(0.12)))
//                 }

//                 Text(opportunity.title)
//                     .font(.system(.caption, design: .rounded).weight(.semibold))
//                     .foregroundStyle(Color.primary)
//                     .lineLimit(2)
//                     .multilineTextAlignment(.leading)

//                 if let sponsor = opportunity.sponsorName {
//                     Text(sponsor)
//                         .font(.system(.caption2, design: .rounded))
//                         .foregroundStyle(EPTheme.softText)
//                 } else {
//                     Text(opportunity.requirements)
//                         .font(.system(.caption2, design: .rounded))
//                         .foregroundStyle(EPTheme.softText)
//                 }
//             }
//             .frame(width: 152, alignment: .leading)
//             .padding(12)
//             .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(EPTheme.card))
//             .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(EPTheme.cardStroke, lineWidth: 1))
//             .shadow(color: EPTheme.cardShadow, radius: 4, x: 0, y: 2)
//         }
//         .buttonStyle(.plain)
//     }
// }

// // MARK: – Join Group View

// struct JoinGroupView: View {
//     @EnvironmentObject private var store: AppStore
//     @State private var searchText: String = ""
//     @State private var showScanner: Bool = false

//     private var allGroups: [Group] {
//         let fromCommunities = store.communities.flatMap { $0.groups }
//         let merged = store.groups + fromCommunities
//         let unique = Dictionary(grouping: merged, by: \.name).compactMapValues(\.first).values
//         if searchText.isEmpty { return Array(unique).sorted { $0.name < $1.name } }
//         return Array(unique).filter { $0.name.localizedCaseInsensitiveContains(searchText) }.sorted { $0.name < $1.name }
//     }

//     var body: some View {
//         ScrollView {
//             VStack(spacing: 16) {
//                 // Search + Scan
//                 HStack(spacing: 10) {
//                     HStack(spacing: 8) {
//                         Image(systemName: "magnifyingglass")
//                             .foregroundStyle(EPTheme.softText)
//                         TextField("Search groups…", text: $searchText)
//                             .font(.system(.body, design: .rounded))
//                     }
//                     .padding(10)
//                     .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(EPTheme.card))
//                     .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(EPTheme.cardStroke, lineWidth: 1))

//                     Button {
//                         showScanner = true
//                     } label: {
//                         Image(systemName: "qrcode.viewfinder")
//                             .font(.system(size: 22, weight: .semibold))
//                             .foregroundStyle(EPTheme.accent)
//                             .padding(10)
//                             .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(EPTheme.card))
//                             .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(EPTheme.cardStroke, lineWidth: 1))
//                     }
//                 }

//                 ForEach(allGroups) { group in
//                     NavigationLink {
//                         GroupDetailView(group: group)
//                     } label: {
//                         EPCard {
//                             HStack(spacing: 12) {
//                                 ZStack {
//                                     RoundedRectangle(cornerRadius: 12, style: .continuous)
//                                         .fill(EPTheme.accent.opacity(0.12))
//                                         .frame(width: 48, height: 48)
//                                     Image(systemName: group.kind == .activity ? "figure.run" : "building.2")
//                                         .font(.system(size: 22))
//                                         .foregroundStyle(EPTheme.accent)
//                                 }
//                                 VStack(alignment: .leading, spacing: 4) {
//                                     Text(group.name)
//                                         .font(.system(.subheadline, design: .serif).weight(.semibold))
//                                         .foregroundStyle(Color.primary)
//                                     Text("\(group.members) members · \(group.locationHint)")
//                                         .font(.system(.caption, design: .rounded))
//                                         .foregroundStyle(EPTheme.softText)
//                                 }
//                                 Spacer()
//                                 Image(systemName: "chevron.right")
//                                     .font(.system(size: 12, weight: .semibold))
//                                     .foregroundStyle(EPTheme.softText)
//                             }
//                         }
//                     }
//                     .buttonStyle(.plain)
//                 }
//             }
//             .padding(16)
//         }
//         .navigationTitle("Join Group")
//         .navigationBarTitleDisplayMode(.inline)
//         .sheet(isPresented: $showScanner) {
//             QRScannerView(
//                 onScan: { _ in showScanner = false },
//                 onCancel: { showScanner = false }
//             )
//         }
//     }
// }

// // MARK: – Log Meal View (Photo meal tracker)

// struct LogMealView: View {
//     @EnvironmentObject private var store: AppStore
//     @State private var showCamera: Bool = false
//     @State private var mealNote: String = ""
//     @State private var submitted: Bool = false

//     var body: some View {
//         ScrollView {
//             VStack(spacing: 20) {
//                 // Scan Your Meal hero
//                 EPCard {
//                     VStack(spacing: 16) {
//                         ZStack {
//                             RoundedRectangle(cornerRadius: 16, style: .continuous)
//                                 .fill(
//                                     LinearGradient(
//                                         colors: [EPTheme.accent.opacity(0.15), EPTheme.accent.opacity(0.05)],
//                                         startPoint: .topLeading, endPoint: .bottomTrailing
//                                     )
//                                 )
//                                 .frame(height: 180)

//                             VStack(spacing: 12) {
//                                 Image(systemName: "camera.fill")
//                                     .font(.system(size: 44))
//                                     .foregroundStyle(EPTheme.accent)
//                                 Text("Scan Your Meal")
//                                     .font(.system(.title3, design: .serif).weight(.bold))
//                                 Text("Take a photo — AI tags it. No calorie counting needed.")
//                                     .font(.system(.subheadline, design: .serif))
//                                     .foregroundStyle(EPTheme.softText)
//                                     .multilineTextAlignment(.center)
//                                     .padding(.horizontal, 20)
//                             }
//                         }

//                         Button {
//                             showCamera = true
//                         } label: {
//                             HStack(spacing: 8) {
//                                 Image(systemName: "camera.fill")
//                                 Text("Take Photo")
//                             }
//                             .font(.system(.headline, design: .serif).weight(.semibold))
//                             .foregroundStyle(.white)
//                             .frame(maxWidth: .infinity)
//                             .padding(.vertical, 14)
//                             .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(EPTheme.accent))
//                         }
//                         .buttonStyle(.plain)
//                     }
//                 }

//                 if submitted {
//                     EPCard {
//                         VStack(spacing: 12) {
//                             Image(systemName: "checkmark.circle.fill")
//                                 .font(.system(size: 36))
//                                 .foregroundStyle(.green)
//                             Text("Meal Logged!")
//                                 .font(.system(.headline, design: .serif))
//                             Text("Your coach can view and comment on your meal.")
//                                 .font(.system(.subheadline, design: .serif))
//                                 .foregroundStyle(EPTheme.softText)
//                                 .multilineTextAlignment(.center)
//                         }
//                         .frame(maxWidth: .infinity)
//                         .padding(.vertical, 8)
//                     }
//                 } else {
//                     EPCard {
//                         VStack(alignment: .leading, spacing: 12) {
//                             Text("Quick Note (optional)")
//                                 .font(.system(.subheadline, design: .serif).weight(.semibold))
//                             TextField("e.g. Post-workout lunch", text: $mealNote, axis: .vertical)
//                                 .lineLimit(2...4)
//                                 .textFieldStyle(.roundedBorder)
//                             Button {
//                                 store.earnCredits(3)
//                                 submitted = true
//                             } label: {
//                                 Text("Submit Without Photo")
//                             }
//                             .buttonStyle(EPButtonStyle())
//                         }
//                     }
//                 }

//                 // How it works
//                 EPCard {
//                     VStack(alignment: .leading, spacing: 10) {
//                         Text("How It Works")
//                             .font(.system(.headline, design: .serif))
//                         stepRow(num: "1", text: "Take a photo of your meal")
//                         stepRow(num: "2", text: "AI automatically tags the food items")
//                         stepRow(num: "3", text: "Your nutritionist can review and comment")
//                     }
//                 }
//             }
//             .padding(16)
//         }
//         .navigationTitle("Log Meal")
//         .navigationBarTitleDisplayMode(.inline)
//     }

//     private func stepRow(num: String, text: String) -> some View {
//         HStack(spacing: 12) {
//             ZStack {
//                 Circle()
//                     .fill(EPTheme.accent.opacity(0.15))
//                     .frame(width: 28, height: 28)
//                 Text(num)
//                     .font(.system(.caption, design: .rounded).weight(.bold))
//                     .foregroundStyle(EPTheme.accent)
//             }
//             Text(text)
//                 .font(.system(.subheadline, design: .serif))
//             Spacer()
//         }
//     }
// }


// #Preview {HomeFeedView()
//     .environmentObject(AppStore())}
