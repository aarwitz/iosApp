// CreateChatMessage.swift
// EliteProAI Backend

import Fluent

struct CreateChatMessage: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("chat_messages")
            .id()
            .field("conversation_id", .uuid, .required, .references("chat_conversations", "id", onDelete: .cascade))
            .field("sender_name", .string, .required)
            .field("sender_user_id", .uuid)
            .field("text", .string, .required)
            .field("is_from_user", .bool, .required)
            .field("created_at", .datetime)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("chat_messages").delete()
    }
}
