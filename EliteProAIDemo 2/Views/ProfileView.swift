import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showBarcodeSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                // MARK: – Avatar + Name + Building
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(EPTheme.accent.opacity(0.18))
                            .frame(width: 100, height: 100)
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(EPTheme.accent)
                    }

                    Text(store.profile.name)
                        .font(.system(.title2, design: .rounded).weight(.bold))

                    Text(store.profile.email)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(EPTheme.softText)

                    // Building info
                    HStack(spacing: 6) {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(EPTheme.accent)
                        Text(store.profile.buildingName)
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                        Text("•")
                            .foregroundStyle(EPTheme.softText)
                        Text(store.profile.buildingOwner)
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(EPTheme.softText)
                    }

                    HStack(spacing: 12) {
                        Text(store.profile.role)
                            .font(.system(.caption, design: .rounded).weight(.medium))
                            .foregroundStyle(EPTheme.accent)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(EPTheme.accent.opacity(0.15)))

                        Button {
                            showBarcodeSheet = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "qrcode")
                                    .font(.system(size: 12))
                                Text("My Code")
                                    .font(.system(.caption, design: .rounded).weight(.medium))
                            }
                            .foregroundStyle(EPTheme.accent)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(EPTheme.accent.opacity(0.15)))
                        }
                    }
                }
                .padding(.top, 8)

                // MARK: – Friends Summary
                NavigationLink {
                    FriendsView()
                } label: {
                    EPCard {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(EPTheme.accent.opacity(0.15))
                                    .frame(width: 44, height: 44)
                                Image(systemName: "person.2.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(EPTheme.accent)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Friends")
                                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                    .foregroundStyle(Color.primary)
                                Text("\(store.friends.count) friends")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(EPTheme.softText)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(EPTheme.softText)
                        }
                    }
                }
                .buttonStyle(.plain)

                // MARK: – Credits
                EPCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Healthy Habit Credits")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(EPTheme.softText)

                        ProgressView(value: Double(store.credits.current), total: Double(store.credits.goal))
                            .tint(EPTheme.accent)
                            .scaleEffect(x: 1.0, y: 2.0, anchor: .center)

                        HStack {
                            Text("\(store.credits.current)/\(store.credits.goal)")
                                .font(.system(.footnote, design: .rounded))
                                .foregroundStyle(EPTheme.softText)
                            Spacer()
                            Button {
                                store.earnCredits(5)
                            } label: {
                                Text("+5")
                                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Capsule().fill(EPTheme.accent.opacity(0.18)))
                                    .overlay(Capsule().stroke(EPTheme.accent.opacity(0.55), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // MARK: – Challenges Quick Look
                EPCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Active Challenges")
                            .font(.system(.headline, design: .rounded))
                        Text("Complete challenges to earn credits and level up.")
                            .foregroundStyle(EPTheme.softText)
                            .font(.system(.subheadline, design: .rounded))

                        ForEach(store.challenges.prefix(3)) { c in
                            HStack(spacing: 10) {
                                Image(systemName: c.imagePlaceholder)
                                    .foregroundStyle(EPTheme.accent)
                                    .frame(width: 28)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(c.title)
                                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                                    ProgressView(value: c.progress)
                                        .tint(EPTheme.accent)
                                }
                                Spacer()
                                Text("\(Int(c.progress * 100))%")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(EPTheme.softText)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                // MARK: – Weekly Stats (This Week / Last Week)
                weeklyStatsSection

                // MARK: – Rewards Redeemable
                EPCard {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Rewards")
                                .font(.system(.headline, design: .rounded))
                            Spacer()
                            NavigationLink {
                                RewardsView()
                            } label: {
                                Text("See All")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundStyle(EPTheme.accent)
                            }
                        }
                        Text("\(store.credits.current) credits available to redeem")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(EPTheme.softText)
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showBarcodeSheet) {
            barcodeSheet
        }
    }

    // MARK: – Barcode Sheet

    private var barcodeSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Text("My Friend Code")
                    .font(.system(.title3, design: .rounded).weight(.semibold))

                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white)
                        .frame(width: 220, height: 220)
                        .shadow(color: .black.opacity(0.08), radius: 8)

                    Image(systemName: "qrcode")
                        .font(.system(size: 150))
                        .foregroundStyle(.black)
                }

                Text(store.profile.name)
                    .font(.system(.headline, design: .rounded))
                Text("@\(store.profile.name.lowercased().replacingOccurrences(of: " ", with: "."))")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(EPTheme.softText)

                VStack(spacing: 8) {
                    Text("Scan a friend's code to connect instantly")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(EPTheme.softText)

                    Button {} label: {
                        HStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                            Text("Scan Code")
                        }
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(.white)
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

    @State private var selectedStatsTab: Int = 1

    private var weeklyStatsSection: some View {
        TabView(selection: $selectedStatsTab) {
            // Last Week
            EPCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Last Week")
                            .font(.system(.title3, design: .rounded).weight(.semibold))
                        Spacer()
                        Text("Feb 3 – 9")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(EPTheme.softText)
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        profileStatBox(icon: "flame.fill", value: "\(store.lastWeekStats.workoutsCompleted)", label: "Workouts", color: .orange)
                        profileStatBox(icon: "heart.fill", value: "\(store.lastWeekStats.avgHeartRate) bpm", label: "Avg Heart Rate", color: .red)
                        profileStatBox(icon: "moon.zzz.fill", value: String(format: "%.1fh", store.lastWeekStats.sleepHours), label: "Avg Sleep", color: .indigo)
                        profileStatBox(icon: "person.3.fill", value: "\(store.lastWeekStats.activitiesJoined)", label: "Activities Joined", color: .teal)
                    }
                }
            }
            .tag(0)

            // This Week
            EPCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("This Week")
                            .font(.system(.title3, design: .rounded).weight(.semibold))
                        Spacer()
                        Text("Feb 10 – 16")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(EPTheme.softText)
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        profileStatBox(icon: "flame.fill", value: "\(store.weeklyStats.workoutsCompleted)", label: "Workouts", color: .orange)
                        profileStatBox(icon: "heart.fill", value: "\(store.weeklyStats.avgHeartRate) bpm", label: "Avg Heart Rate", color: .red)
                        profileStatBox(icon: "moon.zzz.fill", value: String(format: "%.1fh", store.weeklyStats.sleepHours), label: "Avg Sleep", color: .indigo)
                        profileStatBox(icon: "person.3.fill", value: "\(store.weeklyStats.activitiesJoined)", label: "Activities Joined", color: .teal)
                    }
                }
            }
            .tag(1)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .frame(height: 200)
    }

    private func profileStatBox(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(color)
                Text(value)
                    .font(.system(.headline, design: .rounded).weight(.bold))
            }
            Text(label)
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(EPTheme.softText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(color.opacity(0.08)))
    }
}

