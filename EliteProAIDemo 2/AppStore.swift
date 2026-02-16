import Foundation
import SwiftUI
import Combine
import CoreLocation

final class AppStore: ObservableObject {

    // UI state
    @Published var selectedTab: AppTab = .home
    @Published var isMenuOpen: Bool = false
    @Published var showProfile: Bool = false
    @Published var showRewards: Bool = false
    @Published var showSettings: Bool = false
    @Published var showBookmarks: Bool = false
    @Published var showChallenges: Bool = false
    @Published var showNotifications: Bool = false
    @Published var showSchedule: Bool = false
    @Published var communityFilter: CommunityFilter = .usa

    // Data
    @Published var profile: UserProfile
    @Published var credits: HabitCredits
    @Published var trainers: [Trainer]
    @Published var groups: [Group]
    @Published var feed: [Post]
    @Published var chat: [ChatMessage]
    @Published var conversations: [Conversation]
    @Published var communities: [Community]
    @Published var challenges: [Challenge]
    @Published var weeklyStats: WeeklyStats
    @Published var lastWeekStats: WeeklyStats
    @Published var activityPins: [ActivityPin]
    @Published var earningOpportunities: [EarningOpportunity]
    @Published var rewardItems: [RewardItem]
    @Published var friends: [FriendProfile]
    @Published var discoverableFriends: [FriendProfile]
    @Published var amenities: [Amenity]
    @Published var amenityInvitations: [AmenityInvitation]

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
        // Non-codable demo data initialised first
        self.communities = []
        self.challenges = []
        self.conversations = []
        self.weeklyStats = WeeklyStats(workoutsCompleted: 0, avgHeartRate: 0, sleepHours: 0, activitiesJoined: 0)
        self.lastWeekStats = WeeklyStats(workoutsCompleted: 0, avgHeartRate: 0, sleepHours: 0, activitiesJoined: 0)
        self.activityPins = []

        if let snap: Snapshot = Persistence.load(Snapshot.self, from: filename) {
            self.profile = snap.profile
            self.credits = snap.credits
            self.trainers = snap.trainers
            self.groups = snap.groups
            self.chat = snap.chat
        } else {
            self.profile = UserProfile(name: "Luis Mendonca", email: "luis@eliteinhomefitness.com", role: "Member", buildingName: "Echelon Seaport", buildingOwner: "Barkan Management")
            self.credits = HabitCredits(current: 72, goal: 100)

            self.trainers = [
                Trainer(name: "Jason Chen", specialty: "Strength & Mobility", rating: 4.9, pricePerSession: 95),
                Trainer(name: "Andre Silva", specialty: "Hypertrophy", rating: 4.7, pricePerSession: 80),
                Trainer(name: "Priya Nair", specialty: "Nutrition Coaching", rating: 4.8, pricePerSession: 70)
            ]

            self.groups = [
                Group(name: "Seaport Tower — Residents", kind: .region, locationHint: "Boston • Seaport", members: 86),
                Group(name: "Back Bay Running", kind: .activity, locationHint: "Boston • Back Bay", members: 142),
                Group(name: "Beginner Lifting", kind: .activity, locationHint: "Any • Online", members: 317)
            ]
            
            self.chat = [
                ChatMessage(from: "Coach Jason", text: "Hey Luis! How's recovery feeling after last week's sessions?", timestamp: Date().addingTimeInterval(-30), isMe: false),
                ChatMessage(from: "Coach Jason", text: "I put together a new plan for this week.", timestamp: Date().addingTimeInterval(-28), isMe: false),
                ChatMessage(from: "Coach Jason", text: "Let me know when you're ready to review it.", timestamp: Date().addingTimeInterval(-26), isMe: false),
                ChatMessage(from: "You", text: "Sounds great, let's look at it tomorrow!", timestamp: Date().addingTimeInterval(-12), isMe: true)
            ]
        }

        // Demo conversations
        self.conversations = [
            Conversation(
                contactName: "Coach Jason",
                lastMessage: "Let me know when you're ready to review it.",
                lastMessageTime: Date().addingTimeInterval(-60*25),
                unreadCount: 2,
                messages: [
                    ChatMessage(from: "Coach Jason", text: "Hey Luis! How's recovery feeling after last week's sessions?", timestamp: Date().addingTimeInterval(-60*30), isMe: false),
                    ChatMessage(from: "Coach Jason", text: "I put together a new plan for this week.", timestamp: Date().addingTimeInterval(-60*28), isMe: false),
                    ChatMessage(from: "Coach Jason", text: "Let me know when you're ready to review it.", timestamp: Date().addingTimeInterval(-60*25), isMe: false)
                ]
            ),
            Conversation(
                contactName: "Andre Silva",
                lastMessage: "Thanks for the squat tips yesterday!",
                lastMessageTime: Date().addingTimeInterval(-60*120),
                unreadCount: 0,
                messages: [
                    ChatMessage(from: "Andre Silva", text: "Hey! Quick question about depth on squats", timestamp: Date().addingTimeInterval(-60*240), isMe: false),
                    ChatMessage(from: "You", text: "Go parallel or just below, controlled descent", timestamp: Date().addingTimeInterval(-60*235), isMe: true),
                    ChatMessage(from: "Andre Silva", text: "Perfect, that's what I needed", timestamp: Date().addingTimeInterval(-60*230), isMe: false),
                    ChatMessage(from: "You", text: "Send me a form check video if you want", timestamp: Date().addingTimeInterval(-60*225), isMe: true),
                    ChatMessage(from: "Andre Silva", text: "Thanks for the squat tips yesterday!", timestamp: Date().addingTimeInterval(-60*120), isMe: false)
                ]
            ),
            Conversation(
                contactName: "Nina",
                lastMessage: "See you at 7am tomorrow!",
                lastMessageTime: Date().addingTimeInterval(-60*180),
                unreadCount: 0,
                messages: [
                    ChatMessage(from: "Nina", text: "Still on for mobility tomorrow morning?", timestamp: Date().addingTimeInterval(-60*200), isMe: false),
                    ChatMessage(from: "You", text: "Yes! 7am at the tower gym?", timestamp: Date().addingTimeInterval(-60*195), isMe: true),
                    ChatMessage(from: "Nina", text: "Perfect 🙌", timestamp: Date().addingTimeInterval(-60*190), isMe: false),
                    ChatMessage(from: "Nina", text: "See you at 7am tomorrow!", timestamp: Date().addingTimeInterval(-60*180), isMe: false)
                ]
            ),
            Conversation(
                contactName: "Priya Nair",
                lastMessage: "I'll send over the meal plan tonight",
                lastMessageTime: Date().addingTimeInterval(-60*60*5),
                unreadCount: 1,
                messages: [
                    ChatMessage(from: "Priya Nair", text: "How did the nutrition tracking go this week?", timestamp: Date().addingTimeInterval(-60*60*24), isMe: false),
                    ChatMessage(from: "You", text: "Pretty good, hit protein goals 5/7 days", timestamp: Date().addingTimeInterval(-60*60*23), isMe: true),
                    ChatMessage(from: "Priya Nair", text: "That's solid progress! Let's adjust your plan", timestamp: Date().addingTimeInterval(-60*60*22), isMe: false),
                    ChatMessage(from: "Priya Nair", text: "I'll send over the meal plan tonight", timestamp: Date().addingTimeInterval(-60*60*5), isMe: false)
                ]
            ),
            Conversation(
                contactName: "Sam (Back Bay Running)",
                lastMessage: "Count me in for Saturday's 5k!",
                lastMessageTime: Date().addingTimeInterval(-60*60*2),
                unreadCount: 0,
                messages: [
                    ChatMessage(from: "Sam (Back Bay Running)", text: "Group run this Saturday - you coming?", timestamp: Date().addingTimeInterval(-60*60*4), isMe: false),
                    ChatMessage(from: "You", text: "What's the pace?", timestamp: Date().addingTimeInterval(-60*60*3.5), isMe: true),
                    ChatMessage(from: "Sam (Back Bay Running)", text: "Easy 5k, about 9-10 min/mile", timestamp: Date().addingTimeInterval(-60*60*3), isMe: false),
                    ChatMessage(from: "You", text: "Count me in for Saturday's 5k!", timestamp: Date().addingTimeInterval(-60*60*2), isMe: true)
                ]
            )
        ]

