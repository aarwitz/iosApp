// JWTAuthMiddleware.swift
// EliteProAI Backend
//
// Middleware that validates the JWT Bearer token on protected routes.

import Vapor
import JWT

struct JWTAuthMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        // Extract Bearer token
        guard let token = request.headers.bearerAuthorization?.token else {
            throw Abort(.unauthorized, reason: "Missing authorization token.")
        }

        // Verify and decode JWT
        let payload: UserJWTPayload
        do {
            payload = try request.jwt.verify(token, as: UserJWTPayload.self)
        } catch {
            throw Abort(.unauthorized, reason: "Invalid or expired token.")
        }

        // Attach to request auth so controllers can access it
        request.auth.login(payload)

        return try await next.respond(to: request)
    }
}

// Make UserJWTPayload conform to Authenticatable so we can use req.auth
extension UserJWTPayload: Authenticatable {}
