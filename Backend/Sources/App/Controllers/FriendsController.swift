// FriendsController.swift
// EliteProAI Backend
//
// Friendship endpoints:
//   GET  /friends                    – list my accepted friends
//   POST /friends                    – add a friend by their user UUID ("friend code")
//   DELETE /friends/:userId          – unfriend

import Vapor
import Fluent

struct FriendsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get(use: listFriends)
        routes.post(use: addFriend)
        routes.delete(":friendUserId", use: removeFriend)
    }

    // MARK: – GET /friends

    func listFriends(req: Request) async throws -> [Friendship.FriendResponse] {
        let userId = try authenticatedUserId(req)

        // Friendships where I am the requester
        let outgoing = try await Friendship.query(on: req.db)
            .filter(\.$user.$id == userId)
            .with(\.$friend)
            .all()

        // Friendships where I am the recipient
        let incoming = try await Friendship.query(on: req.db)
            .filter(\.$friend.$id == userId)
            .with(\.$user)
            .all()

        let fromOutgoing: [Friendship.FriendResponse] = outgoing.map { fs in
            Friendship.FriendResponse(
                id: fs.id ?? UUID(),
                userId: fs.$friend.id,
                name: fs.friend.name,
                email: fs.friend.email,
                buildingName: fs.friend.buildingName,
                buildingOwner: fs.friend.buildingOwner,
                avatarUrl: fs.friend.avatarURL
            )
        }

        let fromIncoming: [Friendship.FriendResponse] = incoming.map { fs in
            Friendship.FriendResponse(
                id: fs.id ?? UUID(),
                userId: fs.$user.id,
                name: fs.user.name,
                email: fs.user.email,
                buildingName: fs.user.buildingName,
                buildingOwner: fs.user.buildingOwner,
                avatarUrl: fs.user.avatarURL
            )
        }

        return fromOutgoing + fromIncoming
    }

    // MARK: – POST /friends

    struct AddFriendRequest: Content {
        let friendCode: String  // the friend's user UUID
    }

    func addFriend(req: Request) async throws -> Friendship.FriendResponse {
        let userId = try authenticatedUserId(req)
        let input = try req.content.decode(AddFriendRequest.self)

        guard let friendUserId = UUID(uuidString: input.friendCode) else {
            throw Abort(.badRequest, reason: "Invalid friend code.")
        }

        guard friendUserId != userId else {
            throw Abort(.badRequest, reason: "You cannot add yourself as a friend.")
        }

        guard let friendUser = try await User.find(friendUserId, on: req.db) else {
            throw Abort(.notFound, reason: "User not found.")
        }

        // Check if friendship already exists in either direction
        let existing = try await Friendship.query(on: req.db)
            .group(.or) { g in
                g.group(.and) { inner in
                    inner.filter(\.$user.$id == userId)
                    inner.filter(\.$friend.$id == friendUserId)
                }
                g.group(.and) { inner in
                    inner.filter(\.$user.$id == friendUserId)
                    inner.filter(\.$friend.$id == userId)
                }
            }
            .first()

        if let existing {
            // Already friends – return the existing record
            return Friendship.FriendResponse(
                id: existing.id ?? UUID(),
                userId: friendUserId,
                name: friendUser.name,
                email: friendUser.email,
                buildingName: friendUser.buildingName,
                buildingOwner: friendUser.buildingOwner,
                avatarUrl: friendUser.avatarURL
            )
        }

        let friendship = Friendship(userID: userId, friendUserID: friendUserId)
        try await friendship.save(on: req.db)

        return Friendship.FriendResponse(
            id: try friendship.requireID(),
            userId: friendUserId,
            name: friendUser.name,
            email: friendUser.email,
            buildingName: friendUser.buildingName,
            buildingOwner: friendUser.buildingOwner,
            avatarUrl: friendUser.avatarURL
        )
    }

    // MARK: – DELETE /friends/:friendUserId

    func removeFriend(req: Request) async throws -> HTTPStatus {
        let userId = try authenticatedUserId(req)
        guard let friendUserId = req.parameters.get("friendUserId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid user ID.")
        }

        // Delete both directions so the relationship is fully removed
        try await Friendship.query(on: req.db)
            .filter(\.$user.$id == userId)
            .filter(\.$friend.$id == friendUserId)
            .delete()

        try await Friendship.query(on: req.db)
            .filter(\.$user.$id == friendUserId)
            .filter(\.$friend.$id == userId)
            .delete()

        return .noContent
    }

    // MARK: – Helper

    private func authenticatedUserId(_ req: Request) throws -> UUID {
        let payload = try req.auth.require(UserJWTPayload.self)
        guard let userId = UUID(uuidString: payload.sub.value) else {
            throw Abort(.unauthorized)
        }
        return userId
    }
}
