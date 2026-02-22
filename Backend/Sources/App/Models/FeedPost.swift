// FeedPost.swift
// EliteProAI Backend
//
// A post in a community feed group.

import Fluent
import Vapor

final class FeedPost: Model, @unchecked Sendable {
    static let schema = "feed_posts"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "author_id")
    var author: User

    @Field(key: "author_name")
    var authorName: String

    @Field(key: "group_name")
    var groupName: String

    @Field(key: "community_name")
    var communityName: String

    @Field(key: "text")
    var text: String

    @OptionalField(key: "image_placeholder")
    var imagePlaceholder: String?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    init() {}

    init(
        id: UUID? = nil,
        authorID: UUID,
        authorName: String,
        groupName: String,
        communityName: String,
        text: String,
        imagePlaceholder: String? = nil
    ) {
        self.id = id
        self.$author.id = authorID
        self.authorName = authorName
        self.groupName = groupName
        self.communityName = communityName
        self.text = text
        self.imagePlaceholder = imagePlaceholder
    }
}

// MARK: – Response DTO (matches iOS Post model)

extension FeedPost {
    struct Response: Content {
        let id: UUID
        let groupName: String
        let communityName: String
        let author: String
        let text: String
        let timestamp: Date
        let imagePlaceholder: String?
    }

    func asResponse() throws -> Response {
        Response(
            id: try requireID(),
            groupName: groupName,
            communityName: communityName,
            author: authorName,
            text: text,
            timestamp: createdAt ?? Date(),
            imagePlaceholder: imagePlaceholder
        )
    }
}
