import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // MARK: – Friend Requests (pending)
                if !store.friendRequests.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .font(.system(size: 16))
                                .foregroundStyle(.blue)
                            Text("Friend Requests")
                                .font(.system(.title3, design: .rounded).weight(.semibold))
                            Spacer()
                            Text("\(store.friendRequests.count)")
                                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                .foregroundStyle(EPTheme.softText)
                        }

                        ForEach(store.friendRequests) { request in
                            friendRequestCard(request)
                        }
                    }

                    Divider().overlay(EPTheme.divider)
                }

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

                    Divider().overlay(EPTheme.divider)
                }

                // MARK: – Suggested Connections
                if !store.discoverableFriends.isEmpty {
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
                }

                // MARK: – Activity / Notifications (API-backed)
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.blue)
                        Text("Activity")
                            .font(.system(.title3, design: .rounded).weight(.semibold))
                    }

                    if store.notifications.isEmpty {
                        HStack {
                            Spacer()
                            VStack(spacing: 8) {
                                Image(systemName: "bell.slash")
                                    .font(.system(size: 32))
                                    .foregroundStyle(EPTheme.softText.opacity(0.4))
                                Text("No activity yet")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundStyle(EPTheme.softText)
                            }
                            .padding(.vertical, 24)
                            Spacer()
                        }
                    } else {
                        ForEach(store.notifications) { notif in
                            notificationRow(notif)
                        }
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await store.loadNotifications()
            await store.loadFriendRequests()
        }
        .refreshable {
            await store.loadNotifications()
            await store.loadFriendRequests()
        }
    }

    // MARK: – Friend Request Card

    @ViewBuilder
    private func friendRequestCard(_ request: FriendRequestResponse) -> some View {
        EPCard {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: gradientForName(request.fromName),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)
                        Text(initials(for: request.fromName))
                            .font(.system(.headline, design: .rounded).weight(.bold))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(request.fromName)
                            .font(.system(.body, design: .rounded).weight(.semibold))
                        if let building = request.fromBuildingName, !building.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "building.2.fill")
                                    .font(.system(size: 10))
                                Text(building)
                                    .font(.system(.caption, design: .rounded))
                            }
                            .foregroundStyle(EPTheme.softText)
                        }
                        Text(timeAgo(from: request.createdAt))
                            .font(.system(.caption2, design: .rounded))
                            .foregroundStyle(EPTheme.softText)
                    }

                    Spacer()
                }

                // Accept / Decline buttons
                HStack(spacing: 10) {
                    Button {
                        Task { await store.acceptFriendRequest(request) }
                    } label: {
                        Text("Confirm")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundStyle(.black.opacity(0.85))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(EPTheme.accent)
                            .cornerRadius(10)
                    }

                    Button {
                        Task { await store.declineFriendRequest(request) }
                    } label: {
                        Text("Delete")
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
            }
        }
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

    // MARK: – Notification Row (API-backed)

    @ViewBuilder
    private func notificationRow(_ notif: AppNotificationResponse) -> some View {
        let (icon, iconColor) = iconForNotificationType(notif.type)

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
                Text(notif.title)
                    .font(.system(.subheadline, design: .rounded).weight(notif.isRead ? .regular : .medium))
                if let body = notif.body, !body.isEmpty {
                    Text(body)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(EPTheme.softText)
                }
            }

            Spacer()

            Text(timeAgo(from: notif.createdAt))
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(EPTheme.softText)

            if !notif.isRead {
                Circle()
                    .fill(EPTheme.accent)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 6)
        .opacity(notif.isRead ? 0.7 : 1.0)
    }

    private func iconForNotificationType(_ type: String) -> (String, Color) {
        switch type {
        case "friend_request":
            return ("person.crop.circle.badge.plus", .blue)
        case "friend_accepted":
            return ("person.crop.circle.badge.checkmark", .green)
        default:
            return ("bell.fill", .orange)
        }
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

    private func gradientForName(_ name: String) -> [Color] {
        let gradients: [[Color]] = [
            [.blue, .purple], [.teal, .blue], [.indigo, .pink],
            [.green, .teal], [.purple, .indigo], [.orange, .pink],
            [.cyan, .blue], [.mint, .green]
        ]
        let index = abs(name.hashValue) % gradients.count
        return gradients[index]
    }

    private func initials(for name: String) -> String {
        name.components(separatedBy: " ")
            .prefix(2)
            .compactMap { $0.first }
            .map { String($0) }
            .joined()
            .uppercased()
    }

    private func timeAgo(from date: Date) -> String {
        let seconds = Date().timeIntervalSince(date)
        if seconds < 60 { return "now" }
        else if seconds < 3600 { return "\(Int(seconds / 60))m" }
        else if seconds < 86400 { return "\(Int(seconds / 3600))h" }
        else { return "\(Int(seconds / 86400))d" }
    }
}