        // Demo communities (not persisted)
        self.communities = [
            Community(name: "The Seaport", locationHint: "Boston • Seaport District", latitude: 42.3519, longitude: -71.0450, groups: [
                Group(name: "Seaport Tower — Residents", kind: .region, locationHint: "Boston • Seaport", members: 86),
                Group(name: "Pickle Ball Club", kind: .activity, locationHint: "Boston • Seaport", members: 42),
                Group(name: "Morning Runners", kind: .activity, locationHint: "Boston • Seaport", members: 63)
            ]),
            Community(name: "Back Bay", locationHint: "Boston • Back Bay", latitude: 42.3503, longitude: -71.0810, groups: [
                Group(name: "Back Bay Running", kind: .activity, locationHint: "Boston • Back Bay", members: 142),
                Group(name: "Yoga Flow", kind: .activity, locationHint: "Boston • Back Bay", members: 58)
            ]),
            Community(name: "South End", locationHint: "Boston • South End", latitude: 42.3388, longitude: -71.0765, groups: [
                Group(name: "Beginner Lifting", kind: .activity, locationHint: "Boston • South End", members: 317),
                Group(name: "Meal Prep Crew", kind: .activity, locationHint: "Boston • South End", members: 29)
            ]),
            Community(name: "Cambridge Fitness", locationHint: "Cambridge • Central Sq", latitude: 42.3656, longitude: -71.1040, groups: [
                Group(name: "CrossFit Central", kind: .activity, locationHint: "Cambridge", members: 95),
                Group(name: "Outdoor Boot Camp", kind: .activity, locationHint: "Cambridge", members: 71)
            ])
        ]

        // Demo challenges
        self.challenges = [
            Challenge(title: "Walk 1,000 Steps Today", subtitle: "Complete your 10,000 step/week goal. You're 82% there!", category: .recommended, progress: 0.82, imagePlaceholder: "figure.walk"),
            Challenge(title: "7-Day Hydration Streak", subtitle: "Drink 2L of water daily for a full week", category: .recommended, progress: 0.57, imagePlaceholder: "drop.fill"),
            Challenge(title: "Log 3 Workouts This Week", subtitle: "Based on your training plan with Coach Jason", category: .recommended, progress: 0.33, imagePlaceholder: "dumbbell.fill"),
            Challenge(title: "30-Min Mobility Challenge", subtitle: "10 min/day for 3 days — unlocks flexibility badge", category: .recommended, progress: 0.0, imagePlaceholder: "figure.flexibility"),

            Challenge(title: "Seaport 5K Fun Run", subtitle: "Community run along the Harborwalk — 48 joined", category: .local, progress: 0.0, imagePlaceholder: "figure.run", communityName: "The Seaport"),
            Challenge(title: "Back Bay Plank-Off", subtitle: "Who can hold the longest plank? Compete locally!", category: .local, progress: 0.0, imagePlaceholder: "flame.fill", communityName: "Back Bay"),
            Challenge(title: "South End Step Challenge", subtitle: "Neighborhood-wide 100K steps in a week", category: .local, progress: 0.15, imagePlaceholder: "shoeprints.fill", communityName: "South End"),

            Challenge(title: "Andre's Squat Challenge", subtitle: "Andre Silva — 315 lb squat by March • 78% done", category: .friends, progress: 0.78, imagePlaceholder: "person.fill", friendName: "Andre Silva"),
            Challenge(title: "Priya's Meal Prep Streak", subtitle: "Priya Nair — 14-day meal prep streak • 9/14 done", category: .friends, progress: 0.64, imagePlaceholder: "fork.knife", friendName: "Priya Nair"),
            Challenge(title: "Sam's Running Goal", subtitle: "Sam — Run 50 miles this month • 34 mi so far", category: .friends, progress: 0.68, imagePlaceholder: "figure.run", friendName: "Sam")
        ]

        // Demo weekly stats
        self.weeklyStats = WeeklyStats(workoutsCompleted: 4, avgHeartRate: 87, sleepHours: 7.2, activitiesJoined: 3)
        self.lastWeekStats = WeeklyStats(workoutsCompleted: 3, avgHeartRate: 82, sleepHours: 6.8, activitiesJoined: 2)

        // Demo activity pins
        self.activityPins = [
            ActivityPin(title: "Morning Yoga", communityName: "Back Bay", groupName: "Yoga Flow", coordinate: CLLocationCoordinate2D(latitude: 42.3510, longitude: -71.0782)),
            ActivityPin(title: "5K Fun Run", communityName: "The Seaport", groupName: "Morning Runners", coordinate: CLLocationCoordinate2D(latitude: 42.3528, longitude: -71.0440)),
            ActivityPin(title: "Boot Camp", communityName: "Cambridge Fitness", groupName: "Outdoor Boot Camp", coordinate: CLLocationCoordinate2D(latitude: 42.3665, longitude: -71.1050)),
            ActivityPin(title: "Pickle Ball Open", communityName: "The Seaport", groupName: "Pickle Ball Club", coordinate: CLLocationCoordinate2D(latitude: 42.3490, longitude: -71.0420)),
            ActivityPin(title: "Beginner Deadlifts", communityName: "South End", groupName: "Beginner Lifting", coordinate: CLLocationCoordinate2D(latitude: 42.3395, longitude: -71.0750)),
            ActivityPin(title: "CrossFit WOD", communityName: "Cambridge Fitness", groupName: "CrossFit Central", coordinate: CLLocationCoordinate2D(latitude: 42.3650, longitude: -71.1035))
        ]
        
