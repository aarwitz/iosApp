// ConversationsController.swift
// EliteProAI Backend
//
// Chat conversation and message endpoints.
// A conversation is shared between two users (user_id and contact_user_id).
// Both sides see the same conversation and messages;
// `isMe` is computed per-request based on who is asking.

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

    // MARK: – Helpers

    /// Extract authenticated user ID from JWT.
    private func authenticatedUserId(_ req: Request) throws -> UUID {
        let payload = try req.auth.require(UserJWTPayload.self)
        guard let userId = UUID(uuidString: payload.sub.value) else {
            throw Abort(.unauthorized)
        }
        return userId
    }

    /// Build a response for a conversation, relative to the requesting user.
    /// If I am the `user_id` → contactName stays as-is.
    /// If I am the `contact_user_id` → flip: show the owner's name as the contact.
    private func responseForConversation(
        _ convo: ChatConversation,
        viewerUserId: UUID,
        ownerName: String? = nil
    ) throws -> ChatConversation.Response {
        let iAmOwner = convo.$user.id == viewerUserId

        let displayContactName: String
        let displayContactUserId: UUID?

        if iAmOwner {
            displayContactName = convo.contactName
            displayContactUserId = convo.contactUserID
        } else {
            // I'm the contact → show the owner as my contact
            displayContactName = ownerName ?? "Unknown"
            displayContactUserId = convo.$user.id
        }

        let messageResponses = (convo.$messages.value ?? []).map { msg in
            ChatMsg.Response(
                id: msg.id ?? UUID(),
                from: msg.senderName,
                text: msg.text,
                timestamp: msg.createdAt ?? Date(),
                isMe: msg.senderUserID == viewerUserId
            )
        }

        return ChatConversation.Response(
            id: try convo.requireID(),
            contactName: displayContactName,
            contactUserId: displayContactUserId,
            lastMessage: convo.lastMessage,
            lastMessageTime: convo.lastMessageTime,
            unreadCount: convo.unreadCount,
            messages: messageResponses.sorted { $0.timestamp < $1.timestamp }
        )
    }

    // MARK: – GET /conversations

    func index(req: Request) async throws -> [ChatConversation.Response] {
        let userId = try authenticatedUserId(req)

        // Conversations I own
        let owned = try await ChatConversation.query(on: req.db)
            .filter(\.$user.$id == userId)
            .with(\.$messages)
            .all()

        // Conversations where I am the contact
        let asContact = try await ChatConversation.query(on: req.db)
            .filter(\.$contactUserID == userId)
            .with(\.$messages)
            .with(\.$user)          // need the owner's name
            .all()

        var results: [ChatConversation.Response] = []

        for convo in owned {
            results.append(try responseForConversation(convo, viewerUserId: userId))
        }
        for convo in asContact {
            results.append(try responseForConversation(convo, viewerUserId: userId, ownerName: convo.user.name))
        }

        results.sort { $0.lastMessageTime > $1.lastMessageTime }
        return results
    }

    // MARK: – POST /conversations

    struct CreateConversationRequest: Content {
        let contactName: String
        let contactUserId: UUID?      // optional: link to a real user
        let initialMessage: String?   // optional: send a first message
    }

    func create(req: Request) async throws -> ChatConversation.Response {
        let userId = try authenticatedUserId(req)
        let input = try req.content.decode(CreateConversationRequest.self)
        let msgText = input.initialMessage ?? ""

        // If contactUserId provided, look up their name automatically
        var resolvedContactName = input.contactName
        if let contactId = input.contactUserId,
           resolvedContactName.isEmpty,
           let contactUser = try await User.find(contactId, on: req.db) {
            resolvedContactName = contactUser.name
        }

        // Check if a conversation already exists between these two users (in either direction)
        if let contactId = input.contactUserId {
            let existing = try await ChatConversation.query(on: req.db)
                .group(.or) { or in
                    or.group(.and) { and in
                        and.filter(\.$user.$id == userId)
                        and.filter(\.$contactUserID == contactId)
                    }
                    or.group(.and) { and in
                        and.filter(\.$user.$id == contactId)
                        and.filter(\.$contactUserID == userId)
                    }
                }
                .with(\.$messages)
                .first()

            if let existing {
                return try responseForConversation(existing, viewerUserId: userId)
            }
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
            let senderUser = try await User.find(userId, on: req.db)
            let message = ChatMsg(
                conversationID: try conversation.requireID(),
                senderName: senderUser?.name ?? "You",
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

        return try responseForConversation(full, viewerUserId: userId)
    }

    // MARK: – GET /conversations/:id/messages

    func messages(req: Request) async throws -> [ChatMsg.Response] {
        let userId = try authenticatedUserId(req)
        guard let conversationID = req.parameters.get("conversationID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid conversation ID.")
        }

        // Verify the user is a participant
        guard let conversation = try await ChatConversation.find(conversationID, on: req.db),
              conversation.$user.id == userId || conversation.contactUserID == userId else {
            throw Abort(.notFound, reason: "Conversation not found.")
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
                isMe: msg.senderUserID == userId
            )
        }
    }

    // MARK: – POST /conversations/:id/messages

    struct SendMessageRequest: Content {
        let text: String
    }

    func sendMessage(req: Request) async throws -> ChatMsg.Response {
        let userId = try authenticatedUserId(req)
        guard let conversationID = req.parameters.get("conversationID", as: UUID.self) else {
            throw Abort(.badRequest)
        }

        let input = try req.content.decode(SendMessageRequest.self)

        // Verify the user is a participant (owner OR contact)
        guard let conversation = try await ChatConversation.find(conversationID, on: req.db),
              conversation.$user.id == userId || conversation.contactUserID == userId else {
            throw Abort(.notFound, reason: "Conversation not found.")
        }

        // Look up sender's actual name
        let senderUser = try await User.find(userId, on: req.db)
        let senderName = senderUser?.name ?? "Unknown"

        // Save message with real sender info
        let message = ChatMsg(
            conversationID: conversationID,
            senderName: senderName,
            senderUserID: userId,
            text: input.text,
            isFromUser: conversation.$user.id == userId   // true if owner sent it
        )
        try await message.save(on: req.db)

        // Update conversation summary
        conversation.lastMessage = input.text
        conversation.lastMessageTime = Date()
        try await conversation.save(on: req.db)

        return ChatMsg.Response(
            id: message.id ?? UUID(),
            from: senderName,
            text: input.text,
            timestamp: message.createdAt ?? Date(),
            isMe: true   // the sender always sees their own message as "me"
        )
    }
}
