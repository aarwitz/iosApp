// AuthTests.swift
// Backend Tests
//
// Integration tests for the auth endpoints.

@testable import App
import XCTVapor
import Fluent

final class AuthTests: XCTestCase {
    var app: Application!

    override func setUp() async throws {
        app = Application(.testing)
        try await configure(app)

        // Use in-memory SQLite for tests (swap Postgres for speed)
        // In production tests, configure a test Postgres DB instead
    }

    override func tearDown() async throws {
        app.shutdown()
    }

    // MARK: – Registration

    func testRegisterCreatesUser() async throws {
        try app.test(.POST, "api/v1/auth/register", beforeRequest: { req in
            try req.content.encode([
                "name": "Test User",
                "email": "test@example.com",
                "password": "SecurePass123!",
                "building_name": "Echelon Seaport",
                "building_owner": "Barkan Management"
            ])
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)

            let tokenResponse = try res.content.decode(AuthController.AuthTokenResponse.self)
            XCTAssertFalse(tokenResponse.accessToken.isEmpty)
            XCTAssertFalse(tokenResponse.refreshToken.isEmpty)
            XCTAssertEqual(tokenResponse.user.name, "Test User")
            XCTAssertEqual(tokenResponse.user.email, "test@example.com")
        })
    }

    func testRegisterRejectsDuplicateEmail() async throws {
        // Register first user
        try app.test(.POST, "api/v1/auth/register", beforeRequest: { req in
            try req.content.encode([
                "name": "User One",
                "email": "duplicate@example.com",
                "password": "SecurePass123!"
            ])
        })

        // Try duplicate
        try app.test(.POST, "api/v1/auth/register", beforeRequest: { req in
            try req.content.encode([
                "name": "User Two",
                "email": "duplicate@example.com",
                "password": "SecurePass456!"
            ])
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .conflict)
        })
    }

    func testRegisterRejectsWeakPassword() async throws {
        try app.test(.POST, "api/v1/auth/register", beforeRequest: { req in
            try req.content.encode([
                "name": "Weak Password User",
                "email": "weak@example.com",
                "password": "short"
            ])
        }, afterResponse: { res in
            XCTAssertNotEqual(res.status, .ok, "Should reject passwords under 8 chars")
        })
    }

    // MARK: – Login

    func testLoginWithValidCredentials() async throws {
        // Register
        try app.test(.POST, "api/v1/auth/register", beforeRequest: { req in
            try req.content.encode([
                "name": "Login Test",
                "email": "login@example.com",
                "password": "SecurePass123!"
            ])
        })

        // Login
        try app.test(.POST, "api/v1/auth/login", beforeRequest: { req in
            try req.content.encode([
                "email": "login@example.com",
                "password": "SecurePass123!"
            ])
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)

            let tokenResponse = try res.content.decode(AuthController.AuthTokenResponse.self)
            XCTAssertFalse(tokenResponse.accessToken.isEmpty)
        })
    }

    func testLoginWithWrongPasswordFails() async throws {
        // Register
        try app.test(.POST, "api/v1/auth/register", beforeRequest: { req in
            try req.content.encode([
                "name": "Wrong Pass",
                "email": "wrongpass@example.com",
                "password": "SecurePass123!"
            ])
        })

        // Login with wrong password
        try app.test(.POST, "api/v1/auth/login", beforeRequest: { req in
            try req.content.encode([
                "email": "wrongpass@example.com",
                "password": "WrongPassword!"
            ])
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    // MARK: – Protected Routes

    func testMeRequiresAuth() async throws {
        try app.test(.GET, "api/v1/auth/me", afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    // MARK: – Health Check

    func testHealthCheck() async throws {
        try app.test(.GET, "health", afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })
    }
}
