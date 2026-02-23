// NotificationsController.swift
// EliteProAI Backend
//
// Notification endpoints:
//   GET  /notifications              – list my notifications (newest first)
//   POST /notifications/:id/read     – mark a single notification as read
//   POST /notifications/read-all     – mark all notifications as read

import Vapor
import Fluent

struct NotificationsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get(use: index)
        routes.post("read-all", use: readAll)
        routes.post(":notificationId", "read", use: markRead)
    }

    // MARK: – GET /notifications

    func index(req: Request) async throws -> [AppNotification.Response] {
        let userId = try authenticatedUserId(req)

        let notifications = try await AppNotification.query(on: req.db)
            .filter(\.$user.$id == userId)
            .sort(\.$createdAt, .descending)
            .all()

        return try notifications.map { try $0.asResponse() }
    }

    // MARK: – POST /notifications/:id/read

    func markRead(req: Request) async throws -> AppNotification.Response {
        let userId = try authenticatedUserId(req)
        guard let notificationId = req.parameters.get("notificationId", as: UUID.self) else {
            throw Abort(.badRequest)
        }

        guard let notification = try await AppNotification.query(on: req.db)
            .filter(\.$id == notificationId)
            .filter(\.$user.$id == userId)
            .first() else {
            throw Abort(.notFound, reason: "Notification not found.")
        }

        notification.isRead = true
        try await notification.save(on: req.db)
        return try notification.asResponse()
    }

    // MARK: – POST /notifications/read-all

    func readAll(req: Request) async throws -> HTTPStatus {
        let userId = try authenticatedUserId(req)

        try await AppNotification.query(on: req.db)
            .filter(\.$user.$id == userId)
            .filter(\.$isRead == false)
            .set(\.$isRead, to: true)
            .update()

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
