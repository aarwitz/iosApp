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
    @Published var showConnector: Bool = false

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
            self.feed = snap.feed
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

            self.feed = [
                Post(groupName: "Seaport Tower — Residents", communityName: "The Seaport", author: "Nina", text: "Anyone want to do a 7am mobility session tomorrow in the gym?", timestamp: Date().addingTimeInterval(-60*12), imagePlaceholder: nil),
                Post(groupName: "Back Bay Running", communityName: "Back Bay", author: "Sam", text: "5k easy pace this Saturday. Meet at the reservoir 9:30.", timestamp: Date().addingTimeInterval(-60*45), imagePlaceholder: "figure.run"),
                Post(groupName: "Beginner Lifting", communityName: "The Seaport", author: "Coach Jason", text: "Tip: track 3 numbers weekly — squat, hinge, and press volume. Keep it simple.", timestamp: Date().addingTimeInterval(-60*110), imagePlaceholder: nil),
                Post(groupName: "Pickle Ball Club", communityName: "The Seaport", author: "Jake R.", text: "The outdoor pickle ball court just opened. I'm making reservations for Sunday. Who's in?", timestamp: Date().addingTimeInterval(-60*5), imagePlaceholder: "sportscourt"),
                Post(groupName: "Yoga Flow", communityName: "South End", author: "Mei", text: "Sunday morning flow at the park — 8 AM, all levels welcome!", timestamp: Date().addingTimeInterval(-60*22), imagePlaceholder: "leaf"),
                Post(groupName: "Seaport Tower — Residents", communityName: "The Seaport", author: "Dan K.", text: "The rooftop gym hours are extended through March. 5AM-11PM.", timestamp: Date().addingTimeInterval(-60*90), imagePlaceholder: "building.2")
            ].sorted { $0.timestamp > $1.timestamp }

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
                name: "Jake Rosenberg", age: 27,
                buildingName: "Echelon Seaport", buildingOwner: "Barkan Management",
                bio: "Pickle ball enthusiast. Gym 6 days/week. Let's play!",
                interests: ["Pickle Ball", "Strength Training", "Basketball"],
                mutualFriends: 3, workoutsThisWeek: 4, favoriteActivity: "Pickle Ball Club",
                avatarInitials: "JR", isFriend: true, hasStory: false
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
                name: "Dan Kim", age: 33,
                buildingName: "Echelon Seaport", buildingOwner: "Barkan Management",
                bio: "Rooftop gym regular. Ask me about powerlifting programs.",
                interests: ["Powerlifting", "CrossFit", "Recovery"],
                mutualFriends: 5, workoutsThisWeek: 5, favoriteActivity: "Beginner Lifting",
                avatarInitials: "DK", isFriend: true, hasStory: false
            )
        ]
        
        // Demo discoverable friends (for swipe-to-connect)
        self.discoverableFriends = [
            FriendProfile(
                name: "Aisha Johnson", age: 28,
                buildingName: "Echelon Seaport", buildingOwner: "Barkan Management",
                bio: "New to Boston! Looking for running buddies and gym partners. Former D1 swimmer turned runner.",
                interests: ["Running", "Swimming", "HIIT", "Meal Prep"],
                mutualFriends: 3, workoutsThisWeek: 4, favoriteActivity: "Morning Runners",
                avatarInitials: "AJ"
            ),
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
                name: "Tyler Brooks", age: 30,
                buildingName: "Echelon Seaport", buildingOwner: "Barkan Management",
                bio: "Basketball league organizer. Building a pickup hoops group at Echelon. Who's in?",
                interests: ["Basketball", "Strength Training", "Cardio"],
                mutualFriends: 7, workoutsThisWeek: 3, favoriteActivity: "Seaport Tower — Residents",
                avatarInitials: "TB"
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
            FriendProfile(
                name: "Devon Patel", age: 26,
                buildingName: "Echelon Seaport", buildingOwner: "Barkan Management",
                bio: "Tech bro who lifts. Tracking everything — macros, sleep, HRV. Data-driven fitness.",
                interests: ["Strength Training", "Biohacking", "Nutrition", "Recovery"],
                mutualFriends: 6, workoutsThisWeek: 5, favoriteActivity: "Beginner Lifting",
                avatarInitials: "DP"
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
}

enum AppTab: Hashable {
    case home, connector, challenges, community, chat
}
