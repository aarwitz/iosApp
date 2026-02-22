# EliteProAI — Production Implementation Roadmap

> Transitioning from demo prototype to production-ready application.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                    iOS App (SwiftUI)                 │
│  ┌──────────┐  ┌──────────┐  ┌───────────────────┐  │
│  │  Views    │  │  AppStore │  │  Services         │  │
│  │  (UI)     │──│  (State) │──│  APIClient        │  │
│  │          │  │          │  │  AuthService       │  │
│  │          │  │          │  │  KeychainManager   │  │
│  └──────────┘  └──────────┘  └────────┬──────────┘  │
└────────────────────────────────────────┼─────────────┘
                                         │ HTTPS/JWT
┌────────────────────────────────────────┼─────────────┐
│                Backend (Swift Vapor)    │             │
│  ┌──────────┐  ┌──────────┐  ┌────────┴──────────┐  │
│  │  Routes   │  │Controllers│  │  Middleware       │  │
│  │  /api/v1  │──│  Auth    │──│  JWT Validation   │  │
│  │          │  │  Users   │  │  CORS             │  │
│  └──────────┘  └──────────┘  └───────────────────┘  │
│                       │                              │
│               ┌───────┴───────┐                      │
│               │  PostgreSQL   │                      │
│               │  (Fluent ORM) │                      │
│               └───────────────┘                      │
└──────────────────────────────────────────────────────┘
```

---

## What Was Built (Phase 0 — Foundation)

### iOS App — New Files

| File | Purpose |
|------|---------|
| `Services/APIClient.swift` | Async/await HTTP client with JWT injection, token refresh, multipart upload |
| `Services/AuthService.swift` | Auth state machine (login, signup, refresh, logout, password change) |
| `Services/KeychainManager.swift` | iOS Keychain wrapper for secure token/credential storage |
| `Views/OnboardingView.swift` | 3-page onboarding carousel for first-time users |
| `Views/LoginView.swift` | Email/password login with social auth placeholders + forgot password |
| `Views/SignUpView.swift` | 3-step signup: credentials → building selection → review |
| `Views/EditProfileView.swift` | Edit profile sheet (name, email, building) syncs to backend |
| `Views/ChangePasswordView.swift` | Authenticated password change with validation |

### iOS App — Modified Files

| File | Changes |
|------|---------|
| `EliteProAIDemoApp.swift` | Auth-gated entry point: onboarding → login → main app |
| `Views/ProfileView.swift` | Added Edit button + sheet presentation |
| `Views/SettingsView.swift` | Real logout, delete account, change password, clear cache |

### Backend (Vapor) — `Backend/`

| File | Purpose |
|------|---------|
| `Package.swift` | SPM manifest: Vapor, Fluent, Postgres, JWT |
| `Sources/App/entrypoint.swift` | Application entry point |
| `Sources/App/configure.swift` | DB, JWT, middleware, migration config |
| `Sources/App/routes.swift` | Route registration (health, auth, users) |
| `Sources/App/Models/User.swift` | User model with Bcrypt, public projection |
| `Sources/App/Models/RefreshToken.swift` | Opaque refresh token for rotation |
| `Sources/App/Models/JWTPayload.swift` | JWT access token payload |
| `Sources/App/Controllers/AuthController.swift` | Register, login, refresh, logout, password reset |
| `Sources/App/Controllers/UsersController.swift` | Profile CRUD, account deletion |
| `Sources/App/Middleware/JWTAuthMiddleware.swift` | Bearer token validation middleware |
| `Sources/App/Migrations/CreateUser.swift` | Users table migration |
| `Sources/App/Migrations/CreateRefreshToken.swift` | Refresh tokens table migration |
| `docker-compose.yml` | Local Postgres via Docker |
| `.env.example` | Environment variable template |

### Test Infrastructure

| File | Purpose |
|------|---------|
| `EliteProAIDemoTests/KeychainManagerTests.swift` | Keychain CRUD, token convenience, edge cases |
| `EliteProAIDemoTests/APIClientTests.swift` | Environment config, error descriptions, decoding |
| `EliteProAIDemoTests/AppStoreTests.swift` | Credits, conversations, posts, rewards, menu logic |
| `EliteProAIDemoTests/ModelTests.swift` | Codable round-trips, community filter logic |
| `EliteProAIDemoUITests/AuthFlowUITests.swift` | Onboarding, login screen, signup navigation |
| `Backend/Tests/AppTests/AuthTests.swift` | Register, login, duplicate email, auth guards |

---

## Xcode Project Setup Required

The new Swift files need to be added to the Xcode project:

1. **Open** `EliteProAIDemo.xcodeproj` in Xcode
2. **Right-click** the `EliteProAIDemo 2` group → "Add Files to..."
3. **Add** the `Services/` folder (APIClient, AuthService, KeychainManager)
4. **Add** the new Views (OnboardingView, LoginView, SignUpView, EditProfileView, ChangePasswordView)
5. **Add test targets** — File → New → Target → Unit Testing Bundle + UI Testing Bundle
6. **Add test files** to respective targets

---

## Next Phases — Implementation Roadmap

### Phase 1: Backend Deployment (Priority: HIGH)
- [x] Install Docker & run `docker-compose up -d` for local Postgres
- [x] Copy `.env.example` → `.env` with real JWT secret
- [x] Run backend: `cd Backend && swift run`
- [x] Test with: `curl http://localhost:8080/health`
- [x] Set up staging server on Railway ✅ `https://backend-production-1013.up.railway.app`
- [x] Update `APIClient.swift` staging URL with Railway domain
- [ ] Configure production Postgres (e.g., Supabase, RDS, Neon)

