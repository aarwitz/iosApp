// FeedController.swift
// EliteProAI Backend
//
// Community feed endpoints — browse and create posts.

import Vapor
import Fluent

struct FeedController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get(use: index)
        routes.post(use: create)
    }

    // MARK: – GET /feed?community=Echelon&page=1&per=20

    func index(req: Request) async throws -> [FeedPost.Response] {
        let payload = try req.auth.require(UserJWTPayload.self)

        var query = FeedPost.query(on: req.db)
            .sort(\.$createdAt, .descending)

        // Optional community filter
        if let community = req.query[String.self, at: "community"], !community.isEmpty {
            query = query.filter(\.$communityName == community)
        }

        // Pagination
        let page = req.query[Int.self, at: "page"] ?? 1
        let per = min(req.query[Int.self, at: "per"] ?? 50, 100)
        let posts = try await query
            .range((page - 1) * per ..< page * per)
            .all()

        return try posts.map { try $0.asResponse() }
    }

    // MARK: – POST /feed

    struct CreatePostRequest: Content {
        let groupName: String
        let communityName: String
        let text: String
        let imagePlaceholder: String?
    }

    func create(req: Request) async throws -> FeedPost.Response {
        let payload = try req.auth.require(UserJWTPayload.self)
        let input = try req.content.decode(CreatePostRequest.self)

        guard let userId = UUID(uuidString: payload.sub.value),
              let user = try await User.find(userId, on: req.db) else {
            throw Abort(.notFound, reason: "User not found.")
        }

        let post = FeedPost(
            authorID: userId,
            authorName: user.name,
            groupName: input.groupName,
            communityName: input.communityName,
            text: input.text,
            imagePlaceholder: input.imagePlaceholder
        )
        try await post.save(on: req.db)
        return try post.asResponse()
    }
}
