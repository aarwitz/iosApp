// CreateAppNotification.swift
// EliteProAI Backend

import Fluent

struct CreateAppNotification: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("notifications")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("type", .string, .required)
            .field("title", .string, .required)
            .field("body", .string)
            .field("reference_id", .uuid)
            .field("from_user_id", .uuid, .references("users", "id", onDelete: .setNull))
            .field("is_read", .bool, .required)
            .field("created_at", .datetime)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("notifications").delete()
    }
}
