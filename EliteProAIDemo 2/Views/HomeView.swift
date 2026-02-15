import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {

                profileCard

                creditsCard

                Text("My Wellness")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(EPTheme.softText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 2)

                VStack(spacing: 10) {
                    NavigationLink {
                        CoachingView()
                    } label: {
                        HStack {
                            Image(systemName: "person")
                            Text("1–1 Coaching Session")
                            Spacer()
                        }
                    }
                    .buttonStyle(EPButtonStyle())

                    NavigationLink {
                        NutritionView()
                    } label: {
                        Text("Nutrition Check-In").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(EPButtonStyle())

                    NavigationLink {
                        GroupClassView()
                    } label: {
                        Text("Join a Group Class").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(EPButtonStyle())

                    NavigationLink {
                        CreateGroupView()
                    } label: {
                        Text("Create a Group").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(EPButtonStyle())

                    NavigationLink {
                        WorkoutLogView()
                    } label: {
                        Text("Workout Log").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(EPButtonStyle())

                    NavigationLink {
                        HabitsTrackerView()
                    } label: {
                        Text("Habits & Performance Tracker").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(EPButtonStyle())
                }

                chatPreview
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { store.persist() }
    }

    private var profileCard: some View {
        EPCard {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.07))
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 42))
                        .foregroundStyle(EPTheme.accent)
                }
                .frame(width: 66, height: 66)

                VStack(alignment: .leading, spacing: 4) {
                    Text(store.profile.name)
                        .font(.system(.title3, design: .rounded).weight(.semibold))
                    Text(store.profile.email)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(EPTheme.softText)
                        .lineLimit(1)
                }
                Spacer()
            }
        }
    }

    private var creditsCard: some View {
        EPCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Healthy Habit Credits:")
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
                        // demo: earn credits
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

                Divider().overlay(EPTheme.divider)

                Text("My Wellness")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(EPTheme.softText)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    private var chatPreview: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Chat")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.9))

            EPCard {
                VStack(spacing: 10) {
                    ForEach(store.chat.suffix(4)) { msg in
                        HStack {
                            if msg.isMe { Spacer(minLength: 20) }
                            Text(msg.text)
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(Color.white.opacity(0.95))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Color.white.opacity(msg.isMe ? 0.10 : 0.06))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                )
                            if !msg.isMe { Spacer(minLength: 20) }
                        }
                    }

                    NavigationLink {
                        ChatView()
                    } label: {
                        HStack {
                            Text("Write something…")
                                .foregroundStyle(EPTheme.softText)
                                .font(.system(.subheadline, design: .rounded))
                            Spacer()
                            Image(systemName: "paperplane.fill")
                                .foregroundStyle(EPTheme.softText)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.white.opacity(0.05))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.top, 8)
    }
}
