import SwiftUI

struct ConnectorView: View {
    @EnvironmentObject private var store: AppStore
    @State private var search: String = ""

    var filtered: [Trainer] {
        let q = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty { return store.trainers }
        return store.trainers.filter { $0.name.lowercased().contains(q) || $0.specialty.lowercased().contains(q) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // Header
                VStack(alignment: .leading, spacing: 6) {
                    Text("Connect & Grow")
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundStyle(Color.primary)
                    Text("Find trainers, join groups, and take your fitness to the next level")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(EPTheme.softText)
                }
                .padding(.bottom, 4)

                // Quick Actions Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    quickActionCard(
                        icon: "person.2.fill",
                        title: "Join a Group",
                        subtitle: "Find your community",
                        color: .blue,
                        destination: AnyView(GroupsView())
                    )
                    
                    quickActionCard(
                        icon: "person.crop.circle.badge.plus",
                        title: "Find Trainers",
                        subtitle: "Get expert guidance",
                        color: .purple,
                        destination: AnyView(TrainerListView())
                    )
                    
                    quickActionCard(
                        icon: "figure.mixed.cardio",
                        title: "Group Classes",
                        subtitle: "Join a session",
                        color: .green,
                        destination: AnyView(GroupClassView())
                    )
                    
                    quickActionCard(
                        icon: "plus.circle.fill",
                        title: "Create Group",
                        subtitle: "Start your own",
                        color: .orange,
                        destination: AnyView(CreateGroupView())
                    )
                }
                
                Divider()
                    .overlay(EPTheme.divider)
                    .padding(.vertical, 8)
                
                // Wellness Tools
                VStack(alignment: .leading, spacing: 12) {
                    Text("My Wellness Tools")
                        .font(.system(.title3, design: .rounded).weight(.semibold))
                        .foregroundStyle(Color.primary)
                    
                    wellnessToolRow(
                        icon: "heart.text.square.fill",
                        title: "Nutrition Check-In",
                        subtitle: "Track your meals and progress",
                        color: .green,
                        destination: AnyView(NutritionView())
                    )
                    
                    wellnessToolRow(
                        icon: "figure.strengthtraining.traditional",
                        title: "Workout Log",
                        subtitle: "Record today's training session",
                        color: .red,
                        destination: AnyView(WorkoutLogView())
                    )
                    
                    wellnessToolRow(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Habits & Performance",
                        subtitle: "Track streaks and improvements",
                        color: .cyan,
                        destination: AnyView(HabitsTrackerView())
                    )
                }
                
                Divider()
                    .overlay(EPTheme.divider)
                    .padding(.vertical, 8)
                
                // Featured Trainers
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Featured Trainers")
                            .font(.system(.title3, design: .rounded).weight(.semibold))
                            .foregroundStyle(Color.primary)
                        Spacer()
                        NavigationLink {
                            TrainerListView()
                        } label: {
                            Text("View All")
                                .font(.system(.subheadline, design: .rounded).weight(.medium))
                                .foregroundStyle(EPTheme.accent)
                        }
                    }
                    
                    ForEach(store.trainers.prefix(3)) { trainer in
                        trainerCard(trainer)
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Connector")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    private func quickActionCard(icon: String, title: String, subtitle: String, color: Color, destination: AnyView) -> some View {
        NavigationLink {
            destination
        } label: {
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(color.opacity(0.15))
                    Image(systemName: icon)
                        .font(.system(size: 28))
                        .foregroundStyle(color)
                }
                .frame(height: 80)
                
                VStack(spacing: 2) {
                    Text(title)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(Color.primary)
                    Text(subtitle)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(EPTheme.softText)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(EPTheme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(EPTheme.cardStroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func wellnessToolRow(icon: String, title: String, subtitle: String, color: Color, destination: AnyView) -> some View {
        NavigationLink {
            destination
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(color.opacity(0.15))
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundStyle(color)
                }
                .frame(width: 44, height: 44)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(Color.primary)
                    Text(subtitle)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(EPTheme.softText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(EPTheme.softText)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(EPTheme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(EPTheme.cardStroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func trainerCard(_ trainer: Trainer) -> some View {
        NavigationLink {
            TrainerDetailView(trainer: trainer)
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(EPTheme.accent.opacity(0.15))
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(EPTheme.accent)
                }
                .frame(width: 50, height: 50)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(trainer.name)
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(Color.primary)
                    Text(trainer.specialty)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(EPTheme.softText)
                    Text("⭐️ \(String(format: "%.1f", trainer.rating)) · $\(trainer.pricePerSession)/session")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(EPTheme.softText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(EPTheme.softText)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(EPTheme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(EPTheme.cardStroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Trainer List View

struct TrainerListView: View {
    @EnvironmentObject private var store: AppStore
    @State private var search: String = ""

    var filtered: [Trainer] {
        let q = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty { return store.trainers }
        return store.trainers.filter { $0.name.lowercased().contains(q) || $0.specialty.lowercased().contains(q) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                EPCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Find a trainer")
                            .font(.system(.headline, design: .rounded))
                        TextField("Search specialty or name", text: $search)
                            .textFieldStyle(.roundedBorder)
                    }
                }

                ForEach(filtered) { t in
                    EPCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(t.name).font(.system(.headline, design: .rounded))
                                Text(t.specialty).font(.system(.subheadline, design: .rounded)).foregroundStyle(EPTheme.softText)
                                Text("⭐️ \(String(format: "%.1f", t.rating)) · $\(t.pricePerSession)/session")
                                    .font(.system(.footnote, design: .rounded))
                                    .foregroundStyle(EPTheme.softText)
                            }
                            Spacer()
                            NavigationLink {
                                TrainerDetailView(trainer: t)
                            } label: {
                                Text("View")
                                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(Capsule().fill(EPTheme.accent.opacity(0.18)))
                                    .overlay(Capsule().stroke(EPTheme.accent.opacity(0.55), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Find Trainers")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TrainerDetailView: View {
    @EnvironmentObject private var store: AppStore
    let trainer: Trainer
    @State private var note: String = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                EPCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(trainer.name).font(.system(.title3, design: .rounded).weight(.semibold))
                        Text(trainer.specialty).foregroundStyle(EPTheme.softText)
                        Text("⭐️ \(String(format: "%.1f", trainer.rating)) · $\(trainer.pricePerSession)/session")
                            .font(.system(.footnote, design: .rounded))
                            .foregroundStyle(EPTheme.softText)
                    }
                }

                EPCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Message")
                            .font(.system(.headline, design: .rounded))
                        TextField("What do you want to work on?", text: $note, axis: .vertical)
                            .lineLimit(3...6)
                            .textFieldStyle(.roundedBorder)

                        Button {
                            store.findOrCreateConversation(with: trainer.name, initialMessage: "Hi \(trainer.name) — \(note.isEmpty ? "I'd like to chat about coaching." : note)")
                            store.earnCredits(2)
                            note = ""
                        } label: {
                            Text("Send (Demo)")
                        }
                        .buttonStyle(EPButtonStyle())
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Trainer")
        .navigationBarTitleDisplayMode(.inline)
    }
}