        // Demo friends (already connected)
        self.friends = [
            // Friends with stories (fully fleshed out)
            FriendProfile(
                name: "Nina Alvarez", age: 29,
                buildingName: "Echelon Seaport", buildingOwner: "Barkan Management",
                bio: "Yoga lover & early riser. Always down for a morning mobility session.",
                interests: ["Yoga", "Mobility", "Meditation"],
                mutualFriends: 4, workoutsThisWeek: 5, favoriteActivity: "Yoga Flow",
                avatarInitials: "NA", isFriend: true, hasStory: true,
                storyItems: [
                    StoryItem(imagePlaceholder: "figure.yoga", caption: "Morning flow on the rooftop 🧘‍♀️", timestamp: Date().addingTimeInterval(-60*30), gradientColors: [.purple, .pink]),
                    StoryItem(imagePlaceholder: "sunrise.fill", caption: "Caught the sunrise today!", timestamp: Date().addingTimeInterval(-60*90), gradientColors: [.orange, .yellow])
                ]
            ),
            FriendProfile(
                name: "Sam Torres", age: 31,
                buildingName: "Via Seaport", buildingOwner: "The Fallon Company",
                bio: "Running is my therapy. Training for Boston Marathon 2026.",
                interests: ["Running", "HIIT", "Nutrition"],
                mutualFriends: 6, workoutsThisWeek: 6, favoriteActivity: "Back Bay Running",
                avatarInitials: "ST", isFriend: true, hasStory: true,
                storyItems: [
                    StoryItem(imagePlaceholder: "figure.run", caption: "10K PR this morning! 42:15 🏃", timestamp: Date().addingTimeInterval(-60*120), gradientColors: [.green, .teal])
                ]
            ),
            FriendProfile(
                name: "Mei Lin", age: 26,
                buildingName: "Watermark Seaport", buildingOwner: "Greystar",
                bio: "Plant-based athlete. Teaching Sunday yoga in the park.",
                interests: ["Yoga", "Nutrition", "Hiking"],
                mutualFriends: 2, workoutsThisWeek: 3, favoriteActivity: "Yoga Flow",
                avatarInitials: "ML", isFriend: true, hasStory: true,
                storyItems: [
                    StoryItem(imagePlaceholder: "leaf.fill", caption: "New smoothie recipe — spinach mango 🥭", timestamp: Date().addingTimeInterval(-60*45), gradientColors: [.green, .mint]),
                    StoryItem(imagePlaceholder: "figure.flexibility", caption: "Flexibility gains after 30 days!", timestamp: Date().addingTimeInterval(-60*200), gradientColors: [.indigo, .purple])
                ]
            ),
            FriendProfile(
                name: "Alex Rivera", age: 28,
                buildingName: "One Seaport", buildingOwner: "WS Development",
                bio: "CrossFit athlete & nutrition coach. Love helping people hit their goals.",
                interests: ["CrossFit", "Nutrition", "Weightlifting"],
                mutualFriends: 8, workoutsThisWeek: 7, favoriteActivity: "CrossFit Central",
                avatarInitials: "AR", isFriend: true, hasStory: true,
                storyItems: [
                    StoryItem(imagePlaceholder: "dumbbell.fill", caption: "Hit a 225lb clean today! 💪", timestamp: Date().addingTimeInterval(-60*180), gradientColors: [.red, .orange]),
                    StoryItem(imagePlaceholder: "carrot.fill", caption: "Meal prep Sunday vibes 🥗", timestamp: Date().addingTimeInterval(-60*300), gradientColors: [.green, .yellow])
                ]
            ),
            FriendProfile(
                name: "Jenna Watson", age: 30,
                buildingName: "Echelon Seaport", buildingOwner: "Barkan Management",
                bio: "Marathon runner & yoga instructor. Balance is everything.",
                interests: ["Running", "Yoga", "Meditation"],
                mutualFriends: 5, workoutsThisWeek: 6, favoriteActivity: "Morning Runners",
                avatarInitials: "JW", isFriend: true, hasStory: true,
                storyItems: [
                    StoryItem(imagePlaceholder: "heart.fill", caption: "Recovery day = best day", timestamp: Date().addingTimeInterval(-60*60), gradientColors: [.pink, .red])
                ]
            ),
            FriendProfile(
                name: "Marcus Johnson", age: 32,
                buildingName: "Via Seaport", buildingOwner: "The Fallon Company",
                bio: "Former college football player. Now into bodybuilding and powerlifting.",
                interests: ["Powerlifting", "Bodybuilding", "Sports"],
                mutualFriends: 7, workoutsThisWeek: 5, favoriteActivity: "Beginner Lifting",
                avatarInitials: "MJ", isFriend: true, hasStory: true,
                storyItems: [
                    StoryItem(imagePlaceholder: "flame.fill", caption: "Leg day destroyed me 🔥", timestamp: Date().addingTimeInterval(-60*240), gradientColors: [.orange, .red]),
                    StoryItem(imagePlaceholder: "fork.knife", caption: "Post-workout feast!", timestamp: Date().addingTimeInterval(-60*260), gradientColors: [.brown, .orange])
                ]
            ),
            FriendProfile(
                name: "Sofia Martinez", age: 25,
                buildingName: "Watermark Seaport", buildingOwner: "Greystar",
                bio: "Dance fitness instructor. Bringing the energy to every class!",
                interests: ["Dance", "HIIT", "Group Fitness"],
                mutualFriends: 4, workoutsThisWeek: 8, favoriteActivity: "Group Classes",
                avatarInitials: "SM", isFriend: true, hasStory: true,
                storyItems: [
                    StoryItem(imagePlaceholder: "music.note", caption: "New playlist for tomorrow's class 🎵", timestamp: Date().addingTimeInterval(-60*150), gradientColors: [.purple, .blue])
                ]
            ),
            FriendProfile(
                name: "Ryan Park", age: 29,
                buildingName: "One Seaport", buildingOwner: "WS Development",
                bio: "Triathlete training for Ironman. Swim, bike, run, repeat.",
                interests: ["Triathlon", "Swimming", "Cycling", "Running"],
                mutualFriends: 6, workoutsThisWeek: 9, favoriteActivity: "Morning Runners",
                avatarInitials: "RP", isFriend: true, hasStory: true,
                storyItems: [
                    StoryItem(imagePlaceholder: "figure.outdoor.cycle", caption: "50 mile bike ride ✅", timestamp: Date().addingTimeInterval(-60*100), gradientColors: [.blue, .cyan]),
                    StoryItem(imagePlaceholder: "figure.pool.swim", caption: "Open water swim in the harbor!", timestamp: Date().addingTimeInterval(-60*360), gradientColors: [.blue, .teal])
                ]
            ),
            FriendProfile(
                name: "Olivia Brown", age: 27,
                buildingName: "Echelon Seaport", buildingOwner: "Barkan Management",
                bio: "Certified personal trainer. Love helping beginners find their confidence.",
                interests: ["Personal Training", "Strength", "Motivation"],
                mutualFriends: 9, workoutsThisWeek: 6, favoriteActivity: "Beginner Lifting",
                avatarInitials: "OB", isFriend: true, hasStory: true,
                storyItems: [
                    StoryItem(imagePlaceholder: "star.fill", caption: "Client hit their first pull-up today!", timestamp: Date().addingTimeInterval(-60*80), gradientColors: [.yellow, .orange])
                ]
            ),
            FriendProfile(
                name: "David Chen", age: 33,
                buildingName: "Via Seaport", buildingOwner: "The Fallon Company",
                bio: "Rock climber & calisthenics enthusiast. Bodyweight training is underrated.",
                interests: ["Rock Climbing", "Calisthenics", "Parkour"],
                mutualFriends: 3, workoutsThisWeek: 5, favoriteActivity: "Outdoor Activities",
                avatarInitials: "DC", isFriend: true, hasStory: true,
                storyItems: [
                    StoryItem(imagePlaceholder: "figure.climbing", caption: "Sent a V7 project today! 🧗", timestamp: Date().addingTimeInterval(-60*220), gradientColors: [.gray, .blue])
                ]
            ),
            
            // Friends without stories (simpler profiles)
            FriendProfile(name: "Jake Rosenberg", age: 27, buildingName: "Echelon Seaport", buildingOwner: "Barkan Management", bio: "Pickle ball enthusiast", interests: ["Pickle Ball", "Strength Training"], mutualFriends: 3, workoutsThisWeek: 4, favoriteActivity: "Pickle Ball Club", avatarInitials: "JR", isFriend: true, hasStory: false),
            FriendProfile(name: "Dan Kim", age: 33, buildingName: "Echelon Seaport", buildingOwner: "Barkan Management", bio: "Rooftop gym regular", interests: ["Powerlifting", "CrossFit"], mutualFriends: 5, workoutsThisWeek: 5, favoriteActivity: "Beginner Lifting", avatarInitials: "DK", isFriend: true, hasStory: false),
            FriendProfile(name: "Jessica Lee", age: 26, buildingName: "Watermark Seaport", buildingOwner: "Greystar", bio: "Morning runner", interests: ["Running"], mutualFriends: 2, workoutsThisWeek: 3, favoriteActivity: "Morning Runners", avatarInitials: "JL", isFriend: true, hasStory: false),
            FriendProfile(name: "Tom Anderson", age: 31, buildingName: "One Seaport", buildingOwner: "WS Development", bio: "Gym enthusiast", interests: ["Lifting"], mutualFriends: 4, workoutsThisWeek: 4, favoriteActivity: "Beginner Lifting", avatarInitials: "TA", isFriend: true, hasStory: false),
            FriendProfile(name: "Lisa Patel", age: 28, buildingName: "Via Seaport", buildingOwner: "The Fallon Company", bio: "Yoga practitioner", interests: ["Yoga"], mutualFriends: 3, workoutsThisWeek: 2, favoriteActivity: "Yoga Flow", avatarInitials: "LP", isFriend: true, hasStory: false),
            FriendProfile(name: "Chris Walker", age: 29, buildingName: "Echelon Seaport", buildingOwner: "Barkan Management", bio: "Basketball player", interests: ["Basketball"], mutualFriends: 6, workoutsThisWeek: 3, favoriteActivity: "Sports", avatarInitials: "CW", isFriend: true, hasStory: false),
            FriendProfile(name: "Amy Zhou", age: 24, buildingName: "Watermark Seaport", buildingOwner: "Greystar", bio: "Fitness newbie", interests: ["Cardio"], mutualFriends: 1, workoutsThisWeek: 2, favoriteActivity: "Group Classes", avatarInitials: "AZ", isFriend: true, hasStory: false),
            FriendProfile(name: "Brian Murphy", age: 35, buildingName: "One Seaport", buildingOwner: "WS Development", bio: "Cycling enthusiast", interests: ["Cycling"], mutualFriends: 5, workoutsThisWeek: 4, favoriteActivity: "Outdoor Activities", avatarInitials: "BM", isFriend: true, hasStory: false),
            FriendProfile(name: "Rachel Green", age: 27, buildingName: "Via Seaport", buildingOwner: "The Fallon Company", bio: "Pilates instructor", interests: ["Pilates"], mutualFriends: 4, workoutsThisWeek: 5, favoriteActivity: "Pilates", avatarInitials: "RG", isFriend: true, hasStory: false),
            FriendProfile(name: "Kevin Tran", age: 30, buildingName: "Echelon Seaport", buildingOwner: "Barkan Management", bio: "CrossFit member", interests: ["CrossFit"], mutualFriends: 7, workoutsThisWeek: 6, favoriteActivity: "CrossFit Central", avatarInitials: "KT", isFriend: true, hasStory: false),
            FriendProfile(name: "Sarah Mitchell", age: 26, buildingName: "Watermark Seaport", buildingOwner: "Greystar", bio: "Runner", interests: ["Running"], mutualFriends: 3, workoutsThisWeek: 5, favoriteActivity: "Back Bay Running", avatarInitials: "SM", isFriend: true, hasStory: false),
            FriendProfile(name: "Mike Davis", age: 32, buildingName: "One Seaport", buildingOwner: "WS Development", bio: "Weightlifter", interests: ["Weightlifting"], mutualFriends: 4, workoutsThisWeek: 5, favoriteActivity: "Beginner Lifting", avatarInitials: "MD", isFriend: true, hasStory: false),
            FriendProfile(name: "Jennifer Yang", age: 25, buildingName: "Via Seaport", buildingOwner: "The Fallon Company", bio: "Yoga teacher", interests: ["Yoga"], mutualFriends: 2, workoutsThisWeek: 4, favoriteActivity: "Yoga Flow", avatarInitials: "JY", isFriend: true, hasStory: false),
            FriendProfile(name: "Alex Turner", age: 28, buildingName: "Echelon Seaport", buildingOwner: "Barkan Management", bio: "HIIT lover", interests: ["HIIT"], mutualFriends: 5, workoutsThisWeek: 6, favoriteActivity: "Group Classes", avatarInitials: "AT", isFriend: true, hasStory: false),
            FriendProfile(name: "Lauren Scott", age: 29, buildingName: "Watermark Seaport", buildingOwner: "Greystar", bio: "Marathon trainer", interests: ["Running"], mutualFriends: 6, workoutsThisWeek: 7, favoriteActivity: "Back Bay Running", avatarInitials: "LS", isFriend: true, hasStory: false),
        ] + Self.generateBulkFriends(count: 230)
        
