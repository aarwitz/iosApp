// UserDeletedMessage.swift
// EliteProAI Backend
//
// Join table that tracks which messages a user has deleted from their view.
// The underlying message is NOT removed — only hidden for this user.

import Fluent
import Vapor

final class UserDeletedMessage: Model, @unchecked Sendable {
    static let schema = "user_deleted_messages"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "user_id")
    var userID: UUID

    @Field(key: "message_id")
    var messageID: UUID

    init() {}

    init(id: UUID? = nil, userID: UUID, messageID: UUID) {
        self.id = id
        self.userID = userID
        self.messageID = messageID
    }
}
