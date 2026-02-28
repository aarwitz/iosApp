# EliteProAIDemo — Product Requirements & Marketing Review (MRD)

Last updated: 2026-02-28

## Executive Summary

EliteProAIDemo is a consumer-facing lifestyle and wellness mobile app prototype that bundles coaching, nutrition guidance, community engagement, and local amenity/connectivity features into a single curated experience. The app provides members with a personalized home feed, 1:1 coaching and nutrition check-ins, session booking, meal suggestions and delivery integration, social/community features (posts, stories, groups), a connector/discovery card swipe experience for meeting neighbors, and an earn-and-redeem rewards system.

This MRD summarizes the product purpose, target users, core features, success metrics, UX workflows, technical touchpoints, deliverables, and roadmap items for stakeholder review.

## Purpose & Goals

- Deliver a polished MVP that showcases integrations between wellness coaching, nutrition, social communities, and local services.
- Increase member engagement by offering clear pathways to action: book a session, message a coach, join a group, or redeem credits.
- Demonstrate a cohesive product where behavioral nudges (quotes, tips, quick actions) and social discovery (stories, connector) drive retention.
- Provide a platform for partners (sponsored events, delivery partners, rewards) to appear in-venue.

## Target Users

- Residents of managed communities or buildings who want a centralized wellness & community app.
- Users interested in health coaching and nutrition advice with lightweight social features (stories, small groups).
- Community managers seeking event and amenity discovery tools.

## Key Features (Overview)

Each feature below includes description, UI touchpoints (view/component name), required deliverables, and success criteria.

1. Home Feed — Personalized Daily Hub
   - Description: The main landing experience; greeting, quick status widget (upcoming classes or events), staff carousel (coach/nutritionist), actions, community pulse, and ways to earn credits.
   - UI: `HomeFeedView` (root), components: hero header, `staffCarousel`, `statusWidget`, `todaysActionsSection`, `communityPulseCard`, `waysToEarnSection`.
   - Deliverables: feed refresh, pull-to-refresh, sheet/modal flows for booking and chat, navigation to detailed screens.
   - Success: Daily active users and time-on-home metrics; conversions to booking or chat from feed.

2. Coaching (1:1) Experience
   - Description: Browse coaches, view availability, book sessions, see booked sessions, program recommendations, and coach tips.
   - UI: `CoachingView`, `BookingSessionView`, and coach card component.
   - Deliverables: Carousel of coaches, booking flow, chat sheet/modal, view of booked sessions and WOD (Workout of the Day).
   - Success: Bookings per week, session attendance, messages initiated to coaches.

3. Nutrition Experience
   - Description: Nutritionist carousel, meal suggestions, quick recipes, meal scanner, grocery list, delivery partners, and nutritionist tips.
   - UI: `NutritionView`, `mealScannerSheet`, `groceryListSheet`, nutritionist card.
   - Deliverables: Tag filtering for meals, meal scanner sheet, grocery list exportable view, chat with nutritionist.
   - Success: Meal suggestion engagement, scanner usage, grocery list opens.

4. Rewards & Earning
   - Description: Earn credits through activities, sponsored events, or challenges; redeem credits for rewards.
   - UI: `RewardsView`, `earningOpportunityCard`, `rewardItemCard`, credits overview.
   - Deliverables: Earning opportunity tracking, redemption flow, credit progress visualization.
   - Success: Number of completed opportunities, redemption rate, average credits per user.

5. Community Feed & Groups
   - Description: Community tabs, posts feed, stories, groups discovery, map view of pinned activities and amenities.
   - UI: `CommunityView`, `communityPost`, `friendStoriesSection`, `mapSection`.
   - Deliverables: Post creation, story viewer, group discovery and join flows, map pin interactions.
   - Success: Posts per user, story views, groups joined.

6. Connector (People Discovery)
   - Description: Swipeable card interface to discover nearby or building-based potential friends; includes barcode/QR add-friend flows and match overlay upon mutual interest.
   - UI: `ConnectorView`, `friendCard`, `matchOverlayView`, `barcodeSheet`.
   - Deliverables: Swipe gestures, match modal, friend detail navigation, QR scanner integration.
   - Success: Connections made, QR adds, match acceptance rate.

7. Chat & Conversations
   - Description: Centralized chat list, individual conversation flows, unread counts shown in top-right chat button across tabs.
   - UI: `ChatListView` (navigated from many toolbars), conversation model `Conversation` in code.
   - Deliverables: Navigation to chat list, unread badge logic, message sending/receiving flows.
   - Success: Messages per user, response time, unread backlog.

8. Side Menu & Profile
   - Description: Global navigation menu with profile, challenges, connector, schedule, notifications, bookmarks, and settings shortcuts.
   - UI: `SideMenu`, `SideMenuOverlay`, `MenuRow`.
   - Deliverables: Menu open/close animations, item actions that drive the main navigation state.
   - Success: Menu usage stats and preferred entry points.

9. Challenges & Programs
   - Description: Browse or join community challenges to earn credits and promote healthy competition.
   - UI: `ChallengesView`, `challengeCard`.
   - Deliverables: Category filters, join/continue flows, challenge progress tracking.
   - Success: Challenges joined, challenge completion rate.

10. Bookings & Schedule
    - Description: Book staff sessions, view schedule, and see booked sessions (both coach and nutritionist).
    - UI: `BookingSessionView`, `BookedSession` models, schedule widgets.
    - Deliverables: Slot selection, confirmation, and calendar-style views where applicable.
    - Success: Booking conversion and retention after sessions.