        // Demo discoverable friends (for swipe-to-connect)
        self.discoverableFriends = [
            // Echelon building
            FriendProfile(
                name: "Aisha Johnson", age: 28,
                buildingName: "Echelon Seaport", buildingOwner: "Barkan Management",
                bio: "New to Boston! Looking for running buddies and gym partners. Former D1 swimmer turned runner.",
                interests: ["Running", "Swimming", "HIIT", "Meal Prep"],
                mutualFriends: 3, workoutsThisWeek: 4, favoriteActivity: "Morning Runners",
                avatarInitials: "AJ"
            ),
            FriendProfile(
                name: "Tyler Brooks", age: 30,
                buildingName: "Echelon Seaport", buildingOwner: "Barkan Management",
                bio: "Basketball league organizer. Building a pickup hoops group at Echelon. Who's in?",
                interests: ["Basketball", "Strength Training", "Cardio"],
                mutualFriends: 7, workoutsThisWeek: 3, favoriteActivity: "Seaport Tower — Residents",
                avatarInitials: "TB"
            ),
            FriendProfile(
                name: "Devon Patel", age: 26,
                buildingName: "Echelon Seaport", buildingOwner: "Barkan Management",
                bio: "Tech bro who lifts. Tracking everything — macros, sleep, HRV. Data-driven fitness.",
                interests: ["Strength Training", "Biohacking", "Nutrition", "Recovery"],
                mutualFriends: 6, workoutsThisWeek: 5, favoriteActivity: "Beginner Lifting",
                avatarInitials: "DP"
            ),
            
            // Other Seaport buildings
            FriendProfile(
                name: "Marco Reyes", age: 34,
                buildingName: "Via Seaport", buildingOwner: "The Fallon Company",
                bio: "CrossFit Level 2 coach. Love outdoor workouts and competitive fitness. Always up for a challenge.",
                interests: ["CrossFit", "Olympic Lifting", "Boot Camp"],
                mutualFriends: 5, workoutsThisWeek: 6, favoriteActivity: "CrossFit Central",
                avatarInitials: "MR"
            ),
            FriendProfile(
                name: "Sophie Chen", age: 25,
                buildingName: "Watermark Seaport", buildingOwner: "Greystar",
                bio: "Pilates instructor by day, trail runner by weekend. Into clean eating and mindfulness.",
                interests: ["Pilates", "Trail Running", "Meditation", "Nutrition"],
                mutualFriends: 2, workoutsThisWeek: 5, favoriteActivity: "Yoga Flow",
                avatarInitials: "SC"
            ),
            FriendProfile(
                name: "Priya Sharma", age: 27,
                buildingName: "One Seaport", buildingOwner: "WS Development",
                bio: "Nutrition nerd & weekend hiker. Training for my first half-marathon. Love group energy!",
                interests: ["Nutrition", "Hiking", "Running", "Yoga"],
                mutualFriends: 4, workoutsThisWeek: 4, favoriteActivity: "Back Bay Running",
                avatarInitials: "PS"
            ),
            FriendProfile(
                name: "James O'Brien", age: 32,
                buildingName: "Via Seaport", buildingOwner: "The Fallon Company",
                bio: "Former rugby player. Now into functional fitness and mobility. Great spotter if you need one.",
                interests: ["Functional Fitness", "Mobility", "Rugby", "Recovery"],
                mutualFriends: 1, workoutsThisWeek: 5, favoriteActivity: "Beginner Lifting",
                avatarInitials: "JO"
            ),
            FriendProfile(
                name: "Lena Kowalski", age: 29,
                buildingName: "Watermark Seaport", buildingOwner: "Greystar",
                bio: "Dance fitness & barre enthusiast. Also run a meal prep group. Let's connect!",
                interests: ["Dance Fitness", "Barre", "Meal Prep", "Pilates"],
                mutualFriends: 3, workoutsThisWeek: 4, favoriteActivity: "Group Classes",
                avatarInitials: "LK"
            ),
            
            // Back Bay buildings
            FriendProfile(
                name: "Emma Martinez", age: 29,
                buildingName: "The Clarendon", buildingOwner: "Trinity Place Holdings",
                bio: "Marathon runner and yoga instructor. Teaching evening classes in Back Bay!",
                interests: ["Running", "Yoga", "Meditation"],
                mutualFriends: 2, workoutsThisWeek: 7, favoriteActivity: "Back Bay Running",
                avatarInitials: "EM"
            ),
            FriendProfile(
                name: "Jake Williams", age: 31,
                buildingName: "The Viridian", buildingOwner: "Hamilton Company",
                bio: "Powerlifter competing in local meets. Always down to share lifting tips!",
                interests: ["Powerlifting", "Strength Training", "Nutrition"],
                mutualFriends: 1, workoutsThisWeek: 5, favoriteActivity: "Beginner Lifting",
                avatarInitials: "JW"
            ),
            
            // South End buildings
            FriendProfile(
                name: "Maya Rodriguez", age: 27,
                buildingName: "Troy Boston", buildingOwner: "Samuels & Associates",
                bio: "Yoga teacher and plant-based nutrition coach. Let's get healthy together!",
                interests: ["Yoga", "Nutrition", "Meal Prep", "Meditation"],
                mutualFriends: 4, workoutsThisWeek: 4, favoriteActivity: "Yoga Flow",
                avatarInitials: "MR"
            ),
            
            // Cambridge buildings  
            FriendProfile(
                name: "Alex Kim", age: 28,
                buildingName: "The Lofts at Kendall Square", buildingOwner: "Boston Properties",
                bio: "CrossFit athlete training for competitions. Love the grind!",
                interests: ["CrossFit", "Olympic Lifting", "HIIT"],
                mutualFriends: 3, workoutsThisWeek: 6, favoriteActivity: "CrossFit Central",
                avatarInitials: "AK"
            ),
            FriendProfile(
                name: "Rachel Green", age: 26,
                buildingName: "Avalon at Assembly Row", buildingOwner: "AvalonBay Communities",
                bio: "Rock climber and outdoor enthusiast. Weekend adventures in the White Mountains!",
                interests: ["Rock Climbing", "Hiking", "Yoga", "Trail Running"],
                mutualFriends: 2, workoutsThisWeek: 5, favoriteActivity: "Outdoor Activities",
                avatarInitials: "RG"
            )
        ]
        
