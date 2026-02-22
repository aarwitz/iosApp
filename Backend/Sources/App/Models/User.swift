// User.swift
// EliteProAI Backend
//
// User database model with Fluent ORM.

import Fluent
import Vapor

final class User: Model, Content, @unchecked Sendable {
    static let schema = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "email")
    var email: String

    @Field(key: "password_hash")
    var passwordHash: String

    @Field(key: "role")
    var role: String

    @OptionalField(key: "building_name")
    var buildingName: String?

    @OptionalField(key: "building_owner")
    var buildingOwner: String?

    @OptionalField(key: "avatar_url")
    var avatarURL: String?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() {}

    init(
        id: UUID? = nil,
        name: String,
        email: String,
        passwordHash: String,
        role: String = "Member",
        buildingName: String? = nil,
        buildingOwner: String? = nil
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.passwordHash = passwordHash
        self.role = role
        self.buildingName = buildingName
        self.buildingOwner = buildingOwner
    }
}

// MARK: – Public representation (never expose password hash)

extension User {
    struct Public: Content {
        let id: UUID
        let name: String
        let email: String
        let role: String
        let buildingName: String?
        let buildingOwner: String?
        let avatarURL: String?
    }

    func asPublic() throws -> Public {
        Public(
            id: try requireID(),
            name: name,
            email: email,
            role: role,
            buildingName: buildingName,
            buildingOwner: buildingOwner,
            avatarURL: avatarURL
        )
    }
}

// MARK: – Validatable

extension User: Validatable {
    static func validations(_ v: inout Validations) {
        v.add("name", as: String.self, is: !.empty)
        v.add("email", as: String.self, is: .email)
        v.add("password", as: String.self, is: .count(8...))
    }
}

// MARK: – ModelAuthenticatable (for password verification)

extension User: ModelAuthenticatable {
    static let usernameKey = \User.$email
    static let passwordHashKey = \User.$passwordHash

    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.passwordHash)
    }
}