## Representative Workflows (User Journeys)

1. Onboard → Personalize → Engage
   - User signs up / completes profile.
   - App shows `HomeFeedView` with greeting and status widget.
   - User views staff carousel and taps “Message” on a coach → opens chat sheet to start conversation.

2. Book a Coaching Session
   - From `CoachingView` or `HomeFeedView`, user opens a staff card and taps “Book”.
   - `BookingSessionView` shows available slots; user confirms slot → booking stored in `BookedSession` and shown in home/booked sessions.

3. Discover & Connect
   - User navigates to `ConnectorView`, swipes right to show interest in a neighbor.
   - If mutual, `matchOverlayView` appears; users can message or plan an activity.
   - Alternatively use QR `barcodeSheet` to add a friend instantly.

4. Nutrition & Meal Tracking
   - User opens `NutritionView` → filters meals by tag → views meal detail or taps “Scan Meal” to open `mealScannerSheet`.
   - `groceryListSheet` compiles suggested groceries.

5. Earn & Redeem
   - User completes a challenge or sponsored activity → store credits increase.
   - In `RewardsView`, user redeems credits for reward items; UI shows success alert and updates inventory.

## Technical Notes & Data Model Highlights

- Major SwiftUI Views: `HomeFeedView.swift`, `CoachingView.swift`, `NutritionView.swift`, `ConnectorView.swift`, `CommunityView.swift`, `SideMenu.swift`, `ChallengesView.swift`, `RewardsView.swift`.
- Data models are defined in `Models.swift` (profiles, staff, meals, sessions, communities, conversations, rewards).
- App state appears driven by an `AppStore` environment object (observed in view attachments) to centralize profile, staff, community, and conversation data.
- Features use SwiftUI sheets, `NavigationStack`, and modern gesture APIs for swipes and overlays.

## Non-functional Requirements

- Performance: Smooth carousel and swipe animations; page-dots and transient animations must be lightweight.
- Offline: Read-only cached feed and booked session display; booking and chat require connectivity.
- Security/Privacy: Minimal PII in local storage; use Keychain via `KeychainManager` (present in Services). Ensure backend APIs follow secure auth.
- Accessibility: Support Dynamic Type, VoiceOver labels on major interactive items, and color contrast for themes.

## Integrations & Third-Party Services

- Chat backend and push notifications (conversations and unread counts).
- Payment or scheduling backend for bookings (if monetized).
- Meal delivery partners for Eat Smart Delivery links.
- QR/Barcode scanning for friend adds (QRScannerView referenced in attachments).

## Analytics & Success Metrics

- DAU/MAU
- Session length and feature-specific engagement (bookings, chat starts, meals scanned).
- Conversion: Bookings per user, redemptions per user.
- Retention: 7-day/30-day retention post-onboarding.

## Roadmap & Phasing (Proposed)

Phase 1 (MVP):
- Home feed, coaches & nutritionist carousels, booking flow, chat list navigation, rewards overview, community feed read/write, connector swipe UI, side menu navigation.

Phase 2:
- Real chat backend, push notifications, calendar sync for bookings, multi-language support, deeper analytics, sponsor integrations.

Phase 3:
- Monetization: paid sessions, premium content; richer profile discovery; recommended programs driven by ML.

## Deliverables for Stakeholders

- Polished iOS build with core screens implemented: `HomeFeedView`, `CoachingView`, `NutritionView`, `CommunityView`, `ConnectorView`, `RewardsView`.
- Implementation of booking, chat navigation, meal scanning sheet, and rewards redemption flows.
- Documentation: this MRD and a short developer README describing app architecture and `AppStore` contract.

## Risks & Mitigations

- Risk: Chat and booking backends are complex and may delay launch. Mitigation: provide demo-mode flows (complete offline or mocked backend) for early demos.
- Risk: Over-scoped social features. Mitigation: prioritize core engagement paths (book → attend → message) and add community features iteratively.

## Appendix: Component → File Mapping (from provided views)

- Home feed: `EliteProAIDemo 2/Views/HomeFeedView.swift` (`statusWidget`, `staffCarousel`, `todaysActionsSection`)
- Coaching: `EliteProAIDemo 2/Views/CoachingView.swift` (`coachCarousel`, `BookingSessionView`)
- Nutrition: `EliteProAIDemo 2/Views/NutritionView.swift` (`nutritionistCarousel`, `mealScannerSheet`)
- Connector: `EliteProAIDemo 2/Views/ConnectorView.swift` (`friendCard`, swipe logic, `barcodeSheet`)
- Community: `EliteProAIDemo 2/Views/CommunityView.swift` (tabs, `friendStoriesSection`, `mapSection`)
- Side Menu: `EliteProAIDemo 2/Views/SideMenu.swift` (`SideMenu`, `MenuRow`)
- Challenges: `EliteProAIDemo 2/Views/ChallengesView.swift` (`challengeCard`)
- Rewards: `EliteProAIDemo 2/Views/RewardsView.swift` (`earningOpportunityCard`, `rewardItemCard`)
- Models: `EliteProAIDemo 2/Models.swift` (data types referenced throughout)

---

If you’d like, I can (choose one or more):

- Expand this MRD into a shorter investor-facing one-pager.
- Produce a developer README that maps `AppStore` APIs and mock endpoints for the demo flows.
- Create user journey diagrams or Mermaid flowcharts for the booking, connector, and rewards flows.

File created: PRODUCT_MARKETING_DOC.md
