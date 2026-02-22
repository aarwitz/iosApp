// CreateFeedPost.swift
// EliteProAI Backend

import Fluent

struct CreateFeedPost: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("feed_posts")
            .id()
            .field("author_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("author_name", .string, .required)
            .field("group_name", .string, .required)
            .field("community_name", .string, .required)
            .field("text", .string, .required)
            .field("image_placeholder", .string)
            .field("created_at", .datetime)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("feed_posts").delete()
    }
}
