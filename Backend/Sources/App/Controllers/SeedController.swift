// SeedController.swift
// EliteProAI Backend
//
// Seeds demo data for the authenticated user.
// POST /seed — creates sample feed posts and conversations.

import Vapor
import Fluent

struct SeedController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.post("seed", use: seed)
    }

    struct SeedResponse: Content {
        let postsCreated: Int
        let conversationsCreated: Int
        let messagesCreated: Int
    }

    func seed(req: Request) async throws -> SeedResponse {
        let payload = try req.auth.require(UserJWTPayload.self)
        guard let userId = UUID(uuidString: payload.sub.value),
              let user = try await User.find(userId, on: req.db) else {
            throw Abort(.notFound)
        }

        // Check if already seeded (has any posts)
        let existingPosts = try await FeedPost.query(on: req.db).count()
        if existingPosts > 0 {
            throw Abort(.conflict, reason: "Data already seeded. Delete and re-migrate to re-seed.")
        }

        var postsCreated = 0
        var conversationsCreated = 0
        var messagesCreated = 0

        // ── Seed Feed Posts ──

        let posts: [(group: String, community: String, author: String, text: String, img: String?, ago: TimeInterval)] = [
            ("Seaport Tower — Residents", "Echelon", "Nina", "Anyone want to do a 7am mobility session tomorrow in the gym?", nil, 60*12),
            ("Pickle Ball Club", "Echelon", "Jake R.", "The outdoor pickle ball court just opened. I'm making reservations for Sunday. Who's in?", "sportscourt", 60*5),
            ("Seaport Tower — Residents", "Echelon", "Dan K.", "The rooftop gym hours are extended through March. 5AM-11PM.", "building.2", 60*90),
            ("Echelon Early Birds", "Echelon", "Sarah L.", "6am workout crew meets tomorrow! Coffee after 💪", "cup.and.saucer", 60*35),
            ("Echelon Yoga", "Echelon", "Emma T.", "New evening yoga class starting this week - Tuesdays at 7pm", "figure.mind.and.body", 60*180),
            ("Echelon Swimming", "Echelon", "Marcus W.", "Pool is heated and ready! Lap swim schedule posted in lobby.", "figure.pool.swim", 60*240),

            ("Barkan Buildings Fitness", "Barkan Management", "Lisa M.", "All Barkan-managed buildings now have 24/7 gym access!", "building.2", 60*150),
            ("Barkan Wellness Program", "Barkan Management", "David P.", "New wellness program launches next month across all Barkan properties 🎉", "heart.text.square", 60*300),
            ("Barkan Community Events", "Barkan Management", "Rachel K.", "Inter-building fitness challenge starting soon! Which building will win?", "trophy", 60*420),

            ("Beginner Lifting", "Seaport", "Coach Jason", "Tip: track 3 numbers weekly — squat, hinge, and press volume. Keep it simple.", nil, 60*110),
            ("Seaport Runners", "Seaport", "Chris B.", "Harbor run tomorrow at sunrise 🌅 Meet at the pier!", "figure.run", 60*65),
            ("Seaport CrossFit", "Seaport", "Alex R.", "WOD: 21-15-9 Thrusters and Pull-ups. Who's joining?", "figure.strengthtraining.traditional", 60*140),
            ("Seaport Beach Volleyball", "Seaport", "Jordan M.", "Beach volleyball this weekend! All skill levels welcome 🏐", nil, 60*360),
            ("Seaport Nutrition Club", "Seaport", "Priya N.", "Meal prep workshop next Sunday - learn to prep a week's worth of healthy meals!", "fork.knife", 60*480),

            ("Back Bay Running", "Boston", "Sam", "5k easy pace this Saturday. Meet at the reservoir 9:30.", "figure.run", 60*45),
            ("Yoga Flow", "Boston", "Mei", "Sunday morning flow at the park — 8 AM, all levels welcome!", "leaf", 60*22),
            ("Boston Cycling Club", "Boston", "Tyler J.", "40-mile ride along the Charles this Sunday. Fast-paced group!", "bicycle", 60*78),
            ("Boston Boxing", "Boston", "Amanda L.", "Beginner boxing class tonight at 6pm. Gloves provided!", "figure.boxing", 60*8),
            ("Boston Hiking Group", "Boston", "Kevin H.", "Blue Hills hike this Saturday morning. Moderate difficulty, 4 miles.", "figure.hiking", 60*270),

            ("Massachusetts Runners", "Massachusetts", "Tom H.", "Spring marathon training starts next week. Join us!", "figure.run", 60*200),
            ("Mass Fitness Challenge", "Massachusetts", "Patricia G.", "Statewide fitness challenge - 10,000 people signed up so far! 🏃‍♀️", "person.2.fill", 60*390),

            ("National Fitness Movement", "USA", "Coach Taylor", "National fitness month is coming up! What are your goals? 🇺🇸", "flag", 60*810),
            ("USA Wellness Summit", "USA", "Dr. Martinez", "Virtual wellness summit next week - free registration!", "video", 60*900),
        ]

        for p in posts {
            let post = FeedPost(
                authorID: userId,
                authorName: p.author,
                groupName: p.group,
                communityName: p.community,
                text: p.text,
                imagePlaceholder: p.img
            )
            try await post.save(on: req.db)
            // Backdate the created_at timestamp
            post.createdAt = Date().addingTimeInterval(-p.ago)
            try await post.update(on: req.db)
            postsCreated += 1
        }

        // ── Seed Conversations ──

        struct ConvoSeed {
            let contact: String
            let messages: [(from: String, text: String, ago: TimeInterval, isMe: Bool)]
            let unread: Int
        }

        let convos: [ConvoSeed] = [
            ConvoSeed(contact: "Coach Jason", messages: [
                ("Coach Jason", "Hey \(user.name.components(separatedBy: " ").first ?? "")! How's recovery feeling after last week's sessions?", 60*30, false),
                ("Coach Jason", "I put together a new plan for this week.", 60*28, false),
                ("Coach Jason", "Let me know when you're ready to review it.", 60*25, false),
            ], unread: 2),
            ConvoSeed(contact: "Andre Silva", messages: [
                ("Andre Silva", "Hey! Quick question about depth on squats", 60*240, false),
                ("You", "Go parallel or just below, controlled descent", 60*235, true),
                ("Andre Silva", "Perfect, that's what I needed", 60*230, false),
                ("You", "Send me a form check video if you want", 60*225, true),
                ("Andre Silva", "Thanks for the squat tips yesterday!", 60*120, false),
            ], unread: 0),
            ConvoSeed(contact: "Nina", messages: [
                ("Nina", "Still on for mobility tomorrow morning?", 60*200, false),
                ("You", "Yes! 7am at the tower gym?", 60*195, true),
                ("Nina", "Perfect 🙌", 60*190, false),
                ("Nina", "See you at 7am tomorrow!", 60*180, false),
            ], unread: 0),
            ConvoSeed(contact: "Priya Nair", messages: [
                ("Priya Nair", "How did the nutrition tracking go this week?", 60*60*24, false),
                ("You", "Pretty good, hit protein goals 5/7 days", 60*60*23, true),
                ("Priya Nair", "That's solid progress! Let's adjust your plan", 60*60*22, false),
                ("Priya Nair", "I'll send over the meal plan tonight", 60*60*5, false),
            ], unread: 1),
            ConvoSeed(contact: "Sam (Back Bay Running)", messages: [
                ("Sam (Back Bay Running)", "Group run this Saturday - you coming?", 60*60*4, false),
                ("You", "What's the pace?", 60*60*3.5, true),
                ("Sam (Back Bay Running)", "Easy 5k, about 9-10 min/mile", 60*60*3, false),
                ("You", "Count me in for Saturday's 5k!", 60*60*2, true),
            ], unread: 0),
        ]

        for cs in convos {
            let lastMsg = cs.messages.last!
            let conversation = ChatConversation(
                userID: userId,
                contactName: cs.contact,
                lastMessage: lastMsg.text,
                lastMessageTime: Date().addingTimeInterval(-lastMsg.ago),
                unreadCount: cs.unread
            )
            try await conversation.save(on: req.db)
            conversationsCreated += 1

            let convoId = try conversation.requireID()
            for m in cs.messages {
                let msg = ChatMsg(
                    conversationID: convoId,
                    senderName: m.from,
                    senderUserID: m.isMe ? userId : nil,
                    text: m.text,
                    isFromUser: m.isMe
                )
                try await msg.save(on: req.db)
                // Backdate
                msg.createdAt = Date().addingTimeInterval(-m.ago)
                try await msg.update(on: req.db)
                messagesCreated += 1
            }
        }

        return SeedResponse(
            postsCreated: postsCreated,
            conversationsCreated: conversationsCreated,
            messagesCreated: messagesCreated
        )
    }
}
