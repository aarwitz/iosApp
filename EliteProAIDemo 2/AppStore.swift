import Foundation
import SwiftUI

final class AppStore: ObservableObject {

    // UI state
    @Published var selectedTab: AppTab = .challenges
    @Published var isMenuOpen: Bool = false

    // Data
    @Published var profile: UserProfile
    @Published var credits: HabitCredits
    @Published var trainers: [Trainer]
    @Published var groups: [Group]
    @Published var feed: [Post]
    @Published var chat: [ChatMessage]

    private let filename = "elitepro_demo_store.json"

    struct Snapshot: Codable {
        var profile: UserProfile
        var credits: HabitCredits
        var trainers: [Trainer]
        var groups: [Group]
        var feed: [Post]
        var chat: [ChatMessage]
    }

    init() {
        if let snap: Snapshot = Persistence.load(Snapshot.self, from: filename) {
            self.profile = snap.profile
            self.credits = snap.credits
            self.trainers = snap.trainers
            self.groups = snap.groups
            self.feed = snap.feed
            self.chat = snap.chat
        } else {
            self.profile = UserProfile(name: "Luis Mendonca", email: "luis@eliteinhomefitness.com", role: "Member")
            self.credits = HabitCredits(current: 72, goal: 100)

            self.trainers = [
                Trainer(name: "Maya Chen", specialty: "Strength & Mobility", rating: 4.9, pricePerSession: 95),
                Trainer(name: "Andre Silva", specialty: "Hypertrophy", rating: 4.7, pricePerSession: 80),
                Trainer(name: "Priya Nair", specialty: "Nutrition Coaching", rating: 4.8, pricePerSession: 70)
            ]

            self.groups = [
                Group(name: "Seaport Tower — Residents", kind: .region, locationHint: "Boston • Seaport", members: 86),
                Group(name: "Back Bay Running", kind: .activity, locationHint: "Boston • Back Bay", members: 142),
                Group(name: "Beginner Lifting", kind: .activity, locationHint: "Any • Online", members: 317)
            ]

            self.feed = [
                Post(groupName: "Seaport Tower — Residents", author: "Nina", text: "Anyone want to do a 7am mobility session tomorrow in the gym?", timestamp: Date().addingTimeInterval(-60*12)),
                Post(groupName: "Back Bay Running", author: "Sam", text: "5k easy pace this Saturday. Meet at the reservoir 9:30.", timestamp: Date().addingTimeInterval(-60*45)),
                Post(groupName: "Beginner Lifting", author: "Coach Maya", text: "Tip: track 3 numbers weekly — squat, hinge, and press volume. Keep it simple.", timestamp: Date().addingTimeInterval(-60*110))
            ].sorted { $0.timestamp > $1.timestamp }

            self.chat = [
                ChatMessage(from: "Coach Maya", text: "Just now", timestamp: Date().addingTimeInterval(-30), isMe: false),
                ChatMessage(from: "Coach Maya", text: "Just now", timestamp: Date().addingTimeInterval(-28), isMe: false),
                ChatMessage(from: "Coach Maya", text: "Just now", timestamp: Date().addingTimeInterval(-26), isMe: false),
                ChatMessage(from: "You", text: "Just now", timestamp: Date().addingTimeInterval(-12), isMe: true)
            ]
        }
    }

    func persist() {
        let snap = Snapshot(profile: profile, credits: credits, trainers: trainers, groups: groups, feed: feed, chat: chat)
        Persistence.save(snap, to: filename)
    }

    func toggleMenu() {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
            isMenuOpen.toggle()
        }
    }

    func closeMenu() {
        if isMenuOpen {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.95)) {
                isMenuOpen = false
            }
        }
    }

    func addPost(groupName: String, text: String) {
        let p = Post(groupName: groupName, author: profile.name, text: text, timestamp: Date())
        feed.insert(p, at: 0)
        persist()
    }

    func addChatMessage(text: String) {
        let m = ChatMessage(from: "You", text: text, timestamp: Date(), isMe: true)
        chat.append(m)
        persist()
    }

    func earnCredits(_ delta: Int) {
        credits.current = min(credits.goal, credits.current + max(0, delta))
        persist()
    }
}

enum AppTab: Hashable {
    case challenges, connector, rewards, groups
}
