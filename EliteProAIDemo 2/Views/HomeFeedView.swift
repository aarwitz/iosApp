import SwiftUI

// MARK: – Scroll-offset preference key
private struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct HomeFeedView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var colorScheme

    // Floating-nav visibility driven by scroll direction
    @State private var showFloatingNav: Bool = false
    @State private var lastScrollOffset: CGFloat = 0
    @State private var showBookingCalendar: Bool = false
    @State private var bookingStaff: StaffMember? = nil
    @State private var reservePressed: Bool = false

    var body: some View {
        ZStack(alignment: .top) {

            // ── Background ──
            LinearGradient(
                colors: [
                    Color(red: 0.97, green: 0.95, blue: 0.93),
                    Color(red: 0.94, green: 0.92, blue: 0.90) //received feedback this looks like Claude colors...
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // ── Main scroll content ──
            ScrollView(.vertical, showsIndicators: false) {

                // Invisible anchor to measure scroll offset
                GeometryReader { geo in
                    Color.clear
                        .preference(
                            key: ScrollOffsetKey.self,
                            value: geo.frame(in: .named("homescroll")).minY
                        )
                }
                .frame(height: 0)

                VStack(spacing: 28) {
                    greetingSection
                    featuredEventSection
                    serviceTilesSection
                    communityHighlightsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 60)
            }
            .coordinateSpace(name: "homescroll")
            .onPreferenceChange(ScrollOffsetKey.self) { offset in
                handleScroll(offset)
            }

            // ── Floating nav icons (hamburger + chat) ──
            if showFloatingNav {
                floatingNavBar
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            // ── Luxury booking calendar overlay ──
            if showBookingCalendar, let staff = bookingStaff {
                LuxuryBookingOverlay(
                    staff: staff,
                    isPresented: $showBookingCalendar
                )
                .environmentObject(store)
                .zIndex(10)
            }
        }
        .navigationBarHidden(true)
        .animation(.easeInOut(duration: 0.25), value: showFloatingNav)
    }

    // MARK: – Scroll handler

    private func handleScroll(_ offset: CGFloat) {
        let delta = offset - lastScrollOffset
        // Pulling down (delta > 0) → reveal nav; scrolling up (delta < 0) → hide
        if delta > 8 {
            showFloatingNav = true
        } else if delta < -8 {
            showFloatingNav = false
        }
        lastScrollOffset = offset
    }
}

//////////////////////////////////////////////////////////////////
// MARK: - Floating Nav Bar
//////////////////////////////////////////////////////////////////

private extension HomeFeedView {

    var floatingNavBar: some View {
        HStack {
            Button {
                store.toggleMenu()
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)
                    .padding(10)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .accessibilityLabel("Menu")

            Spacer()

            NavigationLink {
                ChatListView()
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.primary)
                        .padding(10)
                        .background(.ultraThinMaterial, in: Circle())

                    let unread = store.conversations.reduce(0) { $0 + $1.unreadCount }
                    if unread > 0 {
                        Circle()
                            .fill(EPTheme.accent)
                            .frame(width: 10, height: 10)
                            .offset(x: 2, y: -2)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
    }
}

//////////////////////////////////////////////////////////////////
// MARK: - SECTION 1: Greeting
//////////////////////////////////////////////////////////////////

private extension HomeFeedView {

    var greetingSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            // "Good Morning, Ryan" — name in accent, thin elegant serif
            (
                Text("\(timeOfDayGreeting), ")
                    .foregroundColor(.primary)
                +
                Text(firstName)
                    .foregroundColor(EPTheme.accent)
            )
            .font(.system(size: 32, weight: .light, design: .serif))
            .tracking(0.3)

            Text("\(weekdayName) · \(temperaturePlaceholder) · \(store.profile.buildingName)")
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(EPTheme.softText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var timeOfDayGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<22: return "Good Evening"
        default: return "Welcome"
        }
    }

    var firstName: String {
        store.profile.name.components(separatedBy: " ").first ?? store.profile.name
    }

    var weekdayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: Date())
    }

    /// Placeholder until weather API is wired
    var temperaturePlaceholder: String { "72°" }
}

//////////////////////////////////////////////////////////////////
// MARK: - SECTION 2: Featured Event (Hero Card)
//////////////////////////////////////////////////////////////////

private extension HomeFeedView {

    var featuredEventSection: some View {
        ZStack(alignment: .bottom) {

            // Hero image
            Image("RooftopPilates")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 220)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

            // Subtle gradient scrim — only lower third
            LinearGradient(
                colors: [.black.opacity(0.50), .black.opacity(0.15), .clear],
                startPoint: .bottom,
                endPoint: .top
            )
            .frame(height: 130)
            .clipShape(
                UnevenRoundedRectangle(
                    cornerRadii: .init(bottomLeading: 24, bottomTrailing: 24),
                    style: .continuous
                )
            )

            // Bottom overlay: text left, button right
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Rooftop Pilates · 10:00 AM")
                        .font(.system(size: 16, weight: .medium, design: .serif))
                        .foregroundStyle(.white)

                    Text("24 attending")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                }

                Spacer()

                Button {
                    store.selectedTab = .community
                } label: {
                    HStack(spacing: 6) {
                        Text("Reserve Spot")
                            .font(.system(size: 13, weight: .medium, design: .serif))
                            .tracking(0.3)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .medium))
                    }
                    .foregroundStyle(.black.opacity(0.55))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(
                        ZStack {
                            // Base frosted layer
                            Capsule()
                                .fill(.thinMaterial)
                                .environment(\.colorScheme, .light)

                            // Inner luminosity — bright top, soft fade
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        stops: [
                                            .init(color: .white.opacity(0.35), location: 0),
                                            .init(color: .white.opacity(0.08), location: 0.45),
                                            .init(color: .white.opacity(0.12), location: 1.0)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )

                            // Specular highlight — small bright arc at the very top
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        stops: [
                                            .init(color: .white.opacity(0.50), location: 0),
                                            .init(color: .white.opacity(0.0), location: 0.35)
                                        ],
                                        startPoint: .top,
                                        endPoint: .center
                                    )
                                )
                                .padding(.horizontal, 8)
                                .padding(.top, 1)
                                .padding(.bottom, 4)
                                .blendMode(.screen)
                        }
                    )
                    // Outer glass rim — bright top edge fading to subtle bottom
                    .overlay(
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    stops: [
                                        .init(color: .white.opacity(0.85), location: 0),
                                        .init(color: .white.opacity(0.20), location: 0.5),
                                        .init(color: .white.opacity(0.35), location: 1.0)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 0.5
                            )
                    )
                    // Glow + depth
                    .shadow(color: .white.opacity(0.20), radius: 6, x: 0, y: -1)
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
                    // Press effect: scale + brightness shift
                    .scaleEffect(reservePressed ? 0.95 : 1.0)
                    .brightness(reservePressed ? 0.08 : 0)
                    .animation(.spring(response: 0.25, dampingFraction: 0.6), value: reservePressed)
                }
                .buttonStyle(.plain)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in reservePressed = true }
                        .onEnded { _ in reservePressed = false }
                )
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 16)
        }
    }
}