        // Demo earning opportunities
        self.earningOpportunities = [
            // Challenge-based
            EarningOpportunity(
                title: "Complete 7-Day Hydration Streak",
                description: "Drink 2L of water daily for 7 consecutive days",
                creditsReward: 15,
                category: .challenge,
                expiresAt: Date().addingTimeInterval(60*60*24*5),
                sponsorName: nil,
                sponsorLogo: "drop.fill",
                requirements: "4/7 days completed",
                imagePlaceholder: "drop.triangle.fill",
                isCompleted: false
            ),
            EarningOpportunity(
                title: "Walk 10,000 Steps Today",
                description: "Hit your daily step goal by midnight",
                creditsReward: 5,
                category: .daily,
                expiresAt: Date().addingTimeInterval(60*60*6),
                sponsorName: nil,
                sponsorLogo: "figure.walk",
                requirements: "8,200 / 10,000 steps",
                imagePlaceholder: "shoeprints.fill",
                isCompleted: false
            ),
            EarningOpportunity(
                title: "Log Your Workout",
                description: "Track today's training session in the app",
                creditsReward: 3,
                category: .daily,
                expiresAt: Date().addingTimeInterval(60*60*8),
                sponsorName: nil,
                sponsorLogo: "dumbbell.fill",
                requirements: "Quick log",
                imagePlaceholder: "figure.strengthtraining.traditional",
                isCompleted: false
            ),
            
            // Sponsored events
            EarningOpportunity(
                title: "Sweetgreen Recovery Bowl Challenge",
                description: "Order a post-workout bowl and snap a photo after your next session",
                creditsReward: 25,
                category: .sponsored,
                expiresAt: Date().addingTimeInterval(60*60*24*7),
                sponsorName: "Sweetgreen",
                sponsorLogo: "leaf.circle.fill",
                requirements: "Complete any workout + order",
                imagePlaceholder: "takeoutbag.and.cup.and.straw.fill",
                isCompleted: false
            ),
            EarningOpportunity(
                title: "Lululemon Seaport 5K",
                description: "Join the Lululemon-sponsored community 5K this Saturday at 9 AM",
                creditsReward: 40,
                category: .sponsored,
                expiresAt: Date().addingTimeInterval(60*60*24*2),
                sponsorName: "Lululemon",
                sponsorLogo: "figure.run.circle.fill",
                requirements: "Register & attend event",
                imagePlaceholder: "figure.run",
                isCompleted: false
            ),
            EarningOpportunity(
                title: "Equinox Guest Pass Workout",
                description: "Try Equinox with a free day pass — share your experience in the community",
                creditsReward: 35,
                category: .sponsored,
                expiresAt: Date().addingTimeInterval(60*60*24*14),
                sponsorName: "Equinox",
                sponsorLogo: "figure.indoor.cycle",
                requirements: "Visit + post review",
                imagePlaceholder: "figure.indoor.cycle",
                isCompleted: false
            ),
            EarningOpportunity(
                title: "Blue Bottle Morning Ritual",
                description: "Start your day with Blue Bottle coffee before a morning workout (3x this week)",
                creditsReward: 20,
                category: .sponsored,
                expiresAt: Date().addingTimeInterval(60*60*24*4),
                sponsorName: "Blue Bottle Coffee",
                sponsorLogo: "cup.and.saucer.fill",
                requirements: "0/3 completed",
                imagePlaceholder: "cup.and.saucer.fill",
                isCompleted: false
            ),
            
            // Milestone-based
            EarningOpportunity(
                title: "First 10 Workouts Milestone",
                description: "Complete your first 10 logged workouts in the app",
                creditsReward: 50,
                category: .milestone,
                expiresAt: nil,
                sponsorName: nil,
                sponsorLogo: "star.circle.fill",
                requirements: "7/10 workouts",
                imagePlaceholder: "flag.checkered.circle.fill",
                isCompleted: false
            ),
            EarningOpportunity(
                title: "Community Connector",
                description: "Join 5 different community activities",
                creditsReward: 30,
                category: .milestone,
                expiresAt: nil,
                sponsorName: nil,
                sponsorLogo: "person.3.fill",
                requirements: "3/5 activities",
                imagePlaceholder: "person.3.sequence.fill",
                isCompleted: false
            ),
            EarningOpportunity(
                title: "30-Day Streak Master",
                description: "Log activity for 30 consecutive days",
                creditsReward: 100,
                category: .milestone,
                expiresAt: nil,
                sponsorName: nil,
                sponsorLogo: "flame.circle.fill",
                requirements: "18/30 days",
                imagePlaceholder: "calendar.badge.checkmark",
                isCompleted: false
            )
        ]
        
