// CreateChatConversation.swift
// EliteProAI Backend

import Fluent

struct CreateChatConversation: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("chat_conversations")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("contact_name", .string, .required)
            .field("contact_user_id", .uuid)
            .field("last_message", .string, .required)
            .field("last_message_time", .datetime, .required)
            .field("unread_count", .int, .required, .sql(.default(0)))
            .field("created_at", .datetime)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("chat_conversations").delete()
    }
}
