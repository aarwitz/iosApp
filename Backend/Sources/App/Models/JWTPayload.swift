// JWTPayload.swift
// EliteProAI Backend
//
// JWT access token payload structure.

import JWT
import Vapor

struct UserJWTPayload: JWTPayload {
    var sub: SubjectClaim       // user ID
    var exp: ExpirationClaim    // expiration
    var iat: IssuedAtClaim      // issued at
    var role: String

    func verify(using signer: JWTSigner) throws {
        try exp.verifyNotExpired()
    }

    init(userId: UUID, role: String, expiresIn: TimeInterval = 15 * 60) {
        self.sub = SubjectClaim(value: userId.uuidString)
        self.exp = ExpirationClaim(value: Date().addingTimeInterval(expiresIn))
        self.iat = IssuedAtClaim(value: Date())
        self.role = role
    }
}
