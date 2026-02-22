// ModelTests.swift
// EliteProAIDemoTests
//
// Tests for model encoding/decoding and data integrity.

import XCTest
@testable import EliteProAIDemo

final class ModelTests: XCTestCase {

    // MARK: – UserProfile Codable

    func testUserProfileRoundTrip() throws {
        let profile = UserProfile(
            name: "Test User",
            email: "test@example.com",
            role: "Member",
            buildingName: "Test Building",
            buildingOwner: "Test Owner"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(profile)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(UserProfile.self, from: data)

        XCTAssertEqual(decoded.name, profile.name)
        XCTAssertEqual(decoded.email, profile.email)
        XCTAssertEqual(decoded.role, profile.role)
        XCTAssertEqual(decoded.buildingName, profile.buildingName)
        XCTAssertEqual(decoded.buildingOwner, profile.buildingOwner)
    }

    func testUserProfileDecodesWithMissingFields() throws {
        let json = """
        {
            "name": "Partial User"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let profile = try decoder.decode(UserProfile.self, from: json)

        XCTAssertEqual(profile.name, "Partial User")
        XCTAssertEqual(profile.email, "")
        XCTAssertEqual(profile.role, "Member")
        XCTAssertEqual(profile.buildingName, "")
    }

    // MARK: – HabitCredits

    func testHabitCreditsRoundTrip() throws {
        let credits = HabitCredits(current: 50, goal: 100)
        let data = try JSONEncoder().encode(credits)
        let decoded = try JSONDecoder().decode(HabitCredits.self, from: data)

        XCTAssertEqual(decoded.current, 50)
        XCTAssertEqual(decoded.goal, 100)
    }

    // MARK: – CommunityFilter

    func testCommunityFilterInclusion() {
        // Echelon should only include Echelon
        XCTAssertTrue(CommunityFilter.echelon.includedCommunities.contains("Echelon"))
        XCTAssertFalse(CommunityFilter.echelon.includedCommunities.contains("Boston"))

        // Boston should include Echelon and Seaport
        XCTAssertTrue(CommunityFilter.boston.includedCommunities.contains("Echelon"))
        XCTAssertTrue(CommunityFilter.boston.includedCommunities.contains("Seaport"))

        // USA is empty set (means show all)
        XCTAssertTrue(CommunityFilter.usa.includedCommunities.isEmpty)
    }

    func testCommunityFilterBuildingMatching() {
        XCTAssertTrue(CommunityFilter.echelon.matchesBuilding(buildingName: "Echelon Seaport", buildingOwner: "Barkan"))
        XCTAssertFalse(CommunityFilter.echelon.matchesBuilding(buildingName: "Via Seaport", buildingOwner: "Fallon"))
        XCTAssertTrue(CommunityFilter.barkan.matchesBuilding(buildingName: "Via Seaport", buildingOwner: "Barkan Management"))
    }

    // MARK: – GroupKind

    func testGroupKindAllCases() {
        XCTAssertEqual(GroupKind.allCases.count, 2)
        XCTAssertEqual(GroupKind.region.rawValue, "Region")
        XCTAssertEqual(GroupKind.activity.rawValue, "Activity")
    }

    // MARK: – WellnessAction

    func testWellnessActionIdentifiers() {
        for action in WellnessAction.allCases {
            XCTAssertEqual(action.id, action.rawValue, "ID should match rawValue")
        }
        XCTAssertEqual(WellnessAction.allCases.count, 6)
    }
}