#### Railway Staging Deployment

Files created for deployment:
- `Backend/Dockerfile` — Multi-stage build (Swift 5.10 → slim Ubuntu runtime)
- `Backend/railway.toml` — Railway build config with health check
- `Backend/.dockerignore` — Excludes build artifacts from Docker context
- `Backend/deploy-railway.sh` — Interactive setup script

```bash
# Quick deploy:
brew install railway
railway login
cd Backend
./deploy-railway.sh

# Or manual:
railway init                    # Create project
railway open                    # Add Postgres via dashboard (+ New → Database → PostgreSQL)
railway variables set JWT_SECRET=$(openssl rand -base64 32)
railway up                      # Build & deploy
railway domain                  # Generate public URL
curl https://YOUR-APP.up.railway.app/health
```

Railway auto-provides `DATABASE_URL` — `configure.swift` reads it automatically.
The Dockerfile builds in release mode with static linking for a minimal ~50MB image.

### Phase 2: Connect iOS ↔ Backend (Priority: HIGH)
- [x] Point `APIClient` development URL to local Vapor server (`localhost:8080/api/v1`)
- [x] Test full auth flow end-to-end (register → login → refresh → logout)
- [x] Configure Vapor JSON encoding to match iOS (`snake_case` + ISO 8601 dates)
- [x] Create backend models + migrations: `FeedPost`, `ChatConversation`, `ChatMsg`
- [x] Create backend controllers: `FeedController`, `ConversationsController`, `SeedController`
- [x] `POST /seed` endpoint populates 23 feed posts + 5 conversations with messages
- [x] Wire `AppStore.loadFromAPI()` — fetches feed + conversations on login
- [x] Sync user profile from `AuthService.currentUser` into `AppStore.profile`
- [x] Add pull-to-refresh to `HomeFeedView` and `ChatListView`
- [x] Graceful fallback: keeps demo data if API calls fail
- [ ] Create backend endpoints for: groups, challenges (future sprint)
- [ ] Add loading spinners / skeleton screens during data fetch

### Phase 3: Data Security Hardening (Priority: HIGH)
- [ ] Enable App Transport Security (ATS) for production HTTPS
- [ ] Certificate pinning for API calls
- [ ] Implement biometric authentication (Face ID / Touch ID) via `LAContext`
- [ ] Add rate limiting on backend auth endpoints
- [ ] Input sanitization and SQL injection prevention (Fluent handles most)
- [ ] Encrypt sensitive local data at rest (beyond Keychain)
- [ ] GDPR compliance: data export, right to deletion

### Phase 4: Profile & Settings Finalization (Priority: MEDIUM)
- [ ] Profile photo upload (camera + photo library → S3/Cloudflare R2)
- [ ] Email verification flow
- [ ] Push notification registration (APNs + backend)
- [ ] Language/localization support
- [ ] Terms of Service / Privacy Policy web views
- [ ] Email preference management
- [ ] Download My Data export endpoint

### Phase 5: Real-Time Features (Priority: MEDIUM)
- [ ] WebSocket chat (replace demo conversations with live messaging)
- [ ] Push notifications for new messages, friend requests, challenges
- [ ] Live activity updates for challenges/credits
- [ ] Background refresh for feed content

### Phase 6: QA & Testing (Priority: HIGH)
- [ ] Add test targets to Xcode project (Unit + UI)
- [ ] Achieve 80%+ code coverage on Services layer
- [ ] Protocol-based dependency injection for testable architecture
- [ ] Mock `APIClient` for offline/unit testing
- [ ] Snapshot tests for critical views (using swift-snapshot-testing)
- [ ] CI/CD pipeline (GitHub Actions: build → test → deploy)
- [ ] Crashlytics / Sentry for production error monitoring
- [ ] TestFlight beta distribution

### Phase 7: Performance & Polish (Priority: LOW)
- [ ] Image caching (Kingfisher or custom)
- [ ] Pagination for feeds, friends, conversations
- [ ] Skeleton loading screens
- [ ] App icon and launch screen finalization
- [ ] Accessibility audit (VoiceOver, Dynamic Type)
- [ ] App Store submission preparation

---

## Running the Backend Locally

```bash
# 1. Start Postgres
cd Backend
docker-compose up -d

# 2. Copy env
cp .env.example .env

# 3. Build & run
swift run

# 4. Test health
curl http://localhost:8080/health
# → {"status":"ok"}

# 5. Register a user
curl -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com","password":"SecurePass123!"}'
```

---

## Tech Stack Summary

| Layer | Technology |
|-------|-----------|
| iOS UI | SwiftUI (iOS 17+) |
| iOS State | ObservableObject + @Published |
| iOS Networking | URLSession + async/await |
| iOS Security | iOS Keychain Services |
| Backend | Swift Vapor 4 |
| Database | PostgreSQL 16 |
| ORM | Fluent |
| Auth | JWT (access) + Opaque tokens (refresh) |
| Password Hashing | Bcrypt |
| Local Dev | Docker Compose |
| Testing | XCTest (iOS) + XCTVapor (backend) |
