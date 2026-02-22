// AuthController.swift
// EliteProAI Backend
//
// Handles registration, login, token refresh, logout, and password reset.

import Vapor
import Fluent
import JWT

struct AuthController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.post("register", use: register)
        routes.post("login", use: login)
        routes.post("refresh", use: refresh)
        routes.post("logout", use: logout)
        routes.post("forgot-password", use: forgotPassword)
        routes.post("reset-password", use: resetPassword)

        // Protected
        let protected = routes.grouped(JWTAuthMiddleware())
        protected.get("me", use: me)
        protected.post("change-password", use: changePassword)
    }

    // MARK: – Register

    struct RegisterRequest: Content, Validatable {
        let name: String
        let email: String
        let password: String
        let buildingName: String?
        let buildingOwner: String?

        static func validations(_ v: inout Validations) {
            v.add("name", as: String.self, is: !.empty)
            v.add("email", as: String.self, is: .email)
            v.add("password", as: String.self, is: .count(8...))
        }
    }

    func register(req: Request) async throws -> AuthTokenResponse {
        try RegisterRequest.validate(content: req)
        let input = try req.content.decode(RegisterRequest.self)

        // Check unique email
        let existing = try await User.query(on: req.db)
            .filter(\.$email == input.email.lowercased())
            .first()
        guard existing == nil else {
            throw Abort(.conflict, reason: "An account with this email already exists.")
        }

        let user = User(
            name: input.name,
            email: input.email.lowercased(),
            passwordHash: try Bcrypt.hash(input.password),
            buildingName: input.buildingName,
            buildingOwner: input.buildingOwner
        )
        try await user.save(on: req.db)

        return try await generateTokenResponse(for: user, on: req)
    }

    // MARK: – Login

    struct LoginRequest: Content {
        let email: String
        let password: String
    }

    func login(req: Request) async throws -> AuthTokenResponse {
        let input = try req.content.decode(LoginRequest.self)

        guard let user = try await User.query(on: req.db)
            .filter(\.$email == input.email.lowercased())
            .first()
        else {
            throw Abort(.unauthorized, reason: "Invalid email or password.")
        }

        guard try user.verify(password: input.password) else {
            throw Abort(.unauthorized, reason: "Invalid email or password.")
        }

        return try await generateTokenResponse(for: user, on: req)
    }

    // MARK: – Refresh

    struct RefreshRequest: Content {
        let refreshToken: String
    }

    func refresh(req: Request) async throws -> AuthTokenResponse {
        let input = try req.content.decode(RefreshRequest.self)

        guard let storedToken = try await RefreshToken.query(on: req.db)
            .filter(\.$token == input.refreshToken)
            .with(\.$user)
            .first()
        else {
            throw Abort(.unauthorized, reason: "Invalid refresh token.")
        }

        guard !storedToken.isRevoked, storedToken.expiresAt > Date() else {
            throw Abort(.unauthorized, reason: "Refresh token expired or revoked.")
        }

        // Revoke old token (token rotation)
        storedToken.isRevoked = true
        try await storedToken.save(on: req.db)

        return try await generateTokenResponse(for: storedToken.user, on: req)
    }

    // MARK: – Logout

    func logout(req: Request) async throws -> HTTPStatus {
        let input = try req.content.decode(RefreshRequest.self)

        if let storedToken = try await RefreshToken.query(on: req.db)
            .filter(\.$token == input.refreshToken)
            .first()
        {
            storedToken.isRevoked = true
            try await storedToken.save(on: req.db)
        }

        return .noContent
    }

    // MARK: – Me

    func me(req: Request) async throws -> User.Public {
        let payload = try req.auth.require(UserJWTPayload.self)
        guard let userId = UUID(uuidString: payload.sub.value),
              let user = try await User.find(userId, on: req.db)
        else {
            throw Abort(.notFound)
        }
        return try user.asPublic()
    }

    // MARK: – Change Password

    struct ChangePasswordRequest: Content {
        let currentPassword: String
        let newPassword: String
    }

    func changePassword(req: Request) async throws -> HTTPStatus {
        let payload = try req.auth.require(UserJWTPayload.self)
        let input = try req.content.decode(ChangePasswordRequest.self)

        guard let userId = UUID(uuidString: payload.sub.value),
              let user = try await User.find(userId, on: req.db)
        else {
            throw Abort(.notFound)
        }

        guard try user.verify(password: input.currentPassword) else {
            throw Abort(.unauthorized, reason: "Current password is incorrect.")
        }

        user.passwordHash = try Bcrypt.hash(input.newPassword)
        try await user.save(on: req.db)

        return .ok
    }

    // MARK: – Forgot Password (stub — integrate email service)

    struct ForgotPasswordRequest: Content {
        let email: String
    }

    func forgotPassword(req: Request) async throws -> HTTPStatus {
        let input = try req.content.decode(ForgotPasswordRequest.self)

        // Look up user (don't reveal whether email exists)
        if let _ = try await User.query(on: req.db)
            .filter(\.$email == input.email.lowercased())
            .first()
        {
            // TODO: Generate reset token, send email via SendGrid/SES
            req.logger.info("Password reset requested for \(input.email)")
        }

        return .ok // Always return OK to prevent email enumeration
    }

    // MARK: – Reset Password (stub)

    struct ResetPasswordRequest: Content {
        let token: String
        let newPassword: String
    }

    func resetPassword(req: Request) async throws -> HTTPStatus {
        // TODO: Validate reset token, update password
        throw Abort(.notImplemented, reason: "Password reset via token not yet implemented.")
    }

    // MARK: – Token Generation Helper

    struct AuthTokenResponse: Content {
        let accessToken: String
        let refreshToken: String
        let expiresIn: Int
        let user: User.Public
    }

    private func generateTokenResponse(for user: User, on req: Request) async throws -> AuthTokenResponse {
        let userId = try user.requireID()

        // Generate JWT access token (15 min)
        let payload = UserJWTPayload(userId: userId, role: user.role)
        let accessToken = try req.jwt.sign(payload)

        // Generate opaque refresh token (30 days)
        let refreshString = [UInt8].random(count: 32).base64
        let refreshToken = RefreshToken(
            token: refreshString,
            userID: userId,
            expiresAt: Date().addingTimeInterval(30 * 24 * 60 * 60)
        )
        try await refreshToken.save(on: req.db)

        return AuthTokenResponse(
            accessToken: accessToken,
            refreshToken: refreshString,
            expiresIn: 900,
            user: try user.asPublic()
        )
    }
}
