import SwiftUI

struct ConnectorView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var colorScheme
    @State private var currentIndex: Int = 0
    @State private var dragOffset: CGSize = .zero
    @State private var swipeDirection: SwipeDirection? = nil
    @State private var showBarcodeSheet = false
    @State private var showScanner = false
    @State private var selectedFriend: FriendProfile? = nil
    @State private var showMatchOverlay = false
    @State private var matchedFriend: FriendProfile? = nil
    @State private var alertMessage: String? = nil
    @State private var showAlert = false

    enum SwipeDirection {
        case left, right
    }

    // Interests the current user has (derived from profile context)
    private let myInterests: Set<String> = [
        "Running", "Strength Training", "HIIT", "Yoga",
        "Nutrition", "Swimming", "Mobility", "Recovery"
    ]

    var filteredFriends: [FriendProfile] {
        store.discoverableFriends.filter { friend in
            store.communityFilter.matchesBuilding(buildingName: friend.buildingName, buildingOwner: friend.buildingOwner)
        }
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                if currentIndex < filteredFriends.count {
                    // Card stack — fills available space
                    ZStack {
                        // Next card (behind)
                        if currentIndex + 1 < filteredFriends.count {
                            friendCard(filteredFriends[currentIndex + 1])
                                .scaleEffect(0.95)
                                .offset(y: 8)
                                .opacity(0.5)
                        }

                        // Current card (front)
                        friendCard(filteredFriends[currentIndex])
                            .offset(dragOffset)
                            .rotationEffect(.degrees(Double(dragOffset.width / 22)))
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        dragOffset = value.translation
                                        if value.translation.width > 40 {
                                            swipeDirection = .right
                                        } else if value.translation.width < -40 {
                                            swipeDirection = .left
                                        } else {
                                            swipeDirection = nil
                                        }
                                    }
                                    .onEnded { value in
                                        if abs(value.translation.width) > 120 {
                                            let direction: SwipeDirection = value.translation.width > 0 ? .right : .left
                                            completeSwipe(direction)
                                        } else {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                dragOffset = .zero
                                                swipeDirection = nil
                                            }
                                        }
                                    }
                            )

                        // Swipe indicators
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 70))
                                .foregroundStyle(.red.opacity(swipeDirection == .left ? 0.85 : 0))
                                .padding(.leading, 24)
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 70))
                                .foregroundStyle(.green.opacity(swipeDirection == .right ? 0.85 : 0))
                                .padding(.trailing, 24)
                        }
                        .allowsHitTesting(false)
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 4)

                    // Action buttons
                    HStack(spacing: 36) {
                        Button { completeSwipe(.left) } label: {
                            ZStack {
                                Circle()
                                    .fill(EPTheme.card)
                                    .frame(width: 64, height: 64)
                                    .overlay(Circle().stroke(Color.red.opacity(0.3), lineWidth: 2))
                                Image(systemName: "xmark")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundStyle(.red)
                            }
                        }

                        Button {
                            if currentIndex < filteredFriends.count {
                                selectedFriend = filteredFriends[currentIndex]
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(EPTheme.card)
                                    .frame(width: 50, height: 50)
                                    .overlay(Circle().stroke(EPTheme.accent.opacity(0.3), lineWidth: 2))
                                Image(systemName: "person.text.rectangle")
                                    .font(.system(size: 18))
                                    .foregroundStyle(EPTheme.accent)
                            }
                        }

                        Button { completeSwipe(.right) } label: {
                            ZStack {
                                Circle()
                                    .fill(EPTheme.card)
                                    .frame(width: 64, height: 64)
                                    .overlay(Circle().stroke(Color.green.opacity(0.3), lineWidth: 2))
                                Image(systemName: "hand.wave.fill")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                    .padding(.vertical, 14)

                } else {
                    // All cards viewed
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "person.2.circle")
                            .font(.system(size: 64))
                            .foregroundStyle(EPTheme.softText.opacity(0.5))
                        Text("You've seen everyone nearby!")
                            .font(.system(.title3, design: .serif).weight(.semibold))
                        Text("Check back later for new people in your community.")
                            .font(.system(.subheadline, design: .serif))
                            .foregroundStyle(EPTheme.softText)
                            .multilineTextAlignment(.center)
                        Button {
                            withAnimation { currentIndex = 0 }
                        } label: {
                            Text("Start Over")
                                .font(.system(.subheadline, design: .serif).weight(.semibold))
                                .foregroundStyle(EPTheme.accent)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 10)
                                .background(Capsule().fill(EPTheme.accent.opacity(0.15)))
                        }
                    }
                    .padding(.horizontal, 40)
                    Spacer()
                }
            }

            // Match overlay
            if showMatchOverlay, let matched = matchedFriend {
                matchOverlayView(matched)
                    .transition(.opacity.combined(with: .scale))
                    .zIndex(10)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                communityFilterHeader
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { showBarcodeSheet = true } label: {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 18))
                        .foregroundStyle(EPTheme.accent)
                }
            }
        }
        .sheet(isPresented: $showBarcodeSheet) { barcodeSheet }
        .sheet(isPresented: $showScanner) {
            QRScannerView(
                onScan: { code in
                    showScanner = false
                    Task {
                        do {
                            let newFriend = try await store.addFriendByCode(code)
                            alertMessage = "Friend request sent to \(newFriend.name)!"
                        } catch {
                            alertMessage = "Could not add friend: \(error.localizedDescription)"
                        }
                        showAlert = true
                    }
                },
                onCancel: { showScanner = false }
            )
        }
        .alert(alertMessage ?? "", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        }
        .sheet(item: $selectedFriend) { friend in
            NavigationStack { FriendDetailView(friend: friend) }
        }
    }

    // MARK: – Community Filter Header

    private var communityFilterHeader: some View {
        Menu {
            ForEach(CommunityFilter.allCases, id: \.rawValue) { filter in
                Button {
                    withAnimation {
                        store.communityFilter = filter
                        currentIndex = 0 // Reset to first card when filter changes
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
                Text("Connect")
                    .font(.system(.headline, design: .serif))
                    .foregroundStyle(Color.primary)
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
            }
        }
    }

    // MARK: – Friend Card (bigger, more prominent)

    private func friendCard(_ friend: FriendProfile) -> some View {
        VStack(spacing: 0) {
            // Large gradient avatar header
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: gradientForFriend(friend),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 240)

                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.22))
                            .frame(width: 110, height: 110)
                        Text(friend.avatarInitials)
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 12))
                        Text(friend.buildingName)
                            .font(.system(.caption, design: .rounded).weight(.medium))
                    }
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.white.opacity(0.15)))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

            // Info section
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(friend.name)
                            .font(.system(.title2, design: .serif).weight(.bold))
                        Text("\(friend.age) • \(friend.favoriteActivity)")
                            .font(.system(.subheadline, design: .serif))
                            .foregroundStyle(EPTheme.softText)
                    }
                    Spacer()
                    if friend.mutualFriends > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 11))
                            Text("\(friend.mutualFriends) mutual")
                                .font(.system(.caption2, design: .rounded).weight(.medium))
                        }
                        .foregroundStyle(EPTheme.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(EPTheme.accent.opacity(0.12)))
                    }
                }

                Text(friend.bio)
                    .font(.system(.subheadline, design: .serif))
                    .foregroundStyle(Color.primary.opacity(0.85))
                    .lineLimit(3)

                // Shared interests highlight
                let shared = sharedInterests(with: friend)
                if !shared.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 11))
                                .foregroundStyle(.yellow)
                            Text("You both like")
                                .font(.system(.caption, design: .rounded).weight(.semibold))
                                .foregroundStyle(EPTheme.accent)
                        }
                        FlowLayout(spacing: 6) {
                            ForEach(shared, id: \.self) { interest in
                                Text(interest)
                                    .font(.system(.caption, design: .rounded).weight(.medium))
                                    .foregroundStyle(EPTheme.accent)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(
                                        Capsule().fill(EPTheme.accent.opacity(0.12))
                                    )
                            }
                        }
                    }
                }

                // Other interests
                let other = friend.interests.filter { !shared.contains($0) }
                if !other.isEmpty {
                    FlowLayout(spacing: 6) {
                        ForEach(other, id: \.self) { interest in
                            Text(interest)
                                .font(.system(.caption, design: .rounded).weight(.medium))
                                .foregroundStyle(Color.primary.opacity(0.7))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Capsule().fill(EPTheme.card))
                                .overlay(Capsule().stroke(EPTheme.cardStroke, lineWidth: 1))
                        }
                    }
                }

                // Stats row
                HStack(spacing: 0) {
                    miniStat(icon: "flame.fill", value: "\(friend.workoutsThisWeek)", label: "This week", color: .orange)
                    Divider().frame(height: 30).overlay(EPTheme.divider)
                    miniStat(icon: "building.2", value: friend.buildingName.components(separatedBy: " ").first ?? "", label: "Building", color: .blue)
                    Divider().frame(height: 30).overlay(EPTheme.divider)
                    miniStat(icon: "person.2", value: "\(friend.mutualFriends)", label: "Mutual", color: .purple)
                }
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(EPTheme.card.opacity(0.5)))
            }
            .padding(16)
        }
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(EPTheme.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(EPTheme.cardStroke, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 16, x: 0, y: 6)
    }

    // MARK: – Match Overlay

    private func matchOverlayView(_ friend: FriendProfile) -> some View {
        ZStack {
            Color.black.opacity(0.75).ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                Image(systemName: "hands.clap.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(EPTheme.accent)

                Text("It's a Match!")
                    .font(.system(.largeTitle, design: .serif).weight(.bold))
                    .foregroundStyle(.white)

                Text("You and \(friend.name) both want to connect!")
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))

                let shared = sharedInterests(with: friend)
                if !shared.isEmpty {
                    VStack(spacing: 8) {
                        Text("Suggested activities together:")
                            .font(.system(.subheadline, design: .serif).weight(.medium))
                            .foregroundStyle(.white.opacity(0.7))

                        ForEach(suggestedActivities(from: shared), id: \.self) { activity in
                            HStack(spacing: 8) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.yellow)
                                Text(activity)
                                    .font(.system(.subheadline, design: .serif))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .padding(.top, 8)
                }

                Spacer()

                Button {
                    withAnimation { showMatchOverlay = false; matchedFriend = nil }
                } label: {
                    Text("Keep Swiping")
                        .font(.system(.headline, design: .serif))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(EPTheme.accent)
                        )
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: – Helpers

    private func sharedInterests(with friend: FriendProfile) -> [String] {
        friend.interests.filter { myInterests.contains($0) }
    }

    private func suggestedActivities(from shared: [String]) -> [String] {
        let activityMap: [String: String] = [
            "Running": "Go for a morning run together",
            "Yoga": "Join a yoga flow session",
            "HIIT": "Try a HIIT class together",
            "Swimming": "Swim laps at the pool",
            "Strength Training": "Hit the gym for a lifting session",
            "Nutrition": "Share meal prep tips",
            "Mobility": "Do a recovery & mobility session",
            "Recovery": "Book a sauna session together",
            "CrossFit": "Try a CrossFit WOD together",
            "Meditation": "Attend a meditation session",
            "Cycling": "Go for a group ride",
            "Pilates": "Take a Pilates class together",
            "Dance Fitness": "Join a dance fitness class",
            "Basketball": "Play a pickup game",
            "Hiking": "Plan a weekend hike"
        ]
        return shared.compactMap { activityMap[$0] }
    }

    private func miniStat(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(color)
                Text(value)
                    .font(.system(.caption, design: .rounded).weight(.bold))
            }
            Text(label)
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(EPTheme.softText)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: – Swipe Logic

    private func completeSwipe(_ direction: SwipeDirection) {
        let offScreenX: CGFloat = direction == .right ? 500 : -500
        withAnimation(.easeIn(duration: 0.25)) {
            dragOffset = CGSize(width: offScreenX, height: 0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            if direction == .right && currentIndex < filteredFriends.count {
                var newFriend = filteredFriends[currentIndex]
                newFriend.isFriend = true
                store.friends.append(newFriend)
                matchedFriend = newFriend
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showMatchOverlay = true
                }
            }
            currentIndex += 1
            dragOffset = .zero
            swipeDirection = nil
        }
    }

    private func gradientForFriend(_ friend: FriendProfile) -> [Color] {
        let gradients: [[Color]] = [
            [.blue, .purple],
            [.teal, .blue],
            [.indigo, .pink],
            [.green, .teal],
            [.purple, .indigo],
            [.orange, .pink],
            [.cyan, .blue],
            [.mint, .green]
        ]
        let index = abs(friend.name.hashValue) % gradients.count
        return gradients[index]
    }

    // MARK: – Barcode Sheet

    private var barcodeSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                Text("My Friend Code")
                    .font(.system(.title3, design: .serif).weight(.semibold))
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white)
                        .frame(width: 240, height: 240)
                        .shadow(color: .black.opacity(0.08), radius: 8)
                    if let userId = KeychainManager.shared.get(key: .userId), !userId.isEmpty {
                        QRCodeView(content: userId, size: 200)
                    } else {
                        Image(systemName: "qrcode")
                            .font(.system(size: 150))
                            .foregroundStyle(.black)
                    }
                }
                Text(store.profile.name)
                    .font(.system(.headline, design: .serif))
                Text("@\(store.profile.name.lowercased().replacingOccurrences(of: " ", with: "."))")
                    .font(.system(.subheadline, design: .serif))
                    .foregroundStyle(EPTheme.softText)
                VStack(spacing: 8) {
                    Text("Share your code or scan a friend's to connect instantly")
                        .font(.system(.subheadline, design: .serif))
                        .foregroundStyle(EPTheme.softText)
                        .multilineTextAlignment(.center)
                    Button {
                        showBarcodeSheet = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showScanner = true
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                            Text("Scan Code")
                        }
                        .font(.system(.subheadline, design: .serif).weight(.semibold))
                        .foregroundStyle(.black.opacity(0.85))
                        .padding(.horizontal, 28)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(EPTheme.accent))
                    }
                }
                Spacer()
            }
            .padding(20)
            .navigationTitle("Add Friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showBarcodeSheet = false }
                }
            }
        }
    }
}
