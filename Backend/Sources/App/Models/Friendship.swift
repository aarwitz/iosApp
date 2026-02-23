// Friendship.swift
// EliteProAI Backend
//
// Represents a connection between two users.
// A single row (A → B) means A added B and they are friends.
// Lookups check both directions so the relationship is effectively bidirectional.

import Fluent
import Vapor

final class Friendship: Model, @unchecked Sendable {
    static let schema = "friendships"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "user_id")
    var user: User

    @Parent(key: "friend_user_id")
    var friend: User

    @Field(key: "status")
    var status: String  // "accepted" (pending flow can be added later)

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    init() {}

    init(id: UUID? = nil, userID: UUID, friendUserID: UUID, status: String = "accepted") {
        self.id = id
        self.$user.id = userID
        self.$friend.id = friendUserID
        self.status = status
    }
}

// MARK: – Response DTOs

extension Friendship {
    /// Used when listing accepted friends.
    struct FriendResponse: Content {
        let id: UUID        // friendship row ID
        let userId: UUID    // the friend's user ID (their "friend code")
        let name: String
        let email: String
        let buildingName: String?
        let buildingOwner: String?
        let avatarUrl: String?
    }

    /// Used when listing incoming pending friend requests.
    struct FriendRequestResponse: Content {
        let friendshipId: UUID
        let fromUserId: UUID
        let fromName: String
        let fromEmail: String
        let fromBuildingName: String?
        let fromBuildingOwner: String?
        let fromAvatarUrl: String?
        let status: String
        let createdAt: Date
    }
}
