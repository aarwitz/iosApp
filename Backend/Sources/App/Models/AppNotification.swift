// AppNotification.swift
// EliteProAI Backend
//
// Push-style notifications stored in the database.
// Types: friendRequest, friendAccepted, general

import Fluent
import Vapor

final class AppNotification: Model, @unchecked Sendable {
    static let schema = "notifications"

    @ID(key: .id)
    var id: UUID?

    /// The user who receives this notification.
    @Parent(key: "user_id")
    var user: User

    /// Type of notification: "friend_request", "friend_accepted", "general"
    @Field(key: "type")
    var type: String

    /// Human-readable title, e.g. "Alex sent you a friend request"
    @Field(key: "title")
    var title: String

    /// Optional subtitle / body text
    @OptionalField(key: "body")
    var body: String?

    /// Optional reference to a related object (e.g. friendship ID)
    @OptionalField(key: "reference_id")
    var referenceID: UUID?

    /// Optional: who triggered this notification
    @OptionalField(key: "from_user_id")
    var fromUserID: UUID?

    /// Whether the user has seen / interacted with this notification.
    @Field(key: "is_read")
    var isRead: Bool

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    init() {}

    init(
        id: UUID? = nil,
        userID: UUID,
        type: String,
        title: String,
        body: String? = nil,
        referenceID: UUID? = nil,
        fromUserID: UUID? = nil,
        isRead: Bool = false
    ) {
        self.id = id
        self.$user.id = userID
        self.type = type
        self.title = title
        self.body = body
        self.referenceID = referenceID
        self.fromUserID = fromUserID
        self.isRead = isRead
    }
}

// MARK: – Response DTO

extension AppNotification {
    struct Response: Content {
        let id: UUID
        let type: String
        let title: String
        let body: String?
        let referenceId: UUID?
        let fromUserId: UUID?
        let isRead: Bool
        let createdAt: Date
    }

    func asResponse() throws -> Response {
        Response(
            id: try requireID(),
            type: type,
            title: title,
            body: body,
            referenceId: referenceID,
            fromUserId: fromUserID,
            isRead: isRead,
            createdAt: createdAt ?? Date()
        )
    }
}
