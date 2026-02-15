import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {

                profileCard

                creditsCard


                VStack(spacing: 10) {
                    NavigationLink {
                        CoachingView()
                    } label: {
                        HStack {
                            Image(systemName: "person")
                            Text("1–1 Coaching Session")
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
                        .fill(EPTheme.accent.opacity(0.1))
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
            Text("Messages")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(Color.primary.opacity(0.9))

            EPCard {
                VStack(spacing: 10) {
                    ForEach(store.conversations.prefix(3)) { conversation in
                        NavigationLink {
                            ChatDetailView(conversation: conversation)
                        } label: {
                            HStack(spacing: 10) {
                                ZStack {
                                    Circle()
                                        .fill(EPTheme.accent.opacity(0.15))
                                    Image(systemName: "person.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(EPTheme.accent)
                                }
                                .frame(width: 34, height: 34)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(conversation.contactName)
                                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                        .foregroundStyle(Color.primary)
                                    Text(conversation.lastMessage)
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundStyle(EPTheme.softText)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                if conversation.unreadCount > 0 {
                                    ZStack {
                                        Circle()
                                            .fill(EPTheme.accent)
                                        Text("\(conversation.unreadCount)")
                                            .font(.system(.caption2, design: .rounded).weight(.bold))
                                            .foregroundStyle(.black)
                                    }
                                    .frame(width: 18, height: 18)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        
                        if conversation.id != store.conversations.prefix(3).last?.id {
                            Divider().overlay(EPTheme.divider)
                        }
                    }

                    NavigationLink {
                        ChatListView()
                    } label: {
                        HStack {
                            Text("View all messages")
                                .foregroundStyle(EPTheme.accent)
                                .font(.system(.subheadline, design: .rounded).weight(.medium))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(EPTheme.accent)
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(EPTheme.accent.opacity(0.08))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(EPTheme.accent.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.top, 8)
    }
}
