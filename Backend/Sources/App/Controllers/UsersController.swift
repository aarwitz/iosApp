// UsersController.swift
// EliteProAI Backend
//
// Protected user endpoints — profile updates, avatar upload, etc.

import Vapor
import Fluent

struct UsersController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get("me", use: getMe)
        routes.patch("me", use: updateMe)
        routes.delete("me", use: deleteMe)
        routes.get("search", use: searchUsers)
    }

    // MARK: – Get current user

    func getMe(req: Request) async throws -> User.Public {
        let user = try await authenticatedUser(req)
        return try user.asPublic()
    }

    // MARK: – Update profile

    struct UpdateRequest: Content {
        let name: String?
        let email: String?
        let buildingName: String?
        let buildingOwner: String?
    }

    func updateMe(req: Request) async throws -> User.Public {
        let user = try await authenticatedUser(req)
        let input = try req.content.decode(UpdateRequest.self)

        if let name = input.name, !name.isEmpty {
            user.name = name
        }
        if let email = input.email, !email.isEmpty {
            // Check uniqueness
            if email.lowercased() != user.email {
                let existing = try await User.query(on: req.db)
                    .filter(\.$email == email.lowercased())
                    .first()
                guard existing == nil else {
                    throw Abort(.conflict, reason: "Email already in use.")
                }
                user.email = email.lowercased()
            }
        }
        if let buildingName = input.buildingName {
            user.buildingName = buildingName
        }
        if let buildingOwner = input.buildingOwner {
            user.buildingOwner = buildingOwner
        }

        try await user.save(on: req.db)
        return try user.asPublic()
    }

    // MARK: – Delete account

    func deleteMe(req: Request) async throws -> HTTPStatus {
        let user = try await authenticatedUser(req)

        // Revoke all refresh tokens
        try await RefreshToken.query(on: req.db)
            .filter(\.$user.$id == user.requireID())
            .set(\.$isRevoked, to: true)
            .update()

        try await user.delete(on: req.db)
        return .noContent
    }

    // MARK: – Search users (for friend discovery)

    func searchUsers(req: Request) async throws -> [User.Public] {
        let payload = try req.auth.require(UserJWTPayload.self)
        guard let userId = UUID(uuidString: payload.sub.value) else {
            throw Abort(.unauthorized)
        }

        let q = try? req.query.get(String.self, at: "q")

        // Collect current friend IDs (both directions) to exclude them
        let outgoingFriendIds = try await Friendship.query(on: req.db)
            .filter(\.$user.$id == userId)
            .all(\.$friend.$id)
        let incomingFriendIds = try await Friendship.query(on: req.db)
            .filter(\.$friend.$id == userId)
            .all(\.$user.$id)
        let friendIds = Set(outgoingFriendIds + incomingFriendIds)

        var usersQuery = User.query(on: req.db)
            .filter(\.$id != userId)

        if let q, !q.isEmpty {
            usersQuery = usersQuery.group(.or) { g in
                g.filter(\.$name ~~ q)
                g.filter(\.$email ~~ q)
            }
        }

        let users = try await usersQuery.limit(30).all()

        return try users
            .filter { user in
                guard let uid = user.id else { return false }
                return !friendIds.contains(uid)
            }
            .map { try $0.asPublic() }
    }

    // MARK: – Helper

    private func authenticatedUser(_ req: Request) async throws -> User {
        let payload = try req.auth.require(UserJWTPayload.self)
        guard let userId = UUID(uuidString: payload.sub.value),
              let user = try await User.find(userId, on: req.db)
        else {
            throw Abort(.notFound, reason: "User not found.")
        }
        return user
    }
}
