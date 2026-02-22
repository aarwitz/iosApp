// ChatConversation.swift
// EliteProAI Backend
//
// A conversation between two users.

import Fluent
import Vapor

final class ChatConversation: Model, @unchecked Sendable {
    static let schema = "chat_conversations"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "user_id")
    var user: User

    @Field(key: "contact_name")
    var contactName: String

    @Field(key: "contact_user_id")
    var contactUserID: UUID?

    @Field(key: "last_message")
    var lastMessage: String

    @Field(key: "last_message_time")
    var lastMessageTime: Date

    @Field(key: "unread_count")
    var unreadCount: Int

    @Children(for: \.$conversation)
    var messages: [ChatMsg]

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    init() {}

    init(
        id: UUID? = nil,
        userID: UUID,
        contactName: String,
        contactUserID: UUID? = nil,
        lastMessage: String = "",
        lastMessageTime: Date = Date(),
        unreadCount: Int = 0
    ) {
        self.id = id
        self.$user.id = userID
        self.contactName = contactName
        self.contactUserID = contactUserID
        self.lastMessage = lastMessage
        self.lastMessageTime = lastMessageTime
        self.unreadCount = unreadCount
    }
}

// MARK: – Response DTO (matches iOS Conversation model)

extension ChatConversation {
    struct Response: Content {
        let id: UUID
        let contactName: String
        let lastMessage: String
        let lastMessageTime: Date
        let unreadCount: Int
        let messages: [ChatMsg.Response]
    }

    func asResponse() throws -> Response {
        let messageResponses = (self.$messages.value ?? []).map { msg in
            ChatMsg.Response(
                id: msg.id ?? UUID(),
                from: msg.senderName,
                text: msg.text,
                timestamp: msg.createdAt ?? Date(),
                isMe: msg.isFromUser
            )
        }

        return Response(
            id: try requireID(),
            contactName: contactName,
            lastMessage: lastMessage,
            lastMessageTime: lastMessageTime,
            unreadCount: unreadCount,
            messages: messageResponses.sorted { $0.timestamp < $1.timestamp }
        )
    }
}
