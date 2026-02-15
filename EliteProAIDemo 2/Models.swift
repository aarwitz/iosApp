import Foundation

struct UserProfile: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var email: String
    var role: String
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
    var author: String
    var text: String
    var timestamp: Date
}

struct ChatMessage: Codable, Identifiable {
    var id: UUID = UUID()
    var from: String
    var text: String
    var timestamp: Date
    var isMe: Bool
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
