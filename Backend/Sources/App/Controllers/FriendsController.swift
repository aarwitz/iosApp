// FriendsController.swift
// EliteProAI Backend
//
// Friendship endpoints (social-media-style request flow):
//   GET    /friends                    – list accepted friends
//   GET    /friends/requests           – list pending incoming requests
//   POST   /friends                    – send a friend request (QR scan / manual)
//   POST   /friends/:friendshipId/accept  – accept a pending request
//   POST   /friends/:friendshipId/decline – decline (delete) a pending request
//   DELETE /friends/:userId            – unfriend an accepted friend

import Vapor
import Fluent

struct FriendsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get(use: listFriends)
        routes.get("requests", use: listRequests)
        routes.post(use: sendRequest)
        routes.post(":friendshipId", "accept", use: acceptRequest)
        routes.post(":friendshipId", "decline", use: declineRequest)
        routes.delete(":friendUserId", use: removeFriend)
    }

    // MARK: – GET /friends  (accepted only)

    func listFriends(req: Request) async throws -> [Friendship.FriendResponse] {
        let userId = try authenticatedUserId(req)

        // Outgoing accepted
        let outgoing = try await Friendship.query(on: req.db)
            .filter(\.$user.$id == userId)
            .filter(\.$status == "accepted")
            .with(\.$friend)
            .all()

        // Incoming accepted
        let incoming = try await Friendship.query(on: req.db)
            .filter(\.$friend.$id == userId)
            .filter(\.$status == "accepted")
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

    // MARK: – GET /friends/requests  (pending incoming)

    func listRequests(req: Request) async throws -> [Friendship.FriendRequestResponse] {
        let userId = try authenticatedUserId(req)

        let pending = try await Friendship.query(on: req.db)
            .filter(\.$friend.$id == userId)
            .filter(\.$status == "pending")
            .with(\.$user)
            .sort(\.$createdAt, .descending)
            .all()

        return pending.map { fs in
            Friendship.FriendRequestResponse(
                friendshipId: fs.id ?? UUID(),
                fromUserId: fs.$user.id,
                fromName: fs.user.name,
                fromEmail: fs.user.email,
                fromBuildingName: fs.user.buildingName,
                fromBuildingOwner: fs.user.buildingOwner,
                fromAvatarUrl: fs.user.avatarURL,
                status: fs.status,
                createdAt: fs.createdAt ?? Date()
            )
        }
    }

    // MARK: – POST /friends  (send request)

    struct AddFriendRequest: Content {
        let friendCode: String  // the target user's UUID
    }

    func sendRequest(req: Request) async throws -> Friendship.FriendResponse {
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

        // Create pending friendship
        let friendship = Friendship(userID: userId, friendUserID: friendUserId, status: "pending")
        try await friendship.save(on: req.db)

        // Lookup sender's name
        let senderUser = try await User.find(userId, on: req.db)
        let senderName = senderUser?.name ?? "Someone"

        // Create notification for the recipient
        let notification = AppNotification(
            userID: friendUserId,
            type: "friend_request",
            title: "\(senderName) sent you a friend request",
            body: "Tap to accept or decline.",
            referenceID: try friendship.requireID(),
            fromUserID: userId
        )
        try await notification.save(on: req.db)

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

    // MARK: – POST /friends/:friendshipId/accept

    func acceptRequest(req: Request) async throws -> Friendship.FriendResponse {
        let userId = try authenticatedUserId(req)
        guard let friendshipId = req.parameters.get("friendshipId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid friendship ID.")
        }

        guard let friendship = try await Friendship.query(on: req.db)
            .filter(\.$id == friendshipId)
            .filter(\.$friend.$id == userId)     // I must be the recipient
            .filter(\.$status == "pending")
            .with(\.$user)
            .first() else {
            throw Abort(.notFound, reason: "Pending request not found.")
        }

        friendship.status = "accepted"
        try await friendship.save(on: req.db)

        // Mark related notifications as read
        try await AppNotification.query(on: req.db)
            .filter(\.$referenceID == friendshipId)
            .filter(\.$user.$id == userId)
            .set(\.$isRead, to: true)
            .update()

        // Send confirmation notification back to the requester
        let myUser = try await User.find(userId, on: req.db)
        let myName = myUser?.name ?? "Someone"
        let acceptNotification = AppNotification(
            userID: friendship.$user.id,
            type: "friend_accepted",
            title: "\(myName) accepted your friend request",
            referenceID: friendshipId,
            fromUserID: userId
        )
        try await acceptNotification.save(on: req.db)

        return Friendship.FriendResponse(
            id: friendship.id ?? UUID(),
            userId: friendship.$user.id,
            name: friendship.user.name,
            email: friendship.user.email,
            buildingName: friendship.user.buildingName,
            buildingOwner: friendship.user.buildingOwner,
            avatarUrl: friendship.user.avatarURL
        )
    }

    // MARK: – POST /friends/:friendshipId/decline

    func declineRequest(req: Request) async throws -> HTTPStatus {
        let userId = try authenticatedUserId(req)
        guard let friendshipId = req.parameters.get("friendshipId", as: UUID.self) else {
            throw Abort(.badRequest)
        }

        guard let friendship = try await Friendship.query(on: req.db)
            .filter(\.$id == friendshipId)
            .filter(\.$friend.$id == userId)
            .filter(\.$status == "pending")
            .first() else {
            throw Abort(.notFound, reason: "Pending request not found.")
        }

        try await friendship.delete(on: req.db)

        // Clean up notifications
        try await AppNotification.query(on: req.db)
            .filter(\.$referenceID == friendshipId)
            .delete()

        return .noContent
    }

    // MARK: – DELETE /friends/:friendUserId  (unfriend)

    func removeFriend(req: Request) async throws -> HTTPStatus {
        let userId = try authenticatedUserId(req)
        guard let friendUserId = req.parameters.get("friendUserId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid user ID.")
        }

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