        // Demo reward items
        self.rewardItems = [
            // Fitness rewards
            RewardItem(
                title: "Free Group Class",
                description: "Join any scheduled group class in your community",
                cost: 30,
                category: .fitness,
                partnerName: nil,
                imagePlaceholder: "figure.mixed.cardio",
                isLimited: false,
                quantityLeft: nil
            ),
            RewardItem(
                title: "1-on-1 Training Session",
                description: "$50 credit toward a personal training session",
                cost: 80,
                category: .fitness,
                partnerName: nil,
                imagePlaceholder: "figure.strengthtraining.traditional",
                isLimited: false,
                quantityLeft: nil
            ),
            RewardItem(
                title: "Equinox Day Pass",
                description: "Experience Equinox with a complimentary day pass",
                cost: 45,
                category: .fitness,
                partnerName: "Equinox",
                imagePlaceholder: "building.columns.fill",
                isLimited: true,
                quantityLeft: 8
            ),
            
            // Wellness rewards
            RewardItem(
                title: "Massage Therapy Session",
                description: "60-min recovery massage at Restore Hyper Wellness",
                cost: 120,
                category: .wellness,
                partnerName: "Restore Hyper Wellness",
                imagePlaceholder: "bed.double.fill",
                isLimited: true,
                quantityLeft: 5
            ),
            RewardItem(
                title: "Cryotherapy Session",
                description: "Whole body cryotherapy for faster recovery",
                cost: 65,
                category: .wellness,
                partnerName: "Restore Hyper Wellness",
                imagePlaceholder: "snowflake",
                isLimited: true,
                quantityLeft: 12
            ),
            RewardItem(
                title: "Nutrition Consultation",
                description: "30-minute nutrition planning session with Priya",
                cost: 55,
                category: .wellness,
                partnerName: nil,
                imagePlaceholder: "leaf.fill",
                isLimited: false,
                quantityLeft: nil
            ),
            
            // Food & Drink
            RewardItem(
                title: "Sweetgreen Bowl",
                description: "Free signature bowl at any Sweetgreen location",
                cost: 25,
                category: .food,
                partnerName: "Sweetgreen",
                imagePlaceholder: "takeoutbag.and.cup.and.straw.fill",
                isLimited: false,
                quantityLeft: nil
            ),
            RewardItem(
                title: "Blue Bottle Coffee (5-Pack)",
                description: "5 free coffees at Blue Bottle — perfect for pre-workout fuel",
                cost: 35,
                category: .food,
                partnerName: "Blue Bottle Coffee",
                imagePlaceholder: "cup.and.saucer.fill",
                isLimited: false,
                quantityLeft: nil
            ),
            RewardItem(
                title: "Pressed Juicery Cleanse",
                description: "3-day juice cleanse delivered to your door",
                cost: 90,
                category: .food,
                partnerName: "Pressed Juicery",
                imagePlaceholder: "waterbottle.fill",
                isLimited: true,
                quantityLeft: 3
            ),
            
            // Gear & Merch
            RewardItem(
                title: "Elite Fitness Water Bottle",
                description: "Insulated 32oz water bottle with community logo",
                cost: 40,
                category: .gear,
                partnerName: nil,
                imagePlaceholder: "waterbottle",
                isLimited: true,
                quantityLeft: 24
            ),
            RewardItem(
                title: "Lululemon $25 Gift Card",
                description: "Put toward any Lululemon gear or apparel",
                cost: 50,
                category: .gear,
                partnerName: "Lululemon",
                imagePlaceholder: "tshirt.fill",
                isLimited: false,
                quantityLeft: nil
            ),
            RewardItem(
                title: "Fitness Tracker Discount",
                description: "$75 off any Whoop or Apple Watch at Best Buy",
                cost: 100,
                category: .gear,
                partnerName: "Best Buy",
                imagePlaceholder: "applewatch.watchface",
                isLimited: true,
                quantityLeft: 6
            ),
            RewardItem(
                title: "Premium Yoga Mat",
                description: "Manduka PRO yoga mat — the gold standard",
                cost: 110,
                category: .gear,
                partnerName: "Manduka",
                imagePlaceholder: "square.3.layers.3d",
                isLimited: true,
                quantityLeft: 4
            ),
            
            // Premium access
            RewardItem(
                title: "Ad-Free Experience (30 days)",
                description: "Enjoy a cleaner app experience for a month",
                cost: 15,
                category: .premium,
                partnerName: nil,
                imagePlaceholder: "sparkles",
                isLimited: false,
                quantityLeft: nil
            ),
            RewardItem(
                title: "Priority Booking Access",
                description: "Book popular classes before they fill up (90 days)",
                cost: 70,
                category: .premium,
                partnerName: nil,
                imagePlaceholder: "calendar.badge.clock",
                isLimited: false,
                quantityLeft: nil
            ),
            RewardItem(
                title: "Exclusive Community Badge",
                description: "Elite In-Home Fitness supporter badge on your profile",
                cost: 20,
                category: .premium,
                partnerName: nil,
                imagePlaceholder: "shield.checkered",
                isLimited: false,
                quantityLeft: nil
            )
        ]
        
        // Demo amenities
        self.amenities = [
            Amenity(
                name: "Rooftop Fitness Center",
                category: .fitness,
                buildingName: "Echelon Seaport",
                imagePlaceholder: "dumbbell.fill",
                availableTimes: ["5:00 AM - 11:00 PM", "Daily"],
                requiresReservation: false,
                description: "Full gym with cardio equipment, free weights, and machines"
            ),
            Amenity(
                name: "Personal Training Sessions",
                category: .services,
                buildingName: "Echelon Seaport",
                imagePlaceholder: "person.fill",
                availableTimes: ["6:00 AM - 9:00 PM", "By Appointment"],
                requiresReservation: true,
                description: "Certified trainers available for 1-on-1 sessions. Book your slot."
            ),
            Amenity(
                name: "Yoga Studio",
                category: .wellness,
                buildingName: "Echelon Seaport",
                imagePlaceholder: "figure.yoga",
                availableTimes: ["6:00 AM - 10:00 PM", "Daily"],
                requiresReservation: true,
                description: "Peaceful studio space for yoga, meditation, and stretching"
            ),
            Amenity(
                name: "Sauna & Steam Room",
                category: .wellness,
                buildingName: "Echelon Seaport",
                imagePlaceholder: "flame.fill",
                availableTimes: ["6:00 AM - 10:00 PM", "Daily"],
                requiresReservation: false,
                description: "Relax and recover in our spa-quality sauna and steam facilities"
            ),
            Amenity(
                name: "Swimming Pool",
                category: .fitness,
                buildingName: "Echelon Seaport",
                imagePlaceholder: "figure.pool.swim",
                availableTimes: ["6:00 AM - 9:00 PM", "Daily"],
                requiresReservation: false,
                description: "25-meter lap pool with designated swim lanes"
            ),
            Amenity(
                name: "Basketball Court",
                category: .social,
                buildingName: "Echelon Seaport",
                imagePlaceholder: "basketball.fill",
                availableTimes: ["7:00 AM - 10:00 PM", "Daily"],
                requiresReservation: true,
                description: "Half-court available for pickup games and practice"
            ),
            Amenity(
                name: "Massage Therapy",
                category: .wellness,
                buildingName: "Echelon Seaport",
                imagePlaceholder: "hands.sparkles.fill",
                availableTimes: ["9:00 AM - 7:00 PM", "Mon-Sat"],
                requiresReservation: true,
                description: "Professional massage therapists available for recovery sessions"
            ),
            Amenity(
                name: "Cycling Studio",
                category: .fitness,
                buildingName: "Echelon Seaport",
                imagePlaceholder: "figure.indoor.cycle",
                availableTimes: ["6:00 AM - 9:00 PM", "Daily"],
                requiresReservation: true,
                description: "Indoor cycling studio with Peloton bikes"
            ),
            Amenity(
                name: "Nutrition Consultation",
                category: .services,
                buildingName: "Echelon Seaport",
                imagePlaceholder: "carrot.fill",
                availableTimes: ["8:00 AM - 6:00 PM", "Mon-Fri"],
                requiresReservation: true,
                description: "Meet with certified nutritionists for personalized meal planning"
            )
        ]
        