//////////////////////////////////////////////////////////////////
// MARK: - SECTION 3: Your Wellness Team (Coach + Nutritionist)
//////////////////////////////////////////////////////////////////

private extension HomeFeedView {

    var serviceTilesSection: some View {
        VStack(alignment: .leading, spacing: 14) {

            Text("Your Wellness Team")
                .font(.system(size: 20, weight: .regular, design: .serif))

            HStack(spacing: 12) {
                if let coach = store.currentCoach {
                    staffCard(staff: coach)
                }
                if let nutritionist = store.currentNutritionist {
                    staffCard(staff: nutritionist)
                }
            }
        }
    }

    func staffCard(staff: StaffMember) -> some View {
        Button {
            bookingStaff = staff
            showBookingCalendar = true
        } label: {
            VStack(alignment: .leading, spacing: 0) {

                // Avatar with online indicator ring
                HStack(spacing: 10) {
                    ZStack(alignment: .bottomTrailing) {
                        Image(staff.name.replacingOccurrences(of: " ", with: ""))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(
                                        staff.isOnShift ? Color.green.opacity(0.65) : EPTheme.cardStroke,
                                        lineWidth: 2.5
                                    )
                            )

                        if staff.isOnShift {
                            Circle()
                                .fill(.green)
                                .frame(width: 14, height: 14)
                                .overlay(Circle().stroke(EPTheme.card, lineWidth: 2.5))
                                .offset(x: 2, y: 2)
                        }
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(staff.name.components(separatedBy: " ").first ?? staff.name)
                            .font(.system(size: 16, weight: .medium, design: .serif))
                            .foregroundStyle(.primary)

                        Text(staff.specialties.first ?? staff.role.rawValue)
                            .font(.system(size: 11, weight: .regular, design: .rounded))
                            .foregroundStyle(EPTheme.softText)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 8)

                // Availability badge
                HStack(spacing: 5) {
                    if staff.isOnShift {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.green)
                        Text("Available Now")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.green)
                    } else {
                        Circle()
                            .fill(.orange)
                            .frame(width: 7, height: 7)
                        Text("Next: \(staff.shift.label)")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.orange)
                    }
                }

