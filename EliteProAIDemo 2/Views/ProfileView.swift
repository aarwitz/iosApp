import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                // MARK: – Avatar + Name
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

                    Text(store.profile.role)
                        .font(.system(.caption, design: .rounded).weight(.medium))
                        .foregroundStyle(EPTheme.accent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(EPTheme.accent.opacity(0.15)))
                }
                .padding(.top, 8)

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

                // MARK: – Stats Snapshot
                EPCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("This Week")
                            .font(.system(.headline, design: .rounded))

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            statTile(icon: "flame.fill", label: "Workouts", value: "\(store.weeklyStats.workoutsCompleted)")
                            statTile(icon: "heart.fill", label: "Avg HR", value: "\(store.weeklyStats.avgHeartRate) bpm")
                            statTile(icon: "moon.fill", label: "Sleep", value: String(format: "%.1fh", store.weeklyStats.sleepHours))
                            statTile(icon: "person.3.fill", label: "Activities", value: "\(store.weeklyStats.activitiesJoined)")
                        }
                    }
                }

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
    }

    private func statTile(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(EPTheme.accent)
            Text(value)
                .font(.system(.headline, design: .rounded).weight(.bold))
            Text(label)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(EPTheme.softText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(EPTheme.card))
    }
}
