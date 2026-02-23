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
            convo.delete(use: deleteConversation)
            convo.delete("messages", ":messageID", use: deleteMessage)
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
        ownerName: String? = nil,
        deletedMessageIds: Set<UUID> = []
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

        let messageResponses = (convo.$messages.value ?? []).compactMap { msg -> ChatMsg.Response? in
            guard let msgId = msg.id, !deletedMessageIds.contains(msgId) else { return nil }
            return ChatMsg.Response(
                id: msgId,
                from: msg.senderName,
                text: msg.text,
                timestamp: msg.createdAt ?? Date(),
                isMe: msg.senderUserID == viewerUserId
            )
        }

        let sortedMessages = messageResponses.sorted { $0.timestamp < $1.timestamp }

        // Derive lastMessage preview from the user's visible messages,
        // not the DB column (which may reference a deleted message).
        let visibleLastMessage = sortedMessages.last?.text ?? ""
        let visibleLastTime = sortedMessages.last?.timestamp ?? convo.lastMessageTime

        return ChatConversation.Response(
            id: try convo.requireID(),
            contactName: displayContactName,
            contactUserId: displayContactUserId,
            lastMessage: visibleLastMessage,
            lastMessageTime: visibleLastTime,
            unreadCount: convo.unreadCount,
            messages: sortedMessages
        )
    }

    // MARK: – GET /conversations

    func index(req: Request) async throws -> [ChatConversation.Response] {
        let userId = try authenticatedUserId(req)

        // Conversations I own (not deleted for me)
        let owned = try await ChatConversation.query(on: req.db)
            .filter(\.$user.$id == userId)
            .filter(\.$deletedForOwner == false)
            .with(\.$messages)
            .all()

        // Conversations where I am the contact (not deleted for me)
        let asContact = try await ChatConversation.query(on: req.db)
            .filter(\.$contactUserID == userId)
            .filter(\.$deletedForContact == false)
            .with(\.$messages)
            .with(\.$user)          // need the owner's name
            .all()

        var results: [ChatConversation.Response] = []

        // Load this user's deleted message IDs (for filtering)
        let deletedMsgRows = try await UserDeletedMessage.query(on: req.db)
            .filter(\.$userID == userId)
            .all()
        let deletedMsgIds = Set(deletedMsgRows.map { $0.messageID })

        for convo in owned {
            results.append(try responseForConversation(convo, viewerUserId: userId, deletedMessageIds: deletedMsgIds))
        }
        for convo in asContact {
            results.append(try responseForConversation(convo, viewerUserId: userId, ownerName: convo.user.name, deletedMessageIds: deletedMsgIds))
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
                // Un-delete for the requesting user if they previously deleted it
                let isOwner = existing.$user.id == userId
                if isOwner && existing.deletedForOwner {
                    existing.deletedForOwner = false
                    try await existing.save(on: req.db)
                } else if !isOwner && existing.deletedForContact {
                    existing.deletedForContact = false
                    try await existing.save(on: req.db)
                }
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

        // Filter out messages this user has deleted
        let deletedMsgIds = try await UserDeletedMessage.query(on: req.db)
            .filter(\.$userID == userId)
            .all()
            .map { $0.messageID }
        let deletedSet = Set(deletedMsgIds)

        return msgs.compactMap { msg in
            guard let msgId = msg.id, !deletedSet.contains(msgId) else { return nil }
            return ChatMsg.Response(
                id: msgId,
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

        // Update conversation summary + un-delete for both users so new messages surface
        conversation.lastMessage = input.text
        conversation.lastMessageTime = Date()
        conversation.deletedForOwner = false
        conversation.deletedForContact = false
        try await conversation.save(on: req.db)

        return ChatMsg.Response(
            id: message.id ?? UUID(),
            from: senderName,
            text: input.text,
            timestamp: message.createdAt ?? Date(),
            isMe: true   // the sender always sees their own message as "me"
        )
    }

    // MARK: – DELETE /conversations/:id  (per-user soft delete)

    func deleteConversation(req: Request) async throws -> HTTPStatus {
        let userId = try authenticatedUserId(req)
        guard let conversationID = req.parameters.get("conversationID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid conversation ID.")
        }

        guard let conversation = try await ChatConversation.find(conversationID, on: req.db) else {
            throw Abort(.notFound, reason: "Conversation not found.")
        }

        let isOwner = conversation.$user.id == userId
        let isContact = conversation.contactUserID == userId

        guard isOwner || isContact else {
            throw Abort(.notFound, reason: "Conversation not found.")
        }

        if isOwner {
            conversation.deletedForOwner = true
        }
        if isContact {
            conversation.deletedForContact = true
        }
        try await conversation.save(on: req.db)

        return .noContent
    }

    // MARK: – DELETE /conversations/:id/messages/:messageID  (per-user soft delete)

    func deleteMessage(req: Request) async throws -> HTTPStatus {
        let userId = try authenticatedUserId(req)
        guard let conversationID = req.parameters.get("conversationID", as: UUID.self),
              let messageID = req.parameters.get("messageID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid conversation or message ID.")
        }

        // Verify the user is a participant
        guard let conversation = try await ChatConversation.find(conversationID, on: req.db),
              conversation.$user.id == userId || conversation.contactUserID == userId else {
            throw Abort(.notFound, reason: "Conversation not found.")
        }

        // Verify the message belongs to this conversation
        guard let _ = try await ChatMsg.query(on: req.db)
            .filter(\.$id == messageID)
            .filter(\.$conversation.$id == conversationID)
            .first() else {
            throw Abort(.notFound, reason: "Message not found.")
        }

        // Check if already deleted for this user
        let existing = try await UserDeletedMessage.query(on: req.db)
            .filter(\.$userID == userId)
            .filter(\.$messageID == messageID)
            .first()

        if existing == nil {
            let deletion = UserDeletedMessage(userID: userId, messageID: messageID)
            try await deletion.save(on: req.db)
        }

        return .noContent
    }
}
