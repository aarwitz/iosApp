// KeychainManager.swift
// EliteProAIDemo
//
// Secure credential storage using the iOS Keychain.
// Stores access tokens, refresh tokens, and sensitive user data.

import Foundation
import Security

final class KeychainManager {
    static let shared = KeychainManager()

    private let serviceName = "com.eliteproai.app"

    // MARK: – Key Constants

    enum Key: String {
        case accessToken  = "access_token"
        case refreshToken = "refresh_token"
        case userId       = "user_id"
        case userEmail    = "user_email"
        case deviceId     = "device_id"
        case biometricKey = "biometric_key"
    }

    private init() {}

    // MARK: – Token Convenience

    func getAccessToken() -> String? {
        get(key: .accessToken)
    }

    func getRefreshToken() -> String? {
        get(key: .refreshToken)
    }

    func saveTokens(access: String, refresh: String) {
        save(key: .accessToken, value: access)
        save(key: .refreshToken, value: refresh)
    }

    func clearTokens() {
        delete(key: .accessToken)
        delete(key: .refreshToken)
    }

    /// Remove ALL stored credentials (used at logout).
    func clearAll() {
        Key.allCases.forEach { delete(key: $0) }
    }

    // MARK: – Generic CRUD

    @discardableResult
    func save(key: Key, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        // Delete existing item first (upsert pattern)
        delete(key: key)

        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String:   data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    func get(key: Key) -> String? {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String:  true,
            kSecMatchLimit as String:  kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    @discardableResult
    func delete(key: Key) -> Bool {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key.rawValue
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    @discardableResult
    func update(key: Key, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key.rawValue
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        return status == errSecSuccess
    }

    // MARK: – Data variant (for storing Codable objects securely)

    func saveData<T: Encodable>(key: Key, value: T) -> Bool {
        guard let data = try? JSONEncoder().encode(value) else { return false }
        guard let string = String(data: data, encoding: .utf8) else { return false }
        return save(key: key, value: string)
    }

    func getData<T: Decodable>(key: Key, as type: T.Type) -> T? {
        guard let string = get(key: key),
              let data = string.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}

// MARK: – CaseIterable for clearAll

extension KeychainManager.Key: CaseIterable {}
