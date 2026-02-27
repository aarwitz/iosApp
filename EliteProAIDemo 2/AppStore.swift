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

    // Network state
    @Published var isLoading: Bool = false
    @Published var loadError: String?

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
    @Published var notifications: [AppNotificationResponse] = []
    @Published var friendRequests: [FriendRequestResponse] = []
    @Published var staffMembers: [StaffMember] = []
    @Published var mealSuggestions: [MealSuggestion] = []
    @Published var quickRecipes: [QuickRecipe] = []
    @Published var bookedSessions: [BookedSession] = []

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
                Trainer(name: "Sarah Martinez", specialty: "Nutrition Coaching", rating: 4.8, pricePerSession: 70),
                Trainer(name: "Andre Silva", specialty: "Hypertrophy", rating: 4.7, pricePerSession: 80),
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

        // Seed two demo conversations so the app and unit tests work offline.
        // These are replaced by API data once refreshConversations() completes on launch.
        self.conversations = [
            Conversation(
                contactName: "Coach Jason",
                lastMessage: "I put together a new plan for this week.",
                lastMessageTime: Date().addingTimeInterval(-1800),
                unreadCount: 1,
                messages: [
                    ChatMessage(from: "Coach Jason", text: "I put together a new plan for this week.", timestamp: Date().addingTimeInterval(-1800), isMe: false)
                ]
            ),
            Conversation(
                contactName: "Sam",
                lastMessage: "See you at the 5K tomorrow!",
                lastMessageTime: Date().addingTimeInterval(-7200),
                unreadCount: 0,
                messages: [
                    ChatMessage(from: "Sam", text: "See you at the 5K tomorrow!", timestamp: Date().addingTimeInterval(-7200), isMe: false)
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
        
        // Friends loaded from API
        self.friends = []
        
        // Discoverable users loaded from API
        self.discoverableFriends = []
        
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
        
        // MARK: – Staff Members (Coaches & Nutritionists with shifts)
        let morningShift = StaffShift(label: "Morning", startHour: 6, endHour: 12, displayRange: "6 AM – 12 PM")
        let afternoonShift = StaffShift(label: "Afternoon", startHour: 12, endHour: 18, displayRange: "12 PM – 6 PM")
        let eveningShift = StaffShift(label: "Evening", startHour: 18, endHour: 22, displayRange: "6 PM – 10 PM")
        
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        
        func slots(for shift: StaffShift) -> [Date] {
            // Try today first. If all slots are in the past, use tomorrow so the booking UI always has choices.
            let now = Date()
            func slotsOnDay(_ day: Date) -> [Date] {
                stride(from: shift.startHour, to: shift.endHour, by: 1).compactMap { hour in
                    cal.date(bySettingHour: hour, minute: 0, second: 0, of: day)
                }
            }
            let todaySlots = slotsOnDay(today).filter { $0 > now }
            if !todaySlots.isEmpty { return todaySlots }
            let tomorrow = cal.date(byAdding: .day, value: 1, to: today)!
            return slotsOnDay(tomorrow)
        }
        
        self.staffMembers = [
            // Coaches
            StaffMember(
                name: "Jason Chen", role: .coach,
                credentials: ["NASM-CPT", "BS Kinesiology", "TRX Certified"],
                bio: "Strength & mobility specialist. 8 years experience helping residents move better and feel great.",
                avatarPlaceholder: "figure.strengthtraining.traditional",
                shift: morningShift,
                availableSlots: slots(for: morningShift),
                tipOfTheWeek: nil
            ),
            StaffMember(
                name: "Andre Silva", role: .coach,
                credentials: ["CSCS", "MS Exercise Science", "USA Weightlifting L2"],
                bio: "Hypertrophy and performance coach. Former collegiate athlete passionate about helping you hit PRs.",
                avatarPlaceholder: "dumbbell.fill",
                shift: afternoonShift,
                availableSlots: slots(for: afternoonShift),
                tipOfTheWeek: nil
            ),
            StaffMember(
                name: "Sarah Martinez", role: .coach,
                credentials: ["ACE-CPT", "Precision Nutrition L1", "HIIT Specialist"],
                bio: "High-energy HIIT & functional fitness coach. Let's build a workout you actually love.",
                avatarPlaceholder: "bolt.heart.fill",
                shift: eveningShift,
                availableSlots: slots(for: eveningShift),
                tipOfTheWeek: nil
            ),
            // Nutritionists
            StaffMember(
                name: "Priya Nair", role: .nutritionist,
                credentials: ["RDN", "MS Clinical Nutrition", "CSSD"],
                bio: "Registered dietitian specializing in sports nutrition and sustainable meal planning.",
                avatarPlaceholder: "leaf.fill",
                shift: morningShift,
                availableSlots: slots(for: morningShift),
                tipOfTheWeek: "Pair your post-workout protein with a handful of berries — the antioxidants speed recovery!"
            ),
            StaffMember(
                name: "Marcus Lee", role: .nutritionist,
                credentials: ["CNS", "BS Nutrition Science", "Gut Health Cert."],
                bio: "Certified nutrition specialist focused on gut health and anti-inflammatory eating.",
                avatarPlaceholder: "carrot.fill",
                shift: afternoonShift,
                availableSlots: slots(for: afternoonShift),
                tipOfTheWeek: "Add fermented foods like kimchi or yogurt to one meal a day for better digestion."
            ),
            StaffMember(
                name: "Elena Torres", role: .nutritionist,
                credentials: ["RD", "Certified Diabetes Educator", "Plant-Based Cert."],
                bio: "Plant-forward nutrition expert. Making healthy eating simple, affordable, and delicious.",
                avatarPlaceholder: "fork.knife",
                shift: eveningShift,
                availableSlots: slots(for: eveningShift),
                tipOfTheWeek: "Prep overnight oats on Sunday night — grab-and-go fuel for your Monday morning workout."
            )
        ]
        
        // MARK: – Meal Suggestions (Eat Smart Delivery)
        self.mealSuggestions = [
            MealSuggestion(name: "Chicken Protein Bowl", restaurant: "Cava", price: 12.49, tags: ["High Protein", "Gluten-Free"], imagePlaceholder: "takeoutbag.and.cup.and.straw.fill", previouslyOrdered: true, nutritionistRecommended: true, nutritionistName: "Priya Nair"),
            MealSuggestion(name: "Vegetarian Power Bowl", restaurant: "Life Alive", price: 14.95, tags: ["Vegetarian", "Organic"], imagePlaceholder: "leaf.circle.fill", previouslyOrdered: false, nutritionistRecommended: true, nutritionistName: "Elena Torres"),
            MealSuggestion(name: "Grilled Salmon Plate", restaurant: "Sweetgreen", price: 15.25, tags: ["Omega-3", "Low Sodium"], imagePlaceholder: "fish.fill", previouslyOrdered: true, nutritionistRecommended: false),
            MealSuggestion(name: "Turkey & Avocado Wrap", restaurant: "Dig", price: 11.99, tags: ["High Protein", "Low Carb"], imagePlaceholder: "burrito.fill", previouslyOrdered: false, nutritionistRecommended: true, nutritionistName: "Marcus Lee"),
            MealSuggestion(name: "Açaí Recovery Bowl", restaurant: "Pressed Juicery", price: 10.50, tags: ["Antioxidants", "Vegan"], imagePlaceholder: "cup.and.saucer.fill", previouslyOrdered: false, nutritionistRecommended: false),
            MealSuggestion(name: "Mediterranean Grain Bowl", restaurant: "Cava", price: 13.25, tags: ["Vegetarian", "Low Sodium"], imagePlaceholder: "takeoutbag.and.cup.and.straw.fill", previouslyOrdered: false, nutritionistRecommended: true, nutritionistName: "Priya Nair")
        ]
        
        // MARK: – Quick Recipes (15-Min Meals)
        self.quickRecipes = [
            QuickRecipe(title: "Protein Overnight Oats", prepTime: "5 min + overnight", calories: 420, protein: 32, tags: ["High Protein", "Meal Prep"], ingredients: ["Oats", "Protein powder", "Greek yogurt", "Banana", "Almond milk"], imagePlaceholder: "takeoutbag.and.cup.and.straw.fill"),
            QuickRecipe(title: "Chicken Stir-Fry", prepTime: "12 min", calories: 380, protein: 35, tags: ["High Protein", "Low Carb"], ingredients: ["Chicken breast", "Broccoli", "Bell pepper", "Soy sauce", "Sesame oil"], imagePlaceholder: "frying.pan.fill"),
            QuickRecipe(title: "Greek Yogurt Parfait", prepTime: "5 min", calories: 310, protein: 28, tags: ["Quick", "High Protein"], ingredients: ["Greek yogurt", "Granola", "Mixed berries", "Honey", "Chia seeds"], imagePlaceholder: "cup.and.saucer.fill"),
            QuickRecipe(title: "Avocado Tuna Salad", prepTime: "10 min", calories: 350, protein: 30, tags: ["Low Carb", "Omega-3"], ingredients: ["Canned tuna", "Avocado", "Lemon", "Red onion", "Mixed greens"], imagePlaceholder: "leaf.fill"),
            QuickRecipe(title: "Egg & Veggie Scramble", prepTime: "8 min", calories: 290, protein: 24, tags: ["Low Carb", "Quick"], ingredients: ["Eggs", "Spinach", "Tomatoes", "Feta", "Olive oil"], imagePlaceholder: "frying.pan")
        ]
        
        self.bookedSessions = []
        
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

    // MARK: – API Integration

    /// Load feed + conversations from the backend.
    @MainActor
    func loadFromAPI() async {
        isLoading = true
        loadError = nil

        // Sync profile from authenticated user
        if let user = AuthService.shared.currentUser {
            profile.name = user.name
            profile.email = user.email
            profile.role = user.role
            profile.buildingName = user.buildingName ?? profile.buildingName
            profile.buildingOwner = user.buildingOwner ?? profile.buildingOwner
        }

        let api = APIClient.shared

        // Fetch feed — always replace with server data
        do {
            let posts: [Post] = try await api.request(.get, path: "/feed")
            feed = posts
        } catch {
            print("[AppStore] Feed fetch failed: \(error.localizedDescription)")
            loadError = error.localizedDescription
        }

        // Fetch conversations — always replace with server data
        do {
            let convos: [Conversation] = try await api.request(.get, path: "/conversations")
            conversations = convos
        } catch {
            print("[AppStore] Conversations fetch failed: \(error.localizedDescription)")
        }

        // Fetch friends from server
        do {
            let response: [FriendResponse] = try await api.request(.get, path: "/friends")
            friends = response.map { $0.toFriendProfile() }
        } catch {
            print("[AppStore] Friends fetch failed: \(error.localizedDescription)")
        }

        // Fetch discoverable users
        do {
            let users: [UserPublic] = try await api.request(.get, path: "/users/search")
            discoverableFriends = users.map { $0.toFriendProfile() }
        } catch {
            print("[AppStore] Discoverable users fetch failed: \(error.localizedDescription)")
        }

        // Fetch notifications
        do {
            let notifs: [AppNotificationResponse] = try await api.request(.get, path: "/notifications")
            notifications = notifs
        } catch {
            print("[AppStore] Notifications fetch failed: \(error.localizedDescription)")
        }

        // Fetch pending friend requests
        do {
            let reqs: [FriendRequestResponse] = try await api.request(.get, path: "/friends/requests")
            friendRequests = reqs
        } catch {
            print("[AppStore] Friend requests fetch failed: \(error.localizedDescription)")
        }

        isLoading = false
    }

    /// Pull-to-refresh for the feed.
    @MainActor
    func refreshFeed() async {
        let api = APIClient.shared
        do {
            let posts: [Post] = try await api.request(.get, path: "/feed")
            feed = posts
        } catch {
            print("[AppStore] Feed refresh failed: \(error.localizedDescription)")
        }
    }

    /// Pull-to-refresh for conversations.
    @MainActor
    func refreshConversations() async {
        let api = APIClient.shared
        do {
            let convos: [Conversation] = try await api.request(.get, path: "/conversations")
            conversations = convos
        } catch {
            print("[AppStore] Conversations refresh failed: \(error.localizedDescription)")
        }
    }

    // MARK: – Friends (API-backed)

    /// Load current accepted friends from the server.
    @MainActor
    func loadFriends() async {
        do {
            let response: [FriendResponse] = try await APIClient.shared.request(.get, path: "/friends")
            friends = response.map { $0.toFriendProfile() }
        } catch {
            print("[AppStore] Load friends failed: \(error.localizedDescription)")
        }
    }

    /// Search for discoverable users (not yet friends).
    @MainActor
    func loadDiscoverableUsers(query: String = "") async {
        var path = "/users/search"
        if !query.isEmpty {
            let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
            path += "?q=\(encoded)"
        }
        do {
            let users: [UserPublic] = try await APIClient.shared.request(.get, path: path)
            discoverableFriends = users.map { $0.toFriendProfile() }
        } catch {
            print("[AppStore] Load discoverable users failed: \(error.localizedDescription)")
        }
    }

    /// Send a friend request by scanning a QR code or entering a user UUID.
    /// The friend shows up on the other person's side as a pending request.
    @MainActor
    @discardableResult
    func addFriendByCode(_ code: String) async throws -> FriendProfile {
        struct AddFriendBody: Encodable {
            let friendCode: String
        }
        let response: FriendResponse = try await APIClient.shared.request(
            .post,
            path: "/friends",
            body: AddFriendBody(friendCode: code)
        )
        let newFriend = response.toFriendProfile()
        // Remove from discoverable list
        discoverableFriends.removeAll { $0.userID == newFriend.userID }
        return newFriend
    }

    // MARK: – Friend Requests (API-backed)

    /// Load pending incoming friend requests.
    @MainActor
    func loadFriendRequests() async {
        do {
            let requests: [FriendRequestResponse] = try await APIClient.shared.request(.get, path: "/friends/requests")
            friendRequests = requests
        } catch {
            print("[AppStore] Load friend requests failed: \(error.localizedDescription)")
        }
    }

    /// Accept a pending friend request.
    @MainActor
    func acceptFriendRequest(_ request: FriendRequestResponse) async {
        do {
            let accepted: FriendResponse = try await APIClient.shared.request(
                .post,
                path: "/friends/\(request.friendshipId)/accept"
            )
            // Move from requests to friends
            friendRequests.removeAll { $0.friendshipId == request.friendshipId }
            let newFriend = accepted.toFriendProfile()
            if !friends.contains(where: { $0.userID == newFriend.userID }) {
                friends.append(newFriend)
            }
            // Refresh notifications
            await loadNotifications()
        } catch {
            print("[AppStore] Accept friend request failed: \(error.localizedDescription)")
        }
    }

    /// Decline a pending friend request.
    @MainActor
    func declineFriendRequest(_ request: FriendRequestResponse) async {
        do {
            try await APIClient.shared.requestVoid(.post, path: "/friends/\(request.friendshipId)/decline")
            friendRequests.removeAll { $0.friendshipId == request.friendshipId }
            // Refresh notifications
            await loadNotifications()
        } catch {
            print("[AppStore] Decline friend request failed: \(error.localizedDescription)")
        }
    }

    /// Remove (unfriend) an accepted friend.
    @MainActor
    func removeFriend(_ friendUserId: UUID) async {
        do {
            try await APIClient.shared.requestVoid(.delete, path: "/friends/\(friendUserId)")
            friends.removeAll { $0.userID == friendUserId }
        } catch {
            print("[AppStore] Remove friend failed: \(error.localizedDescription)")
        }
    }

    /// Check if a user is currently a friend.
    func isFriend(userId: UUID) -> Bool {
        friends.contains { $0.userID == userId }
    }

    // MARK: – Notifications (API-backed)

    /// Load all notifications from the server.
    @MainActor
    func loadNotifications() async {
        do {
            let response: [AppNotificationResponse] = try await APIClient.shared.request(.get, path: "/notifications")
            notifications = response
        } catch {
            print("[AppStore] Load notifications failed: \(error.localizedDescription)")
        }
    }

    /// Number of unread notifications (for badge display).
    var unreadNotificationCount: Int {
        notifications.filter { !$0.isRead }.count + friendRequests.count
    }

    /// Mark all notifications as read.
    @MainActor
    func markAllNotificationsRead() async {
        do {
            try await APIClient.shared.requestVoid(.post, path: "/notifications/read-all")
            for i in notifications.indices {
                notifications[i].isRead = true
            }
        } catch {
            print("[AppStore] Mark-all-read failed: \(error.localizedDescription)")
        }
    }

    func persist() {
        let snap = Snapshot(profile: profile, credits: credits, trainers: trainers, groups: groups, feed: feed, chat: chat)
        Persistence.save(snap, to: filename)
    }

    // MARK: – Staff Helpers

    /// The coach currently on shift right now.
    var currentCoach: StaffMember? {
        let hour = Calendar.current.component(.hour, from: Date())
        return staffMembers.first { $0.role == .coach && $0.shift.startHour <= hour && hour < $0.shift.endHour }
            ?? staffMembers.first { $0.role == .coach }
    }

    /// The nutritionist currently on shift right now.
    var currentNutritionist: StaffMember? {
        let hour = Calendar.current.component(.hour, from: Date())
        return staffMembers.first { $0.role == .nutritionist && $0.shift.startHour <= hour && hour < $0.shift.endHour }
            ?? staffMembers.first { $0.role == .nutritionist }
    }

    /// All coaches with shifts today.
    var todaysCoaches: [StaffMember] {
        staffMembers.filter { $0.role == .coach }
    }

    /// All nutritionists with shifts today.
    var todaysNutritionists: [StaffMember] {
        staffMembers.filter { $0.role == .nutritionist }
    }

    /// Book a session and add to schedule.
    @MainActor
    func bookSession(staff: StaffMember, date: Date, duration: Int = 60) {
        let session = BookedSession(
            staffName: staff.name,
            staffRole: staff.role,
            date: date,
            durationMinutes: duration,
            location: "Echelon Gym"
        )
        bookedSessions.append(session)
        earnCredits(staff.role == .coach ? 10 : 5)
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

    // MARK: – Community / Group Helper

    /// Look up the community name that contains a given group.
    func communityForGroup(_ groupName: String) -> String {
        for community in communities {
            if community.groups.contains(where: { $0.name == groupName }) {
                return community.name
            }
        }
        return ""
    }

    // MARK: – Post Creation (API-backed)

    @MainActor
    func addPost(groupName: String, text: String, communityName: String = "") async {
        let community = communityName.isEmpty ? communityForGroup(groupName) : communityName

        struct CreatePostBody: Encodable {
            let groupName: String
            let communityName: String
            let text: String
        }

        let body = CreatePostBody(groupName: groupName, communityName: community, text: text)

        do {
            let serverPost: Post = try await APIClient.shared.request(.post, path: "/feed", body: body)
            feed.insert(serverPost, at: 0)
        } catch {
            // Fallback to local-only post so the UI still responds
            let p = Post(groupName: groupName, communityName: community, author: profile.name, text: text, timestamp: Date())
            feed.insert(p, at: 0)
            print("[AppStore] Post API failed, created locally: \(error.localizedDescription)")
        }
        persist()
    }

    // MARK: – Chat Message (API-backed)

    /// Delete a conversation (per-user soft delete). Only removes it from this user's view.
    @MainActor
    func deleteConversation(_ conversationId: UUID) async {
        // Optimistic local removal
        conversations.removeAll { $0.id == conversationId }

        do {
            try await APIClient.shared.requestVoid(.delete, path: "/conversations/\(conversationId)")
        } catch {
            print("[AppStore] Delete conversation failed: \(error.localizedDescription)")
            // Refresh to restore if backend failed
            await refreshConversations()
        }
    }

    /// Delete a single message (per-user soft delete). Only removes it from this user's view.
    @MainActor
    func deleteMessage(_ messageId: UUID, in conversationId: UUID) async {
        // Optimistic local removal
        if let idx = conversations.firstIndex(where: { $0.id == conversationId }) {
            conversations[idx].messages.removeAll { $0.id == messageId }
        }

        do {
            try await APIClient.shared.requestVoid(.delete, path: "/conversations/\(conversationId)/messages/\(messageId)")
        } catch {
            print("[AppStore] Delete message failed: \(error.localizedDescription)")
            // Refresh to restore if backend failed
            await refreshMessages(for: conversationId)
        }
    }

    /// Fetch latest messages for a specific conversation from the server.
    @MainActor
    func refreshMessages(for conversationId: UUID) async {
        do {
            let msgs: [ChatMessage] = try await APIClient.shared.request(
                .get,
                path: "/conversations/\(conversationId)/messages"
            )
            if let index = conversations.firstIndex(where: { $0.id == conversationId }) {
                conversations[index].messages = msgs
                if let lastMsg = msgs.last {
                    conversations[index].lastMessage = lastMsg.text
                    conversations[index].lastMessageTime = lastMsg.timestamp
                }
            }
        } catch {
            print("[AppStore] Refresh messages failed: \(error.localizedDescription)")
        }
    }

    @MainActor
    func addChatMessage(to conversationId: UUID, text: String) async {
        guard let index = conversations.firstIndex(where: { $0.id == conversationId }) else { return }

        // Optimistic local insert for instant feedback
        let m = ChatMessage(from: "You", text: text, timestamp: Date(), isMe: true)
        conversations[index].messages.append(m)
        conversations[index].lastMessage = text
        conversations[index].lastMessageTime = Date()
        let updated = conversations.remove(at: index)
        conversations.insert(updated, at: 0)
        persist()

        // Sync to backend
        struct SendMessageBody: Encodable {
            let text: String
        }

        do {
            let _: ChatMessage = try await APIClient.shared.request(
                .post,
                path: "/conversations/\(conversationId)/messages",
                body: SendMessageBody(text: text)
            )
        } catch {
            print("[AppStore] Message API sync failed: \(error.localizedDescription)")
        }
    }

    // MARK: – Create Conversation (API-backed)

    /// Find an existing conversation with a friend, or create a new empty one.
    @MainActor
    func getOrCreateConversation(with friend: FriendProfile) async -> Conversation {
        // Check if conversation already exists for this contact
        if let existing = conversations.first(where: { convo in
            convo.contactUserId == friend.userID || convo.contactName == friend.name
        }) {
            return existing
        }

        struct CreateConversationBody: Encodable {
            let contactName: String
            let contactUserId: UUID?
        }

        do {
            let convo: Conversation = try await APIClient.shared.request(
                .post,
                path: "/conversations",
                body: CreateConversationBody(contactName: friend.name, contactUserId: friend.userID)
            )
            conversations.insert(convo, at: 0)
            return convo
        } catch {
            // Local fallback
            let newConversation = Conversation(
                contactName: friend.name,
                contactUserId: friend.userID,
                lastMessage: "",
                lastMessageTime: Date(),
                unreadCount: 0,
                messages: []
            )
            conversations.insert(newConversation, at: 0)
            print("[AppStore] Create conversation API failed: \(error.localizedDescription)")
            return newConversation
        }
    }

    @MainActor
    func findOrCreateConversation(with contactName: String, initialMessage: String) async {
        if let existing = conversations.first(where: { $0.contactName == contactName }) {
            await addChatMessage(to: existing.id, text: initialMessage)
        } else {
            struct CreateConversationBody: Encodable {
                let contactName: String
                let initialMessage: String
            }

            do {
                let convo: Conversation = try await APIClient.shared.request(
                    .post,
                    path: "/conversations",
                    body: CreateConversationBody(contactName: contactName, initialMessage: initialMessage)
                )
                conversations.insert(convo, at: 0)
            } catch {
                // Local fallback
                let message = ChatMessage(from: "You", text: initialMessage, timestamp: Date(), isMe: true)
                let newConversation = Conversation(
                    contactName: contactName,
                    lastMessage: initialMessage,
                    lastMessageTime: Date(),
                    unreadCount: 0,
                    messages: [message]
                )
                conversations.insert(newConversation, at: 0)
                print("[AppStore] Create conversation API failed: \(error.localizedDescription)")
            }
            persist()
        }
    }

    // MARK: – Session Reset

    /// Clear user-specific data when logging out so the next session starts clean.
    @MainActor
    func resetForNewSession() {
        feed = []
        conversations = [];
        friends = [];
        discoverableFriends = [];
        chat = [];
        notifications = [];
        friendRequests = [];
        profile = UserProfile(name: "", email: "", role: "Member")
        credits = HabitCredits(current: 0, goal: 100)
        isLoading = false
        loadError = nil
        persist()  // overwrite file so next launch doesn't restore stale data
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
    case home, coaching, nutrition, community, rewards
}
