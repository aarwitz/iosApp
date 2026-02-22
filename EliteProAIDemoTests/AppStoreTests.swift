// AppStoreTests.swift
// EliteProAIDemoTests
//
// Unit tests for the main application store logic.

import XCTest
@testable import EliteProAIDemo

final class AppStoreTests: XCTestCase {
    var store: AppStore!

    override func setUp() {
        super.setUp()
        store = AppStore()
    }

    override func tearDown() {
        store = nil
        super.tearDown()
    }

    // MARK: – Credits

    func testEarnCreditsIncrements() {
        let initial = store.credits.current
        store.earnCredits(10)
        XCTAssertEqual(store.credits.current, initial + 10)
    }

    func testEarnCreditsDoesNotExceedGoal() {
        store.credits.current = store.credits.goal - 2
        store.earnCredits(10)
        XCTAssertEqual(store.credits.current, store.credits.goal)
    }

    func testEarnCreditsIgnoresNegative() {
        let initial = store.credits.current
        store.earnCredits(-5)
        XCTAssertEqual(store.credits.current, initial, "Negative delta should be clamped to 0")
    }

    // MARK: – Conversations

    func testAddChatMessageUpdatesConversation() {
        guard let convo = store.conversations.first else {
            XCTFail("Expected at least one conversation")
            return
        }

        let initialCount = convo.messages.count
        store.addChatMessage(to: convo.id, text: "Test message")

        let updated = store.conversations.first(where: { $0.id == convo.id })!
        XCTAssertEqual(updated.messages.count, initialCount + 1)
        XCTAssertEqual(updated.lastMessage, "Test message")
        XCTAssertTrue(updated.messages.last!.isMe)
    }

    func testAddChatMessageMovesToTop() {
        guard store.conversations.count >= 2 else {
            XCTFail("Need at least 2 conversations")
            return
        }

        let lastConvo = store.conversations.last!
        store.addChatMessage(to: lastConvo.id, text: "Moving to top")

        XCTAssertEqual(store.conversations.first?.id, lastConvo.id)
    }

    func testFindOrCreateConversationCreatesNew() {
        let initialCount = store.conversations.count
        store.findOrCreateConversation(with: "New Person", initialMessage: "Hello!")

        XCTAssertEqual(store.conversations.count, initialCount + 1)
        XCTAssertEqual(store.conversations.first?.contactName, "New Person")
    }

    func testFindOrCreateConversationUsesExisting() {
        let name = store.conversations.first!.contactName
        let initialCount = store.conversations.count
        store.findOrCreateConversation(with: name, initialMessage: "Follow up")

        XCTAssertEqual(store.conversations.count, initialCount, "Should not create duplicate")
    }

    // MARK: – Posts

    func testAddPostInsertsAtFront() {
        let initialCount = store.feed.count
        store.addPost(groupName: "Test Group", text: "Hello world")

        XCTAssertEqual(store.feed.count, initialCount + 1)
        XCTAssertEqual(store.feed.first?.text, "Hello world")
        XCTAssertEqual(store.feed.first?.author, store.profile.name)
    }

    // MARK: – Rewards

    func testRedeemRewardDeductsCredits() {
        guard let reward = store.rewardItems.first(where: { $0.cost <= store.credits.current }) else {
            XCTSkip("No affordable reward for testing")
            return
        }

        let creditsBefore = store.credits.current
        let success = store.redeemReward(reward.id)

        XCTAssertTrue(success)
        XCTAssertEqual(store.credits.current, creditsBefore - reward.cost)
    }

    func testRedeemRewardFailsWithInsufficientCredits() {
        store.credits.current = 0
        guard let reward = store.rewardItems.first else {
            XCTFail("Expected at least one reward")
            return
        }

        let success = store.redeemReward(reward.id)
        XCTAssertFalse(success)
    }

    // MARK: – Menu

    func testToggleMenu() {
        XCTAssertFalse(store.isMenuOpen)
        store.toggleMenu()
        XCTAssertTrue(store.isMenuOpen)
        store.toggleMenu()
        XCTAssertFalse(store.isMenuOpen)
    }

    func testCloseMenuOnlyClosesWhenOpen() {
        store.isMenuOpen = true
        store.closeMenu()
        XCTAssertFalse(store.isMenuOpen)

        // Calling again should be a no-op
        store.closeMenu()
        XCTAssertFalse(store.isMenuOpen)
    }

    // MARK: – Profile Defaults

    func testDefaultProfileIsPopulated() {
        XCTAssertFalse(store.profile.name.isEmpty)
        XCTAssertFalse(store.profile.email.isEmpty)
        XCTAssertFalse(store.profile.buildingName.isEmpty)
    }

    // MARK: – Demo Data Integrity

    func testChallengesHaveAllCategories() {
        let categories = Set(store.challenges.map(\.category))
        XCTAssertTrue(categories.contains(.recommended))
        XCTAssertTrue(categories.contains(.local))
        XCTAssertTrue(categories.contains(.friends))
    }

    func testFriendsListIsPopulated() {
        XCTAssertGreaterThan(store.friends.count, 20, "Should have bulk-generated friends")
    }
}
