import SwiftUI

struct FindFriendsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var currentIndex: Int = 0
    @State private var dragOffset: CGSize = .zero
    @State private var swipeDirection: SwipeDirection? = nil
    @State private var showBarcodeSheet = false
    @State private var showScanner = false
    @State private var selectedFriend: FriendProfile? = nil
    @State private var alertMessage: String? = nil
    @State private var showAlert = false

    enum SwipeDirection {
        case left, right
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top bar with barcode scanner
//            HStack {
//                Text("Find Friends")
//                    .font(.system(.title2, design: .serif).weight(.bold))
//                Spacer()
//                Button {
//                    showBarcodeSheet = true
//                } label: {
//                    Image(systemName: "qrcode.viewfinder")
//                        .font(.system(size: 22))
//                        .foregroundStyle(EPTheme.accent)
//                        .padding(10)
//                        .background(Circle().fill(EPTheme.card))
//                        .overlay(Circle().stroke(EPTheme.cardStroke, lineWidth: 1))
//                }
//            }
//            .padding(.horizontal, 16)
//            .padding(.top, 8)
//            .padding(.bottom, 12)

            if currentIndex < store.discoverableFriends.count {
                // Card stack
                ZStack {
                    // Next card (behind)
                    if currentIndex + 1 < store.discoverableFriends.count {
                        friendCard(store.discoverableFriends[currentIndex + 1])
                            .scaleEffect(0.95)
                            .offset(y: 8)
                            .opacity(0.6)
                    }

                    // Current card (front)
                    friendCard(store.discoverableFriends[currentIndex])
                        .offset(dragOffset)
                        .rotationEffect(.degrees(Double(dragOffset.width / 20)))
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
                        // Pass indicator (left)
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.red.opacity(swipeDirection == .left ? 0.8 : 0))
                            .padding(.leading, 30)

                        Spacer()

                        // Connect indicator (right)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.green.opacity(swipeDirection == .right ? 0.8 : 0))
                            .padding(.trailing, 30)
                    }
                    .allowsHitTesting(false)
                }
                .padding(.horizontal, 16)

                Spacer().frame(height: 20)

                // Action buttons
                HStack(spacing: 40) {
                    // Pass
                    Button {
                        completeSwipe(.left)
                    } label: {
                        ZStack {
                            Circle()
                                .fill(EPTheme.card)
                                .frame(width: 60, height: 60)
                                .overlay(Circle().stroke(Color.red.opacity(0.3), lineWidth: 2))
                            Image(systemName: "xmark")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(.red)
                        }
                    }

                    // View Profile
                    Button {
                        if currentIndex < store.discoverableFriends.count {
                            selectedFriend = store.discoverableFriends[currentIndex]
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(EPTheme.card)
                                .frame(width: 48, height: 48)
                                .overlay(Circle().stroke(EPTheme.accent.opacity(0.3), lineWidth: 2))
                            Image(systemName: "person.text.rectangle")
                                .font(.system(size: 18))
                                .foregroundStyle(EPTheme.accent)
                        }
                    }

                    // Connect
                    Button {
                        completeSwipe(.right)
                    } label: {
                        ZStack {
                            Circle()
                                .fill(EPTheme.card)
                                .frame(width: 60, height: 60)
                                .overlay(Circle().stroke(Color.green.opacity(0.3), lineWidth: 2))
                            Image(systemName: "hand.wave.fill")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(.green)
                        }
                    }
                }
                .padding(.bottom, 20)

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
        .navigationTitle("Find Friends")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showBarcodeSheet = true
                } label: {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 18, weight: .medium))
                }
                .accessibilityLabel("Scan Friend Code")
            }
        }
        .task {
            // Load discoverable users when the view appears
            await store.loadDiscoverableUsers()
            currentIndex = 0
        }
        .sheet(isPresented: $showBarcodeSheet) {
            barcodeSheet
        }
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
            NavigationStack {
                FriendDetailView(friend: friend)
            }
        }
    }

    // MARK: – Friend Card

    private func friendCard(_ friend: FriendProfile) -> some View {
        VStack(spacing: 0) {
            // Avatar area
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: gradientForFriend(friend),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 200)

                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 90, height: 90)
                        Text(friend.avatarInitials)
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 11))
                        Text(friend.buildingName)
                            .font(.system(.caption, design: .rounded).weight(.medium))
                    }
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.white.opacity(0.15)))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            // Info section
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(friend.name)
                            .font(.system(.title3, design: .serif).weight(.bold))
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

                // Interests
                FlowLayout(spacing: 6) {
                    ForEach(friend.interests, id: \.self) { interest in
                        Text(interest)
                            .font(.system(.caption, design: .rounded).weight(.medium))
                            .foregroundStyle(Color.primary.opacity(0.8))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(EPTheme.card)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(EPTheme.cardStroke, lineWidth: 1)
                            )
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
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(EPTheme.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(EPTheme.cardStroke, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
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
            if direction == .right && currentIndex < store.discoverableFriends.count {
                let friend = store.discoverableFriends[currentIndex]
                // Add via API if we have their userID
                if let friendUserId = friend.userID {
                    Task {
                        do {
                            try await store.addFriendByCode(friendUserId.uuidString)
                        } catch {
                            print("[FindFriends] Could not add friend: \(error.localizedDescription)")
                        }
                    }
                } else {
                    // Fallback: add locally only
                    var newFriend = store.discoverableFriends[currentIndex]
                    newFriend.isFriend = true
                    store.friends.append(newFriend)
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

                // Real QR code generated from the user's backend ID
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

// MARK: – Friend Detail View

struct FriendDetailView: View {
    let friend: FriendProfile
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var isConnecting = false
    @State private var showChat = false
    @State private var chatConversation: Conversation? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                ZStack(alignment: .bottom) {
                    LinearGradient(
                        colors: gradientForFriend(friend),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 180)

                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.25))
                                .frame(width: 100, height: 100)
                            Text(friend.avatarInitials)
                                .font(.system(size: 38, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        .offset(y: 50)
                    }
                }

                VStack(spacing: 6) {
                    Text(friend.name)
                        .font(.system(.title2, design: .serif).weight(.bold))
                        .padding(.top, 36)

                    if friend.age > 0 {
                        Text("\(friend.age) years old")
                            .font(.system(.subheadline, design: .serif))
                            .foregroundStyle(EPTheme.softText)
                    }

                    if !friend.buildingName.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "building.2.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(EPTheme.accent)
                            Text(friend.buildingName)
                                .font(.system(.subheadline, design: .serif).weight(.medium))
                            if !friend.buildingOwner.isEmpty {
                                Text("•")
                                    .foregroundStyle(EPTheme.softText)
                                Text(friend.buildingOwner)
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(EPTheme.softText)
                            }
                        }
                    }
                }

                // Bio
                if !friend.bio.isEmpty {
                    EPCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("About")
                                .font(.system(.headline, design: .serif))
                            Text(friend.bio)
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(Color.primary.opacity(0.85))
                        }
                    }
                }

                // Interests
                if !friend.interests.isEmpty {
                    EPCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Interests")
                                .font(.system(.headline, design: .serif))
                            FlowLayout(spacing: 8) {
                                ForEach(friend.interests, id: \.self) { interest in
                                    Text(interest)
                                        .font(.system(.subheadline, design: .serif).weight(.medium))
                                        .foregroundStyle(EPTheme.accent)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 7)
                                        .background(Capsule().fill(EPTheme.accent.opacity(0.12)))
                                }
                            }
                        }
                    }
                }

                // Stats
                if friend.workoutsThisWeek > 0 || friend.mutualFriends > 0 {
                    EPCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Activity")
                                .font(.system(.headline, design: .serif))
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                detailStat(icon: "flame.fill", value: "\(friend.workoutsThisWeek)", label: "Workouts this week", color: .orange)
                                detailStat(icon: "person.2.fill", value: "\(friend.mutualFriends)", label: "Mutual friends", color: .purple)
                                if !friend.favoriteActivity.isEmpty {
                                    detailStat(icon: "star.fill", value: friend.favoriteActivity, label: "Favorite activity", color: .yellow)
                                }
                                if !friend.buildingName.isEmpty {
                                    detailStat(icon: "building.2.fill", value: friend.buildingName.components(separatedBy: " ").first ?? "", label: "Building", color: .blue)
                                }
                            }
                        }
                    }
                }

                // Actions
                VStack(spacing: 12) {
                    if friend.isFriend {
                        // Message button for existing friends
                        Button {
                            isConnecting = true
                            Task {
                                let convo = await store.getOrCreateConversation(with: friend)
                                await MainActor.run {
                                    isConnecting = false
                                    chatConversation = convo
                                    showChat = true
                                }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                if isConnecting {
                                    ProgressView().frame(width: 20, height: 20)
                                } else {
                                    Image(systemName: "bubble.left.fill")
                                }
                                Text("Message")
                            }
                            .font(.system(.headline, design: .serif))
                            .foregroundStyle(.black.opacity(0.85))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(EPTheme.accent)
                            )
                        }
                        .disabled(isConnecting)
                    } else {
                        Button {
                            guard let userId = friend.userID else { return }
                            isConnecting = true
                            Task {
                                do {
                                    try await store.addFriendByCode(userId.uuidString)
                                } catch {
                                    print("[FriendDetail] Could not add friend: \(error.localizedDescription)")
                                }
                                await MainActor.run {
                                    isConnecting = false
                                    dismiss()
                                }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                if isConnecting {
                                    ProgressView().frame(width: 20, height: 20)
                                } else {
                                    Image(systemName: "hand.wave.fill")
                                }
                                Text("Connect")
                            }
                            .font(.system(.headline, design: .serif))
                            .foregroundStyle(.black.opacity(0.85))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(EPTheme.accent)
                            )
                        }
                        .disabled(isConnecting || friend.userID == nil)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
        .navigationDestination(
            isPresented: $showChat
        ) {
            if let convo = chatConversation {
                ChatDetailView(conversation: convo)
            }
        }
    }

    private func detailStat(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)
            Text(value)
                .font(.system(.caption, design: .rounded).weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(EPTheme.softText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(color.opacity(0.08)))
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
}

// MARK: – Flow Layout (for interest tags)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layoutSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layoutSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func layoutSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
