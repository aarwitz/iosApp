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

    var body: some View {
        ZStack(alignment: .top) {

            // ── Background ──
            LinearGradient(
                colors: [
                    // Color(red: 0.97, green: 0.95, blue: 0.93),
                    // Color(red: 0.94, green: 0.92, blue: 0.90)
                    Color(red: 0.96, green: 0.96, blue: 0.95),
                    Color(red: 0.94, green: 0.95, blue: 0.94)
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
                    HStack(spacing: 4) {
                        Text("Reserve Spot")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(Capsule().fill(.white.opacity(0.92)))
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 16)
        }
    }
}

//////////////////////////////////////////////////////////////////
// MARK: - SECTION 3: Service Tiles ("Curated for You")
//////////////////////////////////////////////////////////////////

private extension HomeFeedView {

    var serviceTilesSection: some View {
        VStack(alignment: .leading, spacing: 14) {

            Text("Curated for You")
                .font(.system(size: 20, weight: .regular, design: .serif))

            HStack(spacing: 12) {

                serviceTile(
                    title: "1:1 Coaching",
                    subtitle: "Private sessions with certified trainers",
                    image: "coaching_tile",
                    icon: "figure.strengthtraining.traditional"
                ) {
                    store.selectedTab = .coaching
                }

                serviceTile(
                    title: "Nutrition Check-In",
                    subtitle: "Personalized meal & habit review",
                    image: "nutrition_tile",
                    icon: "fork.knife"
                ) {
                    store.selectedTab = .nutrition
                }
            }
        }
    }

    func serviceTile(
        title: String,
        subtitle: String,
        image: String,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {

        Button(action: action) {
            ZStack {

                // Background image — slightly blurred for frosted look
                Image(image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 160)
                    .frame(maxWidth: .infinity)
                    .blur(radius: 1.5)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                // Frosted glass overlay
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial.opacity(0.7))

                // Content label
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 5) {
                        Image(systemName: icon)
                            .font(.system(size: 13, weight: .medium))
                        Text(title)
                            .font(.system(size: 17, weight: .medium, design: .serif))
                    }
                    .foregroundStyle(.primary)

                    Text(subtitle)
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(EPTheme.softText)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .padding(14)
            }
            .frame(height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
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

            Text("Community")
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
