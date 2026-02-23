// CreateFriendship.swift
// EliteProAI Backend

import Fluent

struct CreateFriendship: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("friendships")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("friend_user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("status", .string, .required)
            .field("created_at", .datetime)
            .unique(on: "user_id", "friend_user_id")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("friendships").delete()
    }
}
