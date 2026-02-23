// configure.swift
// EliteProAI Backend
//
// Application configuration: database, middleware, migrations, routes.

import Vapor
import Fluent
import FluentPostgresDriver
import JWT

func configure(_ app: Application) async throws {

    // MARK: – JSON Encoding (match iOS APIClient: snake_case + ISO 8601)

    let jsonEncoder = JSONEncoder()
    jsonEncoder.keyEncodingStrategy = .convertToSnakeCase
    jsonEncoder.dateEncodingStrategy = .iso8601
    let jsonDecoder = JSONDecoder()
    jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
    jsonDecoder.dateDecodingStrategy = .iso8601
    ContentConfiguration.global.use(encoder: jsonEncoder, for: .json)
    ContentConfiguration.global.use(decoder: jsonDecoder, for: .json)

    // MARK: – Database (Postgres)
    //
    // Supports two modes:
    //   1. DATABASE_URL  — a full connection string (Railway, Heroku, Render, etc.)
    //      Append ?sslmode=require for cloud Postgres, e.g.:
    //      postgres://user:pass@host:5432/db?sslmode=require
    //   2. Separate env vars — DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME (local dev)

    if let databaseURL = Environment.get("DATABASE_URL") {
        // Railway / Render / Heroku — parse URL components manually.
        // Railway private networking (postgres.railway.internal) uses a
        // self-signed cert that cannot be verified, so we disable TLS
        // for the internal connection (it's already isolated/trusted).
        guard let url = URL(string: databaseURL),
              let host = url.host,
              let user = url.user,
              let password = url.password else {
            throw Abort(.internalServerError, reason: "Invalid DATABASE_URL")
        }
        let port = url.port ?? 5432
        let database = String(url.path.drop(while: { $0 == "/" }))

        let pgConfig = SQLPostgresConfiguration(
            hostname: host,
            port: port,
            username: user,
            password: password,
            database: database.isEmpty ? "railway" : database,
            tls: .disable
        )
        app.databases.use(.postgres(configuration: pgConfig), as: .psql)
    } else {
        // Local development — individual env vars, no TLS
        let dbHost = Environment.get("DB_HOST") ?? "localhost"
        let dbPort = Environment.get("DB_PORT").flatMap(Int.init) ?? 5432
        let dbUser = Environment.get("DB_USER") ?? "eliteproai"
        let dbPass = Environment.get("DB_PASSWORD") ?? "password"
        let dbName = Environment.get("DB_NAME") ?? "eliteproai_dev"

        let pgConfig = SQLPostgresConfiguration(
            hostname: dbHost,
            port: dbPort,
            username: dbUser,
            password: dbPass,
            database: dbName,
            tls: .disable
        )
        app.databases.use(.postgres(configuration: pgConfig), as: .psql)
    }

    // MARK: – JWT

    let jwtSecret = Environment.get("JWT_SECRET") ?? "dev-secret-change-in-production"
    app.jwt.signers.use(.hs256(key: jwtSecret))

    // MARK: – Middleware

    app.middleware.use(CORSMiddleware(configuration: .init(
        allowedOrigin: .all,
        allowedMethods: [.GET, .POST, .PUT, .PATCH, .DELETE, .OPTIONS],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith]
    )))
    app.middleware.use(ErrorMiddleware.default(environment: app.environment))

    // MARK: – Migrations

    app.migrations.add(CreateUser())
    app.migrations.add(CreateRefreshToken())
    app.migrations.add(CreateFeedPost())
    app.migrations.add(CreateChatConversation())
    app.migrations.add(CreateChatMessage())
    app.migrations.add(CreateFriendship())
    app.migrations.add(CreateAppNotification())
    app.migrations.add(AddPerUserDeletion())
    try await app.autoMigrate()

    // MARK: – Routes

    try routes(app)
}
