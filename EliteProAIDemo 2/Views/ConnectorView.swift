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
                        title: "Find Friends",
                        subtitle: "Swipe to connect",
                        color: .purple,
                        destination: AnyView(FindFriendsView())
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
                
                // Amenity Invitations
                if !store.amenityInvitations.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Invitations")
                            .font(.system(.title3, design: .rounded).weight(.semibold))
                            .foregroundStyle(Color.primary)
                        
                        ForEach(store.amenityInvitations) { invitation in
                            invitationCard(invitation)
                        }
                    }
                    
                    Divider()
                        .overlay(EPTheme.divider)
                        .padding(.vertical, 8)
                }
                
                // Building Amenities
                VStack(alignment: .leading, spacing: 12) {
                    Text("Building Amenities")
                        .font(.system(.title3, design: .rounded).weight(.semibold))
                        .foregroundStyle(Color.primary)
                    
                    ForEach(store.amenities) { amenity in
                        amenityCard(amenity)
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Connector")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Invitation Card
    
    @ViewBuilder
    private func invitationCard(_ invitation: AmenityInvitation) -> some View {
        EPCard {
            VStack(alignment: .leading, spacing: 10) {
                // Friend info
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(EPTheme.accent.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Text(invitation.friendInitials)
                            .font(.system(.caption, design: .rounded).weight(.bold))
                            .foregroundStyle(EPTheme.accent)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(invitation.fromFriend)
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        Text("invited you")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(EPTheme.softText)
                    }
                    
                    Spacer()
                }
                
                // Amenity details
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(EPTheme.accent.opacity(0.15))
                        Image(systemName: invitation.imagePlaceholder)
                            .font(.system(size: 20))
                            .foregroundStyle(EPTheme.accent)
                    }
                    .frame(width: 44, height: 44)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(invitation.amenityName)
                            .font(.system(.body, design: .rounded).weight(.semibold))
                            .foregroundStyle(Color.primary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 10))
                            Text(invitation.time, style: .date)
                            Text("at")
                            Text(invitation.time, style: .time)
                            Text("·")
                            Text(invitation.duration)
                        }
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(EPTheme.softText)
                        
                        if invitation.reservationConfirmed {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 10))
                                Text("Reservation confirmed")
                            }
                            .font(.system(.caption2, design: .rounded))
                            .foregroundStyle(.green)
                        }
                    }
                }
                
                // Message
                Text(invitation.message)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Color.primary.opacity(0.9))
                    .padding(.top, 4)
                
                // Action buttons
                HStack(spacing: 10) {
                    Button {
                        // Accept invitation
                    } label: {
                        Text("Accept")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(EPTheme.accent)
                            .cornerRadius(10)
                    }
                    
                    Button {
                        // Decline invitation
                    } label: {
                        Text("Maybe Later")
                            .font(.system(.subheadline, design: .rounded).weight(.medium))
                            .foregroundStyle(EPTheme.softText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(EPTheme.card)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(EPTheme.cardStroke, lineWidth: 1)
                            )
                    }
                }
                .padding(.top, 6)
            }
        }
    }
    
    // MARK: - Amenity Card
    
    @ViewBuilder
    private func amenityCard(_ amenity: Amenity) -> some View {
        EPCard {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(EPTheme.accent.opacity(0.15))
                    Image(systemName: amenity.imagePlaceholder)
                        .font(.system(size: 20))
                        .foregroundStyle(EPTheme.accent)
                }
                .frame(width: 44, height: 44)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(amenity.name)
                            .font(.system(.body, design: .rounded).weight(.semibold))
                            .foregroundStyle(Color.primary)
                        
                        if amenity.requiresReservation {
                            Text("• Reservation")
                                .font(.system(.caption2, design: .rounded))
                                .foregroundStyle(EPTheme.accent)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(EPTheme.accent.opacity(0.15)))
                        }
                    }
                    
                    Text(amenity.description)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(EPTheme.softText)
                        .lineLimit(2)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                        Text(amenity.availableTimes.joined(separator: " · "))
                    }
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(EPTheme.softText)
                }
                
                Spacer()
                
                if amenity.requiresReservation {
                    Button {
                        // Book amenity
                    } label: {
                        Text("Book")
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .foregroundStyle(EPTheme.accent)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(EPTheme.accent.opacity(0.15)))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
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
}