        // Demo amenity invitations
        self.amenityInvitations = [
            AmenityInvitation(
                amenityName: "Basketball Court",
                fromFriend: "Jake Rosenberg",
                friendInitials: "JR",
                time: Date().addingTimeInterval(60*60*3),  // 3 hours from now
                duration: "1 hour",
                reservationConfirmed: true,
                message: "Hey! Got a court reservation for pickup hoops. You in? 🏀",
                imagePlaceholder: "basketball.fill"
            ),
            AmenityInvitation(
                amenityName: "Yoga Studio",
                fromFriend: "Nina Alvarez",
                friendInitials: "NA",
                time: Date().addingTimeInterval(60*60*17),  // Tomorrow morning
                duration: "1 hour",
                reservationConfirmed: true,
                message: "Morning flow session tomorrow! Join me? 🧘‍♀️",
                imagePlaceholder: "figure.yoga"
            ),
            AmenityInvitation(
                amenityName: "Personal Training Sessions",
                fromFriend: "Marcus Johnson",
                friendInitials: "MJ",
                time: Date().addingTimeInterval(60*60*26),  // Tomorrow afternoon
                duration: "45 min",
                reservationConfirmed: true,
                message: "Booked a trainer for leg day. Want to join the session?",
                imagePlaceholder: "person.fill"
            )
        ]
        
        // Always use fresh demo feed data (not persisted) so community filters work correctly
        self.feed = [
            // Echelon building posts (most specific)
            Post(groupName: "Seaport Tower — Residents", communityName: "Echelon", author: "Nina", text: "Anyone want to do a 7am mobility session tomorrow in the gym?", timestamp: Date().addingTimeInterval(-60*12), imagePlaceholder: nil),
            Post(groupName: "Pickle Ball Club", communityName: "Echelon", author: "Jake R.", text: "The outdoor pickle ball court just opened. I'm making reservations for Sunday. Who's in?", timestamp: Date().addingTimeInterval(-60*5), imagePlaceholder: "sportscourt"),
            Post(groupName: "Seaport Tower — Residents", communityName: "Echelon", author: "Dan K.", text: "The rooftop gym hours are extended through March. 5AM-11PM.", timestamp: Date().addingTimeInterval(-60*90), imagePlaceholder: "building.2"),
            Post(groupName: "Echelon Early Birds", communityName: "Echelon", author: "Sarah L.", text: "6am workout crew meets tomorrow! Coffee after 💪", timestamp: Date().addingTimeInterval(-60*35), imagePlaceholder: "cup.and.saucer"),
            Post(groupName: "Echelon Yoga", communityName: "Echelon", author: "Emma T.", text: "New evening yoga class starting this week - Tuesdays at 7pm", timestamp: Date().addingTimeInterval(-60*180), imagePlaceholder: "figure.mind.and.body"),
            Post(groupName: "Echelon Swimming", communityName: "Echelon", author: "Marcus W.", text: "Pool is heated and ready! Lap swim schedule posted in lobby.", timestamp: Date().addingTimeInterval(-60*240), imagePlaceholder: "figure.pool.swim"),
            
            // Barkan Management posts (includes multiple buildings)
            Post(groupName: "Barkan Buildings Fitness", communityName: "Barkan Management", author: "Lisa M.", text: "All Barkan-managed buildings now have 24/7 gym access!", timestamp: Date().addingTimeInterval(-60*150), imagePlaceholder: "building.2"),
            Post(groupName: "Barkan Wellness Program", communityName: "Barkan Management", author: "David P.", text: "New wellness program launches next month across all Barkan properties 🎉", timestamp: Date().addingTimeInterval(-60*300), imagePlaceholder: "heart.text.square"),
            Post(groupName: "Barkan Community Events", communityName: "Barkan Management", author: "Rachel K.", text: "Inter-building fitness challenge starting soon! Which building will win?", timestamp: Date().addingTimeInterval(-60*420), imagePlaceholder: "trophy"),
            
            // Seaport neighborhood posts
            Post(groupName: "Beginner Lifting", communityName: "Seaport", author: "Coach Jason", text: "Tip: track 3 numbers weekly — squat, hinge, and press volume. Keep it simple.", timestamp: Date().addingTimeInterval(-60*110), imagePlaceholder: nil),
            Post(groupName: "Seaport Runners", communityName: "Seaport", author: "Chris B.", text: "Harbor run tomorrow at sunrise 🌅 Meet at the pier!", timestamp: Date().addingTimeInterval(-60*65), imagePlaceholder: "figure.run"),
            Post(groupName: "Seaport CrossFit", communityName: "Seaport", author: "Alex R.", text: "WOD: 21-15-9 Thrusters and Pull-ups. Who's joining?", timestamp: Date().addingTimeInterval(-60*140), imagePlaceholder: "figure.strengthtraining.traditional"),
            Post(groupName: "Seaport Beach Volleyball", communityName: "Seaport", author: "Jordan M.", text: "Beach volleyball this weekend! All skill levels welcome 🏐", timestamp: Date().addingTimeInterval(-60*360), imagePlaceholder: "volleyball"),
            Post(groupName: "Seaport Nutrition Club", communityName: "Seaport", author: "Priya N.", text: "Meal prep workshop next Sunday - learn to prep a week's worth of healthy meals!", timestamp: Date().addingTimeInterval(-60*480), imagePlaceholder: "fork.knife"),
            
            // Boston city posts (includes multiple neighborhoods)
            Post(groupName: "Back Bay Running", communityName: "Boston", author: "Sam", text: "5k easy pace this Saturday. Meet at the reservoir 9:30.", timestamp: Date().addingTimeInterval(-60*45), imagePlaceholder: "figure.run"),
            Post(groupName: "Yoga Flow", communityName: "Boston", author: "Mei", text: "Sunday morning flow at the park — 8 AM, all levels welcome!", timestamp: Date().addingTimeInterval(-60*22), imagePlaceholder: "leaf"),
            Post(groupName: "Boston Cycling Club", communityName: "Boston", author: "Tyler J.", text: "40-mile ride along the Charles this Sunday. Fast-paced group!", timestamp: Date().addingTimeInterval(-60*78), imagePlaceholder: "bicycle"),
            Post(groupName: "Boston Strength & Conditioning", communityName: "Boston", author: "Mike S.", text: "New strongman training program starts Monday. Limited spots!", timestamp: Date().addingTimeInterval(-60*220), imagePlaceholder: "figure.wrestling"),
            Post(groupName: "Boston Boxing", communityName: "Boston", author: "Amanda L.", text: "Beginner boxing class tonight at 6pm. Gloves provided!", timestamp: Date().addingTimeInterval(-60*8), imagePlaceholder: "figure.boxing"),
            Post(groupName: "Boston Hiking Group", communityName: "Boston", author: "Kevin H.", text: "Blue Hills hike this Saturday morning. Moderate difficulty, 4 miles.", timestamp: Date().addingTimeInterval(-60*270), imagePlaceholder: "figure.hiking"),
            Post(groupName: "Boston Food & Fitness", communityName: "Boston", author: "Julia F.", text: "Healthy brunch social after our workout tomorrow! Who's in? 🥑", timestamp: Date().addingTimeInterval(-60*540), imagePlaceholder: "cup.and.saucer.fill"),
            
            // Massachusetts state posts (broader region)
            Post(groupName: "Massachusetts Runners", communityName: "Massachusetts", author: "Tom H.", text: "Spring marathon training starts next week. Join us!", timestamp: Date().addingTimeInterval(-60*200), imagePlaceholder: "figure.run"),
            Post(groupName: "Mass Fitness Challenge", communityName: "Massachusetts", author: "Patricia G.", text: "Statewide fitness challenge - 10,000 people signed up so far! 🏃‍♀️", timestamp: Date().addingTimeInterval(-60*390), imagePlaceholder: "person.2.fill"),
            Post(groupName: "Cape Cod Outdoor Fitness", communityName: "Massachusetts", author: "Brian M.", text: "Beach workout sessions starting in April. Can't wait for summer!", timestamp: Date().addingTimeInterval(-60*600), imagePlaceholder: "beach.umbrella"),
            Post(groupName: "Worcester Weightlifting", communityName: "Massachusetts", author: "Steve C.", text: "Regional powerlifting meet next month - come compete!", timestamp: Date().addingTimeInterval(-60*720), imagePlaceholder: "figure.strengthtraining.traditional"),
            
            // USA national posts (broadest scope)
            Post(groupName: "National Fitness Movement", communityName: "USA", author: "Coach Taylor", text: "National fitness month is coming up! What are your goals? 🇺🇸", timestamp: Date().addingTimeInterval(-60*810), imagePlaceholder: "flag"),
            Post(groupName: "USA Wellness Summit", communityName: "USA", author: "Dr. Martinez", text: "Virtual wellness summit next week - free registration!", timestamp: Date().addingTimeInterval(-60*900), imagePlaceholder: "video"),
            Post(groupName: "American Fitness League", communityName: "USA", author: "Commissioner Davis", text: "Season 2 of the AFL starts next month. Join a team near you!", timestamp: Date().addingTimeInterval(-60*1020), imagePlaceholder: "sportscourt.fill")
        ].sorted { $0.timestamp > $1.timestamp }
        
