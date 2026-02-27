// StoreFeatureTests.swift
// EliteProAIDemoTests
//
// Tests for booking, staff, feed, credits, and slots logic added in the recent feature sprint.

import XCTest
@testable import EliteProAIDemo

final class StoreFeatureTests: XCTestCase {
    var store: AppStore!

    override func setUp() {
        super.setUp()
        Persistence.delete("elitepro_demo_store.json")
        store = AppStore()
    }

    override func tearDown() {
        store = nil
        super.tearDown()
    }

    // MARK: – Staff Members

    func testStaffMembersArePopulated() {
        XCTAssertGreaterThan(store.staffMembers.count, 0, "Staff should be seeded on init")
    }

    func testStaffIncludesAtLeastOneCoach() {
        let coaches = store.staffMembers.filter { $0.role == .coach }
        XCTAssertGreaterThan(coaches.count, 0, "Should have at least one coach")
    }

    func testStaffIncludesAtLeastOneNutritionist() {
        let nutritionists = store.staffMembers.filter { $0.role == .nutritionist }
        XCTAssertGreaterThan(nutritionists.count, 0, "Should have at least one nutritionist")
    }

    func testCurrentCoachIsSet() {
        XCTAssertNotNil(store.currentCoach, "currentCoach should return a staff member on the current shift")
    }

    func testCurrentNutritionistIsSet() {
        XCTAssertNotNil(store.currentNutritionist, "currentNutritionist should return a staff member on the current shift")
    }

    func testEachStaffMemberHasCredentials() {
        for member in store.staffMembers {
            XCTAssertFalse(member.credentials.isEmpty, "\(member.name) should have credentials")
        }
    }

    func testEachStaffMemberHasBio() {
        for member in store.staffMembers {
            XCTAssertFalse(member.bio.isEmpty, "\(member.name) should have a bio")
        }
    }

    // MARK: – Available Slots

    func testAvailableSlotsAreAllInFuture() {
        let now = Date()
        for member in store.staffMembers {
            for slot in member.availableSlots {
                XCTAssertGreaterThan(slot, now,
                    "\(member.name)'s slot \(slot) should be in the future")
            }
        }
    }

    func testAvailableSlotsAreNotEmpty() {
        for member in store.staffMembers {
            XCTAssertFalse(member.availableSlots.isEmpty,
                "\(member.name) should have at least one bookable slot")
        }
    }

    func testSlotHoursAreWithinShift() {
        let cal = Calendar.current
        for member in store.staffMembers {
            for slot in member.availableSlots {
                let hour = cal.component(.hour, from: slot)
                XCTAssertGreaterThanOrEqual(hour, member.shift.startHour,
                    "\(member.name) slot hour \(hour) is before shift start \(member.shift.startHour)")
                XCTAssertLessThan(hour, member.shift.endHour,
                    "\(member.name) slot hour \(hour) is at/after shift end \(member.shift.endHour)")
            }
        }
    }

    // MARK: – Booking

    func testBookSessionAddsToBookedSessions() async {
        guard let coach = store.staffMembers.first(where: { $0.role == .coach }),
              let slot = coach.availableSlots.first else {
            XCTFail("Need a coach with available slots")
            return
        }

        let before = store.bookedSessions.count
        await MainActor.run { store.bookSession(staff: coach, date: slot) }
        XCTAssertEqual(store.bookedSessions.count, before + 1)
    }

    func testBookSessionStoresCorrectDetails() async {
        guard let coach = store.staffMembers.first(where: { $0.role == .coach }),
              let slot = coach.availableSlots.first else {
            XCTFail("Need a coach with available slots")
            return
        }

        await MainActor.run { store.bookSession(staff: coach, date: slot) }
        let session = store.bookedSessions.last!
        XCTAssertEqual(session.staffName, coach.name)
        XCTAssertEqual(session.staffRole, .coach)
        XCTAssertEqual(session.date, slot)
    }

    func testBookCoachSessionEarns10Credits() async {
        guard let coach = store.staffMembers.first(where: { $0.role == .coach }),
              let slot = coach.availableSlots.first else {
            XCTFail("Need a coach with available slots")
            return
        }

        store.credits.current = 0
        await MainActor.run { store.bookSession(staff: coach, date: slot) }
        XCTAssertEqual(store.credits.current, 10)
    }

    func testBookNutritionistSessionEarns5Credits() async {
        guard let nutri = store.staffMembers.first(where: { $0.role == .nutritionist }),
              let slot = nutri.availableSlots.first else {
            XCTFail("Need a nutritionist with available slots")
            return
        }

        store.credits.current = 0
        await MainActor.run { store.bookSession(staff: nutri, date: slot) }
        XCTAssertEqual(store.credits.current, 5)
    }

