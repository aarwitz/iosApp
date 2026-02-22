// ChatMsg.swift
// EliteProAI Backend
//
// A single message within a conversation.
// Named "ChatMsg" to avoid collision with iOS ChatMessage model.

import Fluent
import Vapor

final class ChatMsg: Model, @unchecked Sendable {
    static let schema = "chat_messages"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "conversation_id")
    var conversation: ChatConversation

    @Field(key: "sender_name")
    var senderName: String

    @OptionalField(key: "sender_user_id")
    var senderUserID: UUID?

    @Field(key: "text")
    var text: String

    @Field(key: "is_from_user")
    var isFromUser: Bool

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    init() {}

    init(
        id: UUID? = nil,
        conversationID: UUID,
        senderName: String,
        senderUserID: UUID? = nil,
        text: String,
        isFromUser: Bool
    ) {
        self.id = id
        self.$conversation.id = conversationID
        self.senderName = senderName
        self.senderUserID = senderUserID
        self.text = text
        self.isFromUser = isFromUser
    }
}

// MARK: – Response DTO (matches iOS ChatMessage model)

extension ChatMsg {
    struct Response: Content {
        let id: UUID
        let from: String
        let text: String
        let timestamp: Date
        let isMe: Bool
    }
}
