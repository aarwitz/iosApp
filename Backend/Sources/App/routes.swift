// routes.swift
// EliteProAI Backend
//
// Top-level route registration.

import Vapor

func routes(_ app: Application) throws {

    // Health check
    app.get("health") { _ in
        ["status": "ok"]
    }

    // API v1 group
    let api = app.grouped("api", "v1")

    // Auth routes (public)
    try api.grouped("auth").register(collection: AuthController())

    // Protected routes (require valid JWT)
    let protected = api.grouped(JWTAuthMiddleware())
    try protected.grouped("users").register(collection: UsersController())
    try protected.grouped("feed").register(collection: FeedController())
    try protected.grouped("conversations").register(collection: ConversationsController())
    try protected.grouped("friends").register(collection: FriendsController())
    try protected.register(collection: SeedController())
}
