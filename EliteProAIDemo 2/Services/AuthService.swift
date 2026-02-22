// AuthService.swift
// EliteProAIDemo
//
// Manages authentication state, login, signup, token refresh, and logout.
// Publishes `authState` so the UI can reactively gate on authentication.

import Foundation
import SwiftUI
import Combine

// MARK: – Auth State

enum AuthState: Equatable {
    case unknown        // App just launched, checking stored tokens
    case unauthenticated
    case authenticated(userId: String)
}

// MARK: – Auth DTOs (Data Transfer Objects)

struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct SignUpRequest: Encodable {
    let name: String
    let email: String
    let password: String
    let buildingName: String
    let buildingOwner: String
}

struct AuthTokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int          // seconds
    let user: AuthUser
}

struct AuthUser: Decodable, Equatable {
    let id: String
    let name: String
    let email: String
    let role: String
    let buildingName: String?
    let buildingOwner: String?
}

struct RefreshTokenRequest: Encodable {
    let refreshToken: String
}

struct ForgotPasswordRequest: Encodable {
    let email: String
}

struct ResetPasswordRequest: Encodable {
    let token: String
    let newPassword: String
}

struct ChangePasswordRequest: Encodable {
    let currentPassword: String
    let newPassword: String
}

struct UpdateProfileRequest: Encodable {
    let name: String?
    let email: String?
    let buildingName: String?
    let buildingOwner: String?
}

// MARK: – AuthService

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published private(set) var authState: AuthState = .unknown
    @Published private(set) var currentUser: AuthUser?
    @Published var errorMessage: String?

    private let api = APIClient.shared
    private let keychain = KeychainManager.shared
    private var refreshTask: Task<Void, Never>?

    private init() {}

    // MARK: – Bootstrap (called at app launch)

    /// Check for a stored session and restore it, or move to unauthenticated.
    func bootstrap() async {
        guard let accessToken = keychain.getAccessToken(),
              !accessToken.isEmpty else {
            authState = .unauthenticated
            return
        }

        // Try to validate the stored token by fetching the current user
        do {
            let user: AuthUser = try await api.request(.get, path: "/auth/me")
            currentUser = user
            keychain.save(key: .userId, value: user.id)
            authState = .authenticated(userId: user.id)
            scheduleTokenRefresh()
        } catch {
            // Token invalid or expired — attempt refresh
            await attemptTokenRefresh()
        }
    }

    // MARK: – Login

    func login(email: String, password: String) async -> Bool {
        errorMessage = nil

        do {
            let response: AuthTokenResponse = try await api.request(
                .post,
                path: "/auth/login",
                body: LoginRequest(email: email, password: password),
                authenticated: false
            )
            handleAuthSuccess(response)
            return true
        } catch let error as APIError {
            errorMessage = error.errorDescription
            return false
        } catch {
            errorMessage = "Login failed. Please try again."
            return false
        }
    }

    // MARK: – Sign Up

    func signUp(name: String, email: String, password: String, buildingName: String = "", buildingOwner: String = "") async -> Bool {
        errorMessage = nil

        do {
            let response: AuthTokenResponse = try await api.request(
                .post,
                path: "/auth/register",
                body: SignUpRequest(
                    name: name,
                    email: email,
                    password: password,
                    buildingName: buildingName,
                    buildingOwner: buildingOwner
                ),
                authenticated: false
            )
            handleAuthSuccess(response)
            return true
        } catch let error as APIError {
            errorMessage = error.errorDescription
            return false
        } catch {
            errorMessage = "Sign-up failed. Please try again."
            return false
        }
    }

    // MARK: – Forgot / Reset Password

    func forgotPassword(email: String) async -> Bool {
        errorMessage = nil
        do {
            try await api.requestVoid(.post, path: "/auth/forgot-password", body: ForgotPasswordRequest(email: email), authenticated: false)
            return true
        } catch let error as APIError {
            errorMessage = error.errorDescription
            return false
        } catch {
            errorMessage = "Could not send reset email."
            return false
        }
    }

    func resetPassword(token: String, newPassword: String) async -> Bool {
        errorMessage = nil
        do {
            try await api.requestVoid(.post, path: "/auth/reset-password", body: ResetPasswordRequest(token: token, newPassword: newPassword), authenticated: false)
            return true
        } catch {
            errorMessage = "Password reset failed."
            return false
        }
    }

    // MARK: – Change Password (authenticated)

    func changePassword(current: String, new: String) async -> Bool {
        errorMessage = nil
        do {
            try await api.requestVoid(.post, path: "/auth/change-password", body: ChangePasswordRequest(currentPassword: current, newPassword: new))
            return true
        } catch let error as APIError {
            errorMessage = error.errorDescription
            return false
        } catch {
            errorMessage = "Password change failed."
            return false
        }
    }

    // MARK: – Update Profile

    func updateProfile(_ request: UpdateProfileRequest) async -> Bool {
        errorMessage = nil
        do {
            let user: AuthUser = try await api.request(.patch, path: "/users/me", body: request)
            currentUser = user
            return true
        } catch let error as APIError {
            errorMessage = error.errorDescription
            return false
        } catch {
            errorMessage = "Profile update failed."
            return false
        }
    }

    // MARK: – Logout

    func logout() {
        refreshTask?.cancel()
        refreshTask = nil

        // Tell the server to invalidate the refresh token (fire-and-forget)
        if let refreshToken = keychain.getRefreshToken() {
            Task {
                try? await api.requestVoid(.post, path: "/auth/logout", body: RefreshTokenRequest(refreshToken: refreshToken))
            }
        }

        keychain.clearAll()
        currentUser = nil
        authState = .unauthenticated
    }

    // MARK: – Token Refresh

    private func attemptTokenRefresh() async {
        guard let refreshToken = keychain.getRefreshToken() else {
            authState = .unauthenticated
            return
        }

        do {
            let response: AuthTokenResponse = try await api.request(
                .post,
                path: "/auth/refresh",
                body: RefreshTokenRequest(refreshToken: refreshToken),
                authenticated: false
            )
            handleAuthSuccess(response)
        } catch {
            // Refresh failed — force re-login
            keychain.clearAll()
            authState = .unauthenticated
        }
    }

    private func scheduleTokenRefresh() {
        refreshTask?.cancel()

        // Refresh 60 seconds before expiry (default 15 min tokens = refresh at 14 min)
        let interval: TimeInterval = 14 * 60 // adjust based on actual token TTL
        refreshTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await self?.attemptTokenRefresh()
        }
    }

    // MARK: – Helpers

    private func handleAuthSuccess(_ response: AuthTokenResponse) {
        keychain.saveTokens(access: response.accessToken, refresh: response.refreshToken)
        keychain.save(key: .userId, value: response.user.id)
        keychain.save(key: .userEmail, value: response.user.email)
        currentUser = response.user
        authState = .authenticated(userId: response.user.id)
        scheduleTokenRefresh()
    }
}