    func testMultipleBookingsAccumulate() async {
        let staffWithSlots = store.staffMembers.filter { !$0.availableSlots.isEmpty }
        guard staffWithSlots.count >= 2 else {
            XCTSkip("Need at least 2 staff members with slots")
            return
        }

        let before = store.bookedSessions.count
        await MainActor.run {
            store.bookSession(staff: staffWithSlots[0], date: staffWithSlots[0].availableSlots[0])
            store.bookSession(staff: staffWithSlots[1], date: staffWithSlots[1].availableSlots[0])
        }
        XCTAssertEqual(store.bookedSessions.count, before + 2)
    }

    // MARK: – Feed

    func testFeedIsPopulated() {
        XCTAssertGreaterThan(store.feed.count, 0, "Feed should have demo posts on init")
    }

    func testFeedPostsHaveNonEmptyText() {
        for post in store.feed {
            XCTAssertFalse(post.text.isEmpty, "Post text should not be empty")
        }
    }

    func testFeedPostsHaveAuthors() {
        for post in store.feed {
            XCTAssertFalse(post.author.isEmpty, "Post author should not be empty")
        }
    }

    func testFeedContainsMultipleCommunities() {
        let communities = Set(store.feed.map(\.communityName))
        XCTAssertGreaterThan(communities.count, 1, "Feed should have posts from multiple communities")
    }

    // MARK: – Communities

    func testCommunitiesArePopulated() {
        XCTAssertGreaterThan(store.communities.count, 0, "Communities should be seeded")
    }

    func testEachCommunityHasGroups() {
        for community in store.communities {
            XCTAssertFalse(community.groups.isEmpty,
                "\(community.name) should have at least one group")
        }
    }

    // MARK: – Meal Suggestions

    func testMealSuggestionsArePopulated() {
        XCTAssertGreaterThan(store.mealSuggestions.count, 0, "Meal suggestions should be seeded")
    }

    func testQuickRecipesArePopulated() {
        XCTAssertGreaterThan(store.quickRecipes.count, 0, "Quick recipes should be seeded")
    }

    func testMealSuggestionsHaveNames() {
        for meal in store.mealSuggestions {
            XCTAssertFalse(meal.name.isEmpty, "Meal name should not be empty")
            XCTAssertFalse(meal.restaurant.isEmpty, "Meal restaurant should not be empty")
        }
    }

    // MARK: – Earning Opportunities

    func testEarningOpportunitiesArePopulated() {
        XCTAssertGreaterThan(store.earningOpportunities.count, 0, "Earning opportunities should be seeded")
    }

    func testEarningOpportunityCreditsArePositive() {
        for opportunity in store.earningOpportunities {
            XCTAssertGreaterThan(opportunity.creditsReward, 0,
                "\(opportunity.title) should reward positive credits")
        }
    }

    func testCompleteEarningOpportunityAddsCredits() async {
        guard let opportunity = store.earningOpportunities.first(where: { !$0.isCompleted }) else {
            XCTSkip("No incomplete opportunities to test")
            return
        }

        let reward = opportunity.creditsReward
        store.credits.current = 0
        await MainActor.run { store.completeEarningOpportunity(opportunity.id) }

        XCTAssertEqual(store.credits.current, reward)
        let updated = store.earningOpportunities.first(where: { $0.id == opportunity.id })!
        XCTAssertTrue(updated.isCompleted)
    }

    // MARK: – Weekly Stats

    func testWeeklyStatsAreNonZero() {
        XCTAssertGreaterThan(store.weeklyStats.workoutsCompleted, 0)
        XCTAssertGreaterThan(store.weeklyStats.avgHeartRate, 0)
        XCTAssertGreaterThan(store.weeklyStats.sleepHours, 0)
    }

    func testLastWeekStatsArePopulated() {
        XCTAssertGreaterThan(store.lastWeekStats.workoutsCompleted, 0)
    }

    // MARK: – Conversations (seeded)

    func testSeedConversationsExist() {
        XCTAssertGreaterThanOrEqual(store.conversations.count, 2,
            "AppStore should seed at least 2 demo conversations for offline use")
    }

    func testSeedConversationsHaveMessages() {
        for convo in store.conversations {
            XCTAssertFalse(convo.messages.isEmpty,
                "\(convo.contactName)'s conversation should have at least one message")
        }
    }

    func testConversationLastMessageMatchesMostRecentMessage() {
        for convo in store.conversations {
            XCTAssertEqual(convo.lastMessage, convo.messages.last?.text,
                "lastMessage should equal the last message's text")
        }
    }
}
