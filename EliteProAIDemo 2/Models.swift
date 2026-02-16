//RootView.swift

import Foundation
import CoreLocation
import SwiftUI

struct UserProfile: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var email: String
    var role: String
    var buildingName: String = ""
    var buildingOwner: String = ""
}

struct HabitCredits: Codable {
    var current: Int
    var goal: Int
}

struct Trainer: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var specialty: String
    var rating: Double
    var pricePerSession: Int
}

struct Group: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var kind: GroupKind
    var locationHint: String
    var members: Int
}

enum GroupKind: String, Codable, CaseIterable {
    case region = "Region"
    case activity = "Activity"
}

struct Post: Codable, Identifiable {
    var id: UUID = UUID()
    var groupName: String
    var communityName: String = ""
    var author: String
    var text: String
    var timestamp: Date
    var imagePlaceholder: String? = nil   // SF Symbol name – leave room for real images
}

struct ChatMessage: Codable, Identifiable {
    var id: UUID = UUID()
    var from: String
    var text: String
    var timestamp: Date
    var isMe: Bool
}

struct Conversation: Codable, Identifiable {
    var id: UUID = UUID()
    var contactName: String
    var lastMessage: String
    var lastMessageTime: Date
    var unreadCount: Int
    var messages: [ChatMessage]
}

enum WellnessAction: String, CaseIterable, Identifiable {
    case coaching = "1–1 Coaching Session"
    case nutrition = "Nutrition Check-In"
    case joinClass = "Join a Group Class"
    case createGroup = "Create a Group"
    case workoutLog = "Workout Log"
    case habits = "Habits & Performance Tracker"

    var id: String { rawValue }
}

// MARK: – Community

struct Community: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var locationHint: String
    var latitude: Double
    var longitude: Double
    var groups: [Group]
}

// MARK: – Challenges

struct Challenge: Identifiable {
    var id: UUID = UUID()
    var title: String
    var subtitle: String
    var category: ChallengeCategory
    var progress: Double          // 0…1
    var imagePlaceholder: String  // SF Symbol for demo
    var communityName: String?
    var friendName: String?
}

enum ChallengeCategory: String, CaseIterable {
    case recommended = "For You"
    case local = "Local"
    case friends = "Friends"
}

// MARK: – Weekly Stats

struct WeeklyStats {
    var workoutsCompleted: Int
    var avgHeartRate: Int
    var sleepHours: Double
    var activitiesJoined: Int
}

// MARK: – Map Pin

struct ActivityPin: Identifiable {
    var id: UUID = UUID()
    var title: String
    var communityName: String
    var groupName: String
    var coordinate: CLLocationCoordinate2D
}

// MARK: – Rewards & Earning

struct EarningOpportunity: Identifiable {
    var id: UUID = UUID()
    var title: String
    var description: String
    var creditsReward: Int
    var category: EarningCategory
    var expiresAt: Date?
    var sponsorName: String?
    var sponsorLogo: String  // SF Symbol
    var requirements: String
    var imagePlaceholder: String
    var isCompleted: Bool = false
}

enum EarningCategory: String, CaseIterable {
    case challenge = "Challenges"
    case sponsored = "Sponsored Events"
    case daily = "Daily Tasks"
    case milestone = "Milestones"
}

struct RewardItem: Identifiable {
    var id: UUID = UUID()
    var title: String
    var description: String
    var cost: Int
    var category: RewardCategory
    var partnerName: String?
    var imagePlaceholder: String
    var isLimited: Bool = false
    var quantityLeft: Int?
}

enum RewardCategory: String, CaseIterable {
    case fitness = "Fitness"
    case wellness = "Wellness"
    case food = "Food & Drink"
    case gear = "Gear & Merch"
    case premium = "Premium Access"
}

// MARK: – Friends & Stories

struct FriendProfile: Identifiable {
    var id: UUID = UUID()
    var name: String
    var age: Int
    var buildingName: String       // e.g. "Echelon Seaport"
    var buildingOwner: String      // e.g. "Barkan Management"
    var bio: String
    var interests: [String]
    var mutualFriends: Int
    var workoutsThisWeek: Int
    var favoriteActivity: String
    var avatarInitials: String     // first two letters for placeholder
    var isFriend: Bool = false
    var hasStory: Bool = false
    var storyItems: [StoryItem] = []
}

struct StoryItem: Identifiable {
    var id: UUID = UUID()
    var imagePlaceholder: String   // SF Symbol
    var caption: String
    var timestamp: Date
    var gradientColors: [Color] = [.blue, .purple]
}

// MARK: – Amenities

struct Amenity: Identifiable {
    var id: UUID = UUID()
    var name: String
    var category: AmenityCategory
    var buildingName: String
    var imagePlaceholder: String   // SF Symbol
    var availableTimes: [String]   // e.g. ["6:00 AM - 10:00 PM", "Mon-Sun"]
    var requiresReservation: Bool
    var description: String
}

enum AmenityCategory: String, CaseIterable {
    case fitness = "Fitness"
    case wellness = "Wellness"
    case social = "Social"
    case services = "Services"
}

struct AmenityInvitation: Identifiable {
    var id: UUID = UUID()
    var amenityName: String
    var fromFriend: String
    var friendInitials: String
    var time: Date
    var duration: String           // e.g. "1 hour"
    var reservationConfirmed: Bool
    var message: String
    var imagePlaceholder: String   // SF Symbol
}

