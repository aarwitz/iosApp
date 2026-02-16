import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // MARK: – Amenity Invitations
                if !store.amenityInvitations.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "envelope.open.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(EPTheme.accent)
                            Text("Invitations")
                                .font(.system(.title3, design: .rounded).weight(.semibold))
                        }

                        ForEach(store.amenityInvitations) { invitation in
                            invitationCard(invitation)
                        }
                    }
                }

                Divider().overlay(EPTheme.divider)

                // MARK: – Suggested Connections
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 16))
                            .foregroundStyle(.purple)
                        Text("Suggested Connections")
                            .font(.system(.title3, design: .rounded).weight(.semibold))
                    }

                    Text("People you might want to meet")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(EPTheme.softText)

                    ForEach(store.discoverableFriends.prefix(4)) { friend in
                        suggestedConnectionCard(friend)
                    }
                }

                Divider().overlay(EPTheme.divider)

                // MARK: – Activity Updates
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.blue)
                        Text("Activity")
                            .font(.system(.title3, design: .rounded).weight(.semibold))
                    }

                    notificationRow(
                        icon: "person.2.fill",
                        iconColor: .green,
                        title: "Nina accepted your invitation",
                        subtitle: "Yoga Studio • Tomorrow at 7 AM",
                        time: "2h ago"
                    )

                    notificationRow(
                        icon: "trophy.fill",
                        iconColor: .yellow,
                        title: "You earned 5 credits!",
                        subtitle: "Completed: Walk 1,000 Steps Today",
                        time: "4h ago"
                    )

                    notificationRow(
                        icon: "person.crop.circle.badge.checkmark",
                        iconColor: .blue,
                        title: "New friend request from Tyler",
                        subtitle: "3 mutual friends • Echelon Seaport",
                        time: "6h ago"
                    )

                    notificationRow(
                        icon: "megaphone.fill",
                        iconColor: .orange,
                        title: "Seaport 5K Fun Run — this Saturday",
                        subtitle: "48 people joined so far",
                        time: "1d ago"
                    )

                    notificationRow(
                        icon: "star.fill",
                        iconColor: .purple,
                        title: "Coach Jason posted a new tip",
                        subtitle: "Check the Seaport community feed",
                        time: "1d ago"
                    )
                }
            }
            .padding(16)
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: – Invitation Card

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

    // MARK: – Suggested Connection Card

    @ViewBuilder
    private func suggestedConnectionCard(_ friend: FriendProfile) -> some View {
        EPCard {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: gradientForFriend(friend),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                    Text(friend.avatarInitials)
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(friend.name)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    HStack(spacing: 4) {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 9))
                        Text(friend.buildingName)
                            .font(.system(.caption, design: .rounded))
                    }
                    .foregroundStyle(EPTheme.softText)
                    if friend.mutualFriends > 0 {
                        Text("\(friend.mutualFriends) mutual friends")
                            .font(.system(.caption2, design: .rounded))
                            .foregroundStyle(EPTheme.accent)
                    }
                }

                Spacer()

                Button {
                    // Quick connect
                } label: {
                    Text("Connect")
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(EPTheme.accent))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: – Notification Row

    @ViewBuilder
    private func notificationRow(icon: String, iconColor: Color, title: String, subtitle: String, time: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                Text(subtitle)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(EPTheme.softText)
            }

            Spacer()

            Text(time)
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(EPTheme.softText)
        }
        .padding(.vertical, 6)
    }

    private func gradientForFriend(_ friend: FriendProfile) -> [Color] {
        let gradients: [[Color]] = [
            [.blue, .purple], [.teal, .blue], [.indigo, .pink],
            [.green, .teal], [.purple, .indigo], [.orange, .pink],
            [.cyan, .blue], [.mint, .green]
        ]
        let index = abs(friend.name.hashValue) % gradients.count
        return gradients[index]
    }
}
