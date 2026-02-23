// AddPerUserDeletion.swift
// EliteProAI Backend
//
// Adds per-user soft-delete support for conversations and messages.
// - Conversations: boolean flags on the conversation row.
// - Messages: a separate join table so each user can independently hide messages.

import Fluent

struct AddPerUserDeletion: AsyncMigration {
    func prepare(on database: Database) async throws {
        // Add soft-delete flags to conversations
        try await database.schema("chat_conversations")
            .field("deleted_for_owner", .bool, .required, .sql(.default(false)))
            .field("deleted_for_contact", .bool, .required, .sql(.default(false)))
            .update()

        // Create join table for per-user message deletion
        try await database.schema("user_deleted_messages")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("message_id", .uuid, .required, .references("chat_messages", "id", onDelete: .cascade))
            .unique(on: "user_id", "message_id")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("user_deleted_messages").delete()

        try await database.schema("chat_conversations")
            .deleteField("deleted_for_owner")
            .deleteField("deleted_for_contact")
            .update()
    }
}