// MARK: – Story Viewer (Instagram-style full-screen)

struct StoryViewer: View {
    let friend: FriendProfile
    @Binding var currentIndex: Int
    let onDismiss: () -> Void
    @State private var progress: CGFloat = 0
    @State private var timer: Timer? = nil

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: currentStory?.gradientColors ?? [.black, .gray],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack {
                // Progress bars
                HStack(spacing: 4) {
                    ForEach(0..<friend.storyItems.count, id: \.self) { index in
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.white.opacity(0.3))
                                .overlay(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.white)
                                        .frame(width: barWidth(for: index, totalWidth: geo.size.width))
                                }
                        }
                        .frame(height: 3)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // Header
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 36, height: 36)
                        Text(friend.avatarInitials)
                            .font(.system(.caption, design: .rounded).weight(.bold))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text(friend.name)
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundStyle(.white)
                        if let story = currentStory {
                            Text(story.timestamp, style: .relative)
                                .font(.system(.caption2, design: .rounded))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }

                    Spacer()

                    Button {
                        stopTimer()
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(8)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                Spacer()

                // Story content
                if let story = currentStory {
                    VStack(spacing: 20) {
                        Image(systemName: story.imagePlaceholder)
                            .font(.system(size: 80))
                            .foregroundStyle(.white.opacity(0.9))

                        Text(story.caption)
                            .font(.system(.title3, design: .rounded).weight(.semibold))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }

                    Spacer()
                }
            }

            // Tap zones
            HStack(spacing: 0) {
                // Left tap (previous)
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        goToPrevious()
                    }

                // Right tap (next)
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        goToNext()
                    }
            }
        }
        .onAppear { startTimer() }
        .onDisappear { stopTimer() }
    }

    private var currentStory: StoryItem? {
        guard currentIndex < friend.storyItems.count else { return nil }
        return friend.storyItems[currentIndex]
    }

    private func barWidth(for index: Int, totalWidth: CGFloat) -> CGFloat {
        if index < currentIndex {
            return totalWidth
        } else if index == currentIndex {
            return totalWidth * progress
        } else {
            return 0
        }
    }

    private func startTimer() {
        progress = 0
        timer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { _ in
            withAnimation(.linear(duration: 0.03)) {
                progress += 0.006  // ~5 seconds per story
            }
            if progress >= 1.0 {
                goToNext()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func goToNext() {
        stopTimer()
        if currentIndex < friend.storyItems.count - 1 {
            currentIndex += 1
            startTimer()
        } else {
            onDismiss()
        }
    }

    private func goToPrevious() {
        stopTimer()
        if currentIndex > 0 {
            currentIndex -= 1
        }
        startTimer()
    }
}