                Spacer(minLength: 10)

                // Book CTA
                HStack {
                    Spacer()
                    HStack(spacing: 5) {
                        Text(staff.role == .coach ? "Book Session" : "Book Check-In")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundStyle(EPTheme.accent)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(EPTheme.accent.opacity(0.12)))
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 180)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(EPTheme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(EPTheme.cardStroke, lineWidth: 1)
            )
            .shadow(color: EPTheme.cardShadow, radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }
}

//////////////////////////////////////////////////////////////////
// MARK: - SECTION 4: Community Highlights
//////////////////////////////////////////////////////////////////

private extension HomeFeedView {

    var communityHighlightsSection: some View {
        VStack(alignment: .leading, spacing: 14) {

            Text("Curated for You")
                .font(.system(size: 20, weight: .regular, design: .serif))

            // Row 1 – Rooftop Run Club
            communityCard(
                title: "Rooftop Run Club",
                subtitle: "Morning run & coffee",
                trailingImage: "run_club_photo",  // placeholder asset
                badge: "18",
                badgeIcon: "bubble.left.fill"
            ) {
                store.selectedTab = .community
            }

            // Row 2 – Meet neighbors via Connector
            connectorCard()
        }
    }

    // Generic community highlight card with trailing thumbnail
    func communityCard(
        title: String,
        subtitle: String,
        trailingImage: String,
        badge: String? = nil,
        badgeIcon: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium, design: .serif))
                        .foregroundStyle(.primary)

                    HStack(spacing: 6) {
                        Text(subtitle)
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundStyle(EPTheme.softText)

                        if let badge, let icon = badgeIcon {
                            Image(systemName: icon)
                                .font(.system(size: 10))
                                .foregroundStyle(EPTheme.softText)
                            Text(badge)
                                .font(.system(.caption2, design: .rounded).weight(.medium))
                                .foregroundStyle(EPTheme.softText)
                        }
                    }
                }

                Spacer()

                Image(trailingImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 90, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(EPTheme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(EPTheme.cardStroke, lineWidth: 1)
            )
            .shadow(color: EPTheme.cardShadow, radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }

    // Connector-specific card with avatar circles and CTA
    func connectorCard() -> some View {
        Button {
            store.showConnector = true
        } label: {
            HStack(spacing: 14) {

                VStack(alignment: .leading, spacing: 8) {
                    Text("Meet 3 new neighbors")
                        .font(.system(size: 15, weight: .medium, design: .serif))
                        .foregroundStyle(.primary)

                    Text("matching your fitness goals")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(EPTheme.softText)

                    HStack(spacing: 4) {
                        Image(systemName: "link")
                            .font(.system(size: 11, weight: .medium))
                        Text("Open Connector")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(EPTheme.accent)
                }

                Spacer()

                // Overlapping avatar circles (placeholders)
                HStack(spacing: -10) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        [Color.blue, Color.purple],
                                        [Color.teal, Color.cyan],
                                        [Color.orange, Color.pink]
                                    ][i],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle().stroke(EPTheme.card, lineWidth: 2)
                            )
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(EPTheme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(EPTheme.cardStroke, lineWidth: 1)
            )
            .shadow(color: EPTheme.cardShadow, radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }
}

//////////////////////////////////////////////////////////////////
// MARK: - Luxury Booking Calendar Overlay
//////////////////////////////////////////////////////////////////

private struct LuxuryBookingOverlay: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var colorScheme
    let staff: StaffMember
    @Binding var isPresented: Bool

    @State private var displayedMonth: Date = Date()
    @State private var selectedDate: Date? = nil
    @State private var selectedSlot: Date? = nil
    @State private var confirmed: Bool = false
    @State private var appearing: Bool = false

    private let cal = Calendar.current
    private let dayCols = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    var body: some View {
        ZStack {
            // Dimmed scrim
            Color.black.opacity(appearing ? 0.45 : 0)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            // Floating card
            calendarCard
                .scaleEffect(appearing ? 1 : 0.92)
                .opacity(appearing ? 1 : 0)
                .offset(y: appearing ? 0 : 24)
        }
        .onAppear {
            selectedDate = cal.startOfDay(for: Date())
            withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
                appearing = true
            }
        }
    }

    // MARK: Dismiss

    private func dismiss() {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
            appearing = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }

    // MARK: Card

    private var calendarCard: some View {
        VStack(spacing: 0) {

            // Close button row
            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(EPTheme.softText)
                        .padding(8)
                        .background(Circle().fill(EPTheme.card.opacity(0.8)))
                }
            }
            .padding(.top, 12)
            .padding(.trailing, 16)

            if confirmed {
                confirmationContent
            } else {
                staffHeader
                    .padding(.top, 4)

                monthNavigator
                    .padding(.top, 16)

                weekdayLabels
                    .padding(.top, 10)

                dayGrid
                    .padding(.top, 4)

                if selectedDate != nil {
                    timeSlotsRow
                        .padding(.top, 14)
                }

                bookButton
                    .padding(.top, 16)
                    .padding(.bottom, 4)
            }
        }
        .padding(.bottom, 16)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(colorScheme == .dark ? Color(white: 0.11) : .white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(EPTheme.cardStroke.opacity(0.6), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.2), radius: 40, x: 0, y: 12)
        .padding(.horizontal, 16)
    }

    // MARK: Staff Header

    private var staffHeader: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                Image(staff.name.replacingOccurrences(of: " ", with: ""))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 54, height: 54)
                    .clipShape(Circle())

                if staff.isOnShift {
                    Circle()
                        .fill(.green)
                        .frame(width: 15, height: 15)
                        .overlay(
                            Circle().stroke(
                                colorScheme == .dark ? Color(white: 0.11) : .white,
                                lineWidth: 2.5
                            )
                        )
                        .offset(x: 2, y: 2)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(staff.name)
                    .font(.system(size: 18, weight: .semibold, design: .serif))

                Text(staff.credentials.prefix(2).joined(separator: " · "))
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(EPTheme.softText)

                if staff.isOnShift {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                        Text("Available Now")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                    }
                    .foregroundStyle(.green)
                } else {
                    Text("\(staff.shift.label) · \(staff.shift.displayRange)")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.orange)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 20)
    }

    // MARK: Month Navigator

    private var monthNavigator: some View {
        HStack {
            Button {
                guard canGoBack else { return }
                withAnimation(.easeInOut(duration: 0.2)) {
                    displayedMonth = cal.date(byAdding: .month, value: -1, to: displayedMonth)!
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(canGoBack ? .primary : EPTheme.softText.opacity(0.3))
            }
            .disabled(!canGoBack)

            Spacer()

            Text(monthYearLabel)
                .font(.system(size: 16, weight: .medium, design: .serif))

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    displayedMonth = cal.date(byAdding: .month, value: 1, to: displayedMonth)!
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal, 24)
    }

    private var canGoBack: Bool {
        let now = cal.dateComponents([.year, .month], from: Date())
        let shown = cal.dateComponents([.year, .month], from: displayedMonth)
        guard let ny = now.year, let nm = now.month,
              let sy = shown.year, let sm = shown.month else { return false }
        return sy > ny || (sy == ny && sm > nm)
    }

    private var monthYearLabel: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM yyyy"
        return fmt.string(from: displayedMonth)
    }

    // MARK: Weekday Labels

    private var weekdayLabels: some View {
        LazyVGrid(columns: dayCols, spacing: 0) {
            ForEach(cal.veryShortWeekdaySymbols, id: \.self) { sym in
                Text(sym)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(EPTheme.softText)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: Day Grid

    private var dayGrid: some View {
        let days = daysInMonth
        let offset = firstWeekdayOffset

        return LazyVGrid(columns: dayCols, spacing: 5) {
            ForEach(0..<offset, id: \.self) { _ in
                Color.clear.frame(height: 34)
            }
            ForEach(days, id: \.self) { date in
                dayCell(date)
            }
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private func dayCell(_ date: Date) -> some View {
        let today = cal.startOfDay(for: Date())
        let dayNum = cal.component(.day, from: date)
        let isPast = date < today
        let isToday = cal.isDate(date, inSameDayAs: today)
        let isSelected = selectedDate.map { cal.isDate($0, inSameDayAs: date) } ?? false
        let hasSlots = !slotsFor(date).isEmpty

        Button {
            guard !isPast else { return }
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedDate = date
                selectedSlot = nil
            }
        } label: {
            VStack(spacing: 2) {
                Text("\(dayNum)")
                    .font(.system(
                        size: 14,
                        weight: isSelected ? .bold : isToday ? .semibold : .regular,
                        design: .rounded
                    ))
                    .foregroundStyle(
                        isSelected ? .white :
                        isPast ? EPTheme.softText.opacity(0.3) :
                        isToday ? EPTheme.accent :
                        .primary
                    )

                Circle()
                    .fill(
                        isSelected ? .white.opacity(0.7) :
                        (hasSlots && !isPast) ? EPTheme.accent.opacity(0.45) :
                        .clear
                    )
                    .frame(width: 4, height: 4)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 34)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [EPTheme.accent, EPTheme.accent.opacity(0.75)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
        }
        .disabled(isPast)
        .buttonStyle(.plain)
    }

    // MARK: Time Slots

    private var timeSlotsRow: some View {
        let slots = selectedDate.map { slotsFor($0) } ?? []

        return VStack(alignment: .leading, spacing: 10) {
            Text("Available Times")
                .font(.system(size: 14, weight: .medium, design: .serif))
                .padding(.horizontal, 24)

            if slots.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 6) {
                        Image(systemName: "moon.zzz.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(EPTheme.softText.opacity(0.4))
                        Text("No slots this day")
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundStyle(EPTheme.softText)
                    }
                    .padding(.vertical, 8)
                    Spacer()
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(slots, id: \.self) { slot in
                            slotPill(slot)
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
    }

    private func slotPill(_ slot: Date) -> some View {
        let isSel = selectedSlot == slot
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedSlot = slot
            }
        } label: {
            Text(slot, style: .time)
                .font(.system(size: 14, weight: isSel ? .semibold : .regular, design: .rounded))
                .foregroundStyle(isSel ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule().fill(
                        isSel
                            ? AnyShapeStyle(LinearGradient(
                                colors: [EPTheme.accent, EPTheme.accent.opacity(0.72)],
                                startPoint: .leading,
                                endPoint: .trailing))
                            : AnyShapeStyle(EPTheme.card)
                    )
                )
                .overlay(
                    Capsule().stroke(
                        isSel ? EPTheme.accent : EPTheme.cardStroke,
                        lineWidth: 1
                    )
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: Book Button

    private var bookButton: some View {
        Button {
            guard let slot = selectedSlot else { return }
            store.bookSession(staff: staff, date: slot)
            withAnimation(.spring(response: 0.4)) {
                confirmed = true
            }
        } label: {
            Text(staff.role == .coach ? "Book Session" : "Book Check-In")
                .font(.system(size: 16, weight: .semibold, design: .serif))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            selectedSlot != nil
                                ? AnyShapeStyle(LinearGradient(
                                    colors: [EPTheme.accent, EPTheme.accent.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing))
                                : AnyShapeStyle(EPTheme.softText.opacity(0.22))
                        )
                )
                .shadow(
                    color: selectedSlot != nil ? EPTheme.accent.opacity(0.3) : .clear,
                    radius: 10, x: 0, y: 4
                )
        }
        .buttonStyle(.plain)
        .disabled(selectedSlot == nil)
        .padding(.horizontal, 20)
    }

    // MARK: Confirmation

    private var confirmationContent: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 8)

            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.12))
                    .frame(width: 80, height: 80)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.green)
            }

            Text("Session Booked!")
                .font(.system(size: 22, weight: .bold, design: .serif))

            VStack(spacing: 4) {
                Text("with \(staff.name)")
                    .font(.system(size: 15, weight: .medium, design: .serif))

                if let slot = selectedSlot {
                    Text(slot, style: .date)
                        .font(.system(size: 14, design: .serif))
                        .foregroundStyle(EPTheme.softText)
                    Text(slot, style: .time)
                        .font(.system(size: 14, design: .serif))
                        .foregroundStyle(EPTheme.softText)
                }
            }

            Text("Added to your Schedule")
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(EPTheme.softText)
                .padding(.top, 2)

            Button { dismiss() } label: {
                Text("Done")
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(LinearGradient(
                                colors: [EPTheme.accent, EPTheme.accent.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing))
                    )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.top, 8)

            Spacer().frame(height: 4)
        }
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: Calendar Helpers

    private var daysInMonth: [Date] {
        guard let range = cal.range(of: .day, in: .month, for: displayedMonth),
              let first = cal.date(from: cal.dateComponents([.year, .month], from: displayedMonth))
        else { return [] }
        return range.compactMap { cal.date(byAdding: .day, value: $0 - 1, to: first) }
    }

    private var firstWeekdayOffset: Int {
        guard let first = cal.date(from: cal.dateComponents([.year, .month], from: displayedMonth))
        else { return 0 }
        return cal.component(.weekday, from: first) - 1
    }

    /// Generate hour-by-hour slots for any date based on this staff member's shift.
    private func slotsFor(_ date: Date) -> [Date] {
        let day = cal.startOfDay(for: date)
        let now = Date()
        return stride(from: staff.shift.startHour, to: staff.shift.endHour, by: 1).compactMap { hour in
            guard let slot = cal.date(bySettingHour: hour, minute: 0, second: 0, of: day) else { return nil }
            return slot > now ? slot : nil
        }
    }
}
 #Preview {HomeFeedView()
     .environmentObject(AppStore())}