        // Backfill building info if the persisted profile is missing those keys
        if self.profile.buildingName.isEmpty {
            self.profile.buildingName = "Echelon Seaport"
        }
        if self.profile.buildingOwner.isEmpty {
            self.profile.buildingOwner = "Barkan Management"
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

    func addPost(groupName: String, text: String, communityName: String = "") {
        let p = Post(groupName: groupName, communityName: communityName, author: profile.name, text: text, timestamp: Date())
        feed.insert(p, at: 0)
        persist()
    }

    func addChatMessage(to conversationId: UUID, text: String) {
        guard let index = conversations.firstIndex(where: { $0.id == conversationId }) else { return }
        let m = ChatMessage(from: "You", text: text, timestamp: Date(), isMe: true)
        conversations[index].messages.append(m)
        conversations[index].lastMessage = text
        conversations[index].lastMessageTime = Date()
        // Move conversation to top
        let updated = conversations.remove(at: index)
        conversations.insert(updated, at: 0)
        persist()
    }
    
    func findOrCreateConversation(with contactName: String, initialMessage: String) {
        // Check if conversation already exists
        if let existing = conversations.first(where: { $0.contactName == contactName }) {
            addChatMessage(to: existing.id, text: initialMessage)
        } else {
            // Create new conversation
            let message = ChatMessage(from: "You", text: initialMessage, timestamp: Date(), isMe: true)
            let newConversation = Conversation(
                contactName: contactName,
                lastMessage: initialMessage,
                lastMessageTime: Date(),
                unreadCount: 0,
                messages: [message]
            )
            conversations.insert(newConversation, at: 0)
            persist()
        }
    }

    func earnCredits(_ delta: Int) {
        credits.current = min(credits.goal, credits.current + max(0, delta))
        persist()
    }
    
    func completeEarningOpportunity(_ opportunityId: UUID) {
        guard let index = earningOpportunities.firstIndex(where: { $0.id == opportunityId }) else { return }
        let opportunity = earningOpportunities[index]
        
        // Mark as completed
        earningOpportunities[index].isCompleted = true
        
        // Award credits
        earnCredits(opportunity.creditsReward)
    }
    
    func redeemReward(_ rewardId: UUID) -> Bool {
        guard let reward = rewardItems.first(where: { $0.id == rewardId }) else { return false }
        
        // Check if user has enough credits
        guard credits.current >= reward.cost else { return false }
        
        // Check if limited item is still available
        if reward.isLimited, let quantity = reward.quantityLeft, quantity <= 0 {
            return false
        }
        
        // Deduct credits
        credits.current -= reward.cost
        
        // Update quantity if limited
        if reward.isLimited, let index = rewardItems.firstIndex(where: { $0.id == rewardId }) {
            if let currentQuantity = rewardItems[index].quantityLeft {
                rewardItems[index].quantityLeft = currentQuantity - 1
            }
        }
        
        persist()
        return true
    }
    
    // Generate bulk simple friends
    static func generateBulkFriends(count: Int) -> [FriendProfile] {
        let firstNames = ["Alex", "Jordan", "Taylor", "Morgan", "Casey", "Riley", "Drew", "Cameron", "Avery", "Quinn", "Peyton", "Reese", "Parker", "Logan", "Skylar", "Dakota", "Hayden", "Charlie", "Emerson", "Rowan", "Sage", "River", "Phoenix", "Blake", "Jamie", "Jesse", "Kai", "Cameron", "Pat", "Sam"]
        let lastNames = ["Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis", "Rodriguez", "Martinez", "Hernandez", "Lopez", "Wilson", "Anderson", "Thomas", "Taylor", "Moore", "Jackson", "Martin", "Lee", "Thompson", "White", "Harris", "Clark", "Lewis", "Robinson", "Walker", "Hall", "Allen", "Young"]
        let buildings = ["Echelon Seaport", "Via Seaport", "Watermark Seaport", "One Seaport", "50 Liberty"]
        let owners = ["Barkan Management", "The Fallon Company", "Greystar", "WS Development", "Hines"]
        let activities = ["Running", "Yoga", "Lifting", "CrossFit", "Cycling", "Swimming", "HIIT", "Pilates", "Boxing", "Climbing"]
        
        var friends: [FriendProfile] = []
        for i in 0..<count {
            let firstName = firstNames[i % firstNames.count]
            let lastName = lastNames[(i / firstNames.count) % lastNames.count]
            let name = "\(firstName) \(lastName)"
            let initials = "\(firstName.prefix(1))\(lastName.prefix(1))"
            let building = buildings[i % buildings.count]
            let owner = owners[i % owners.count]
            let activity = activities[i % activities.count]
            
            friends.append(FriendProfile(
                name: name,
                age: 22 + (i % 18),
                buildingName: building,
                buildingOwner: owner,
                bio: "Fitness enthusiast",
                interests: [activity],
                mutualFriends: i % 10,
                workoutsThisWeek: i % 7,
                favoriteActivity: activity,
                avatarInitials: initials,
                isFriend: true,
                hasStory: false
            ))
        }
        return friends
    }
}

enum AppTab: Hashable {
    case home, connector, challenges, community, chat
}
