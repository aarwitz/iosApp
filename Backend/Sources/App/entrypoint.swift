// entrypoint.swift
// EliteProAI Backend
//
// Application entry point.

import Vapor

@main
enum Entrypoint {
    static func main() async throws {
        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)

        let app = try await Application.make(env)

        // Bind to 0.0.0.0 so containers/Railway can reach the server.
        // PORT env var is set by Railway; defaults to 8080 for local dev.
        app.http.server.configuration.hostname = "0.0.0.0"
        app.http.server.configuration.port = Int(Environment.get("PORT") ?? "8080") ?? 8080

        do {
            try await configure(app)
        } catch {
            app.logger.report(error: error)
            try await app.asyncShutdown()
            throw error
        }

        try await app.execute()
        try await app.asyncShutdown()
    }
}
