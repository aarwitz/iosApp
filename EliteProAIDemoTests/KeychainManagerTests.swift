// KeychainManagerTests.swift
// EliteProAIDemoTests
//
// Unit tests for secure credential storage.

import XCTest
@testable import EliteProAIDemo

final class KeychainManagerTests: XCTestCase {
    private let keychain = KeychainManager.shared

    override func tearDown() {
        super.tearDown()
        keychain.clearAll()
    }

    // MARK: – Basic CRUD

    func testSaveAndRetrieve() {
        let result = keychain.save(key: .accessToken, value: "test-token-123")
        XCTAssertTrue(result, "Save should succeed")

        let retrieved = keychain.get(key: .accessToken)
        XCTAssertEqual(retrieved, "test-token-123")
    }

    func testDeleteRemovesValue() {
        keychain.save(key: .accessToken, value: "to-be-deleted")
        keychain.delete(key: .accessToken)

        let retrieved = keychain.get(key: .accessToken)
        XCTAssertNil(retrieved, "Value should be nil after deletion")
    }

    func testUpsertOverwritesExisting() {
        keychain.save(key: .refreshToken, value: "old-token")
        keychain.save(key: .refreshToken, value: "new-token")

        let retrieved = keychain.get(key: .refreshToken)
        XCTAssertEqual(retrieved, "new-token")
    }

    func testClearAllRemovesEverything() {
        keychain.save(key: .accessToken, value: "a")
        keychain.save(key: .refreshToken, value: "b")
        keychain.save(key: .userId, value: "c")

        keychain.clearAll()

        XCTAssertNil(keychain.get(key: .accessToken))
        XCTAssertNil(keychain.get(key: .refreshToken))
        XCTAssertNil(keychain.get(key: .userId))
    }

    // MARK: – Token Convenience

    func testSaveTokens() {
        keychain.saveTokens(access: "access-123", refresh: "refresh-456")

        XCTAssertEqual(keychain.getAccessToken(), "access-123")
        XCTAssertEqual(keychain.getRefreshToken(), "refresh-456")
    }

    func testClearTokens() {
        keychain.saveTokens(access: "a", refresh: "b")
        keychain.clearTokens()

        XCTAssertNil(keychain.getAccessToken())
        XCTAssertNil(keychain.getRefreshToken())
    }

    // MARK: – Codable Storage

    func testSaveAndRetrieveCodable() {
        struct TestData: Codable, Equatable {
            let id: Int
            let label: String
        }

        let data = TestData(id: 42, label: "hello")
        let saved = keychain.saveData(key: .biometricKey, value: data)
        XCTAssertTrue(saved)

        let retrieved = keychain.getData(key: .biometricKey, as: TestData.self)
        XCTAssertEqual(retrieved, data)
    }

    // MARK: – Edge Cases

    func testGetNonExistentKeyReturnsNil() {
        keychain.clearAll()
        XCTAssertNil(keychain.get(key: .deviceId))
    }

    func testEmptyStringCanBeSaved() {
        keychain.save(key: .userId, value: "")
        XCTAssertEqual(keychain.get(key: .userId), "")
    }
}
