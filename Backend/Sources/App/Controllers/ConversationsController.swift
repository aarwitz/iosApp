// ConversationsController.swift
// EliteProAI Backend
//
// Chat conversation and message endpoints.

import Vapor
import Fluent

struct ConversationsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get(use: index)
        routes.post(use: create)
        routes.group(":conversationID") { convo in
            convo.get("messages", use: messages)
            convo.post("messages", use: sendMessage)
        }
    }

    // MARK: – GET /conversations

    func index(req: Request) async throws -> [ChatConversation.Response] {
        let payload = try req.auth.require(UserJWTPayload.self)
        guard let userId = UUID(uuidString: payload.sub.value) else {
            throw Abort(.unauthorized)
        }

        let conversations = try await ChatConversation.query(on: req.db)
            .filter(\.$user.$id == userId)
            .with(\.$messages)
            .sort(\.$lastMessageTime, .descending)
            .all()

        return try conversations.map { try $0.asResponse() }
    }

    // MARK: – POST /conversations

    struct CreateConversationRequest: Content {
        let contactName: String
        let contactUserId: UUID?      // optional: link to a real user
        let initialMessage: String?   // optional: send a first message
    }

    func create(req: Request) async throws -> ChatConversation.Response {
        let payload = try req.auth.require(UserJWTPayload.self)
        guard let userId = UUID(uuidString: payload.sub.value) else {
            throw Abort(.unauthorized)
        }

        let input = try req.content.decode(CreateConversationRequest.self)
        let msgText = input.initialMessage ?? ""

        // If contactUserId provided, look up their name automatically
        var resolvedContactName = input.contactName
        if let contactId = input.contactUserId,
           resolvedContactName.isEmpty,
           let contactUser = try await User.find(contactId, on: req.db) {
            resolvedContactName = contactUser.name
        }

        let conversation = ChatConversation(
            userID: userId,
            contactName: resolvedContactName,
            contactUserID: input.contactUserId,
            lastMessage: msgText,
            lastMessageTime: Date(),
            unreadCount: 0
        )
        try await conversation.save(on: req.db)

        // Only create the first message if one was provided
        if !msgText.isEmpty {
            let message = ChatMsg(
                conversationID: try conversation.requireID(),
                senderName: "You",
                senderUserID: userId,
                text: msgText,
                isFromUser: true
            )
            try await message.save(on: req.db)
        }

        // Reload with messages
        guard let full = try await ChatConversation.query(on: req.db)
            .filter(\.$id == conversation.requireID())
            .with(\.$messages)
            .first() else {
            throw Abort(.internalServerError)
        }

        return try full.asResponse()
    }

    // MARK: – GET /conversations/:id/messages

    func messages(req: Request) async throws -> [ChatMsg.Response] {
        let payload = try req.auth.require(UserJWTPayload.self)
        guard let conversationID = req.parameters.get("conversationID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid conversation ID.")
        }

        let msgs = try await ChatMsg.query(on: req.db)
            .filter(\.$conversation.$id == conversationID)
            .sort(\.$createdAt, .ascending)
            .all()

        return msgs.map { msg in
            ChatMsg.Response(
                id: msg.id ?? UUID(),
                from: msg.senderName,
                text: msg.text,
                timestamp: msg.createdAt ?? Date(),
                isMe: msg.isFromUser
            )
        }
    }

    // MARK: – POST /conversations/:id/messages

    struct SendMessageRequest: Content {
        let text: String
    }

    func sendMessage(req: Request) async throws -> ChatMsg.Response {
        let payload = try req.auth.require(UserJWTPayload.self)
        guard let userId = UUID(uuidString: payload.sub.value),
              let conversationID = req.parameters.get("conversationID", as: UUID.self) else {
            throw Abort(.badRequest)
        }

        let input = try req.content.decode(SendMessageRequest.self)

        // Verify the conversation belongs to this user
        guard let conversation = try await ChatConversation.find(conversationID, on: req.db),
              conversation.$user.id == userId else {
            throw Abort(.notFound, reason: "Conversation not found.")
        }

        // Save message
        let message = ChatMsg(
            conversationID: conversationID,
            senderName: "You",
            senderUserID: userId,
            text: input.text,
            isFromUser: true
        )
        try await message.save(on: req.db)

        // Update conversation summary
        conversation.lastMessage = input.text
        conversation.lastMessageTime = Date()
        try await conversation.save(on: req.db)

        return ChatMsg.Response(
            id: message.id ?? UUID(),
            from: "You",
            text: input.text,
            timestamp: message.createdAt ?? Date(),
            isMe: true
        )
    }
}
