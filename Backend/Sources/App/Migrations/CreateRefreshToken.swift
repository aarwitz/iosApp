// CreateRefreshToken.swift
// EliteProAI Backend – Migrations

import Fluent

struct CreateRefreshToken: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("refresh_tokens")
            .id()
            .field("token", .string, .required)
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("expires_at", .datetime, .required)
            .field("is_revoked", .bool, .required, .custom("DEFAULT false"))
            .field("created_at", .datetime)
            .unique(on: "token")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("refresh_tokens").delete()
    }
}
