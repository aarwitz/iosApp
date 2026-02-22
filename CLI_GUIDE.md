# EliteProAI — CLI Setup & API Testing Guide

> Full command-line walkthrough from zero to testing every endpoint.

---

## How the Pipeline Works

```
Terminal (curl)
     │
     ▼
┌──────────────────────────────────────────────────────────────┐
│  Vapor Server  (localhost:8080)                              │
│                                                              │
│  Request comes in ──▶ Middleware stack:                       │
│                        1. CORS (adds headers)                │
│                        2. ErrorMiddleware (catches throws)    │
│                                                              │
│  Route matching:                                             │
│    /health               → plain handler (no auth)           │
│    /api/v1/auth/*        → AuthController (no auth)          │
│    /api/v1/users/*       → JWTAuthMiddleware → UsersController│
│    /api/v1/auth/me       → JWTAuthMiddleware → AuthController │
│    /api/v1/auth/change-password → JWTAuthMiddleware           │
│                                                              │
│  JWTAuthMiddleware:                                          │
│    1. Reads "Authorization: Bearer <token>" header           │
│    2. Verifies signature using HS256 + JWT_SECRET            │
│    3. Checks expiration (15 min TTL)                         │
│    4. Attaches user identity to request                      │
│    5. If anything fails → 401 Unauthorized                   │
│                                                              │
│  Controller logic ──▶ Fluent ORM ──▶ PostgreSQL              │
└──────────────────────────────────────────────────────────────┘
                                          │
                                          ▼
                                  ┌──────────────┐
                                  │  PostgreSQL   │
                                  │  (Docker)     │
                                  │  Port 5432    │
                                  └──────────────┘
```

**Key concept:** Public routes (register, login, refresh, logout, forgot-password) don't need
a token. Protected routes (me, change-password, users/*) require a valid JWT in the
`Authorization: Bearer <token>` header. Tokens expire after **15 minutes** — use the
refresh endpoint to get a new one.

---

## Step 0: Prerequisites

```bash
# Make sure Docker is installed and running
docker --version
# → Docker version 24.x or later

# Make sure Swift is available
swift --version
# → Apple Swift version 5.9+ or 6.0+
```

---

## Step 1: Start PostgreSQL

```bash
cd /Users/aarwitz/repos/EliteProAIDemo/Backend

# Start the Postgres container in the background
docker-compose up -d

# Verify it's running
docker ps
# You should see "backend-db-1" with status "Up ... (healthy)"
# Port 5432 mapped to localhost
```

**What this does:** Launches a PostgreSQL 16 container with:
- User: `eliteproai`
- Password: `password`
- Database: `eliteproai_dev`
- Data persisted in a Docker volume (survives restarts)

```bash
# To stop Postgres later:
docker-compose down

# To stop AND wipe all data:
docker-compose down -v
```

---

## Step 2: Configure Environment

```bash
# Copy the template (skip if you already have .env)
cp .env.example .env

# Verify contents
cat .env
```

The defaults work for local development. In production you'd change `JWT_SECRET` to a long random string.

---

## Step 3: Build & Run the Server

```bash
# Build (first time takes ~30-60s to compile dependencies)
swift build

# Run the server
swift run
```

You should see output like:
```
[ NOTICE ] Server starting on http://127.0.0.1:8080
```

The server auto-runs database migrations on first boot (creates `users` and `refresh_tokens` tables).

> **Tip:** Leave this terminal running. Open a **new terminal tab** for the curl commands below.

---

## Step 4: Health Check

```bash
curl -s http://localhost:8080/health | python3 -m json.tool
```

Expected:
```json
{
    "status": "ok"
}
```

If this fails, the server isn't running — check the terminal where you ran `swift run`.

---

## Step 5: Register a User

```bash
curl -s -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Aaron Witz",
    "email": "aaron@eliteproai.com",
    "password": "MySecurePass123!",
    "buildingName": "Luxury Tower A"
  }' | python3 -m json.tool
```

Expected response:
```json
{
    "accessToken": "eyJhbGciOiJIUzI1NiI...",
    "refreshToken": "abc123base64string==",
    "expiresIn": 900,
    "user": {
        "id": "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX",
        "name": "Aaron Witz",
        "email": "aaron@eliteproai.com",
        "buildingName": "Luxury Tower A",
        "role": "Member"
    }
}
```

**What happened behind the scenes:**
1. Server validated input (name not empty, valid email, password ≥ 8 chars)
2. Checked no existing user has that email
3. Hashed password with Bcrypt (12 rounds)
4. Saved user to `users` table
5. Generated a JWT access token (15 min TTL) signed with HS256
6. Generated a random opaque refresh token (30 day TTL), saved to `refresh_tokens` table
7. Returned both tokens + user profile

---

## Step 6: Save Your Tokens

After register or login, save the tokens to shell variables so you can reuse them:

```bash
# Copy the accessToken value from the response above:
export TOKEN="eyJhbGciOiJIUzI1NiI..."

# Copy the refreshToken value too:
export REFRESH="abc123base64string=="
```

> **Important:** `$TOKEN` only exists in the terminal session where you ran `export`.
> If you open a new tab, you need to export it again. This is why your earlier
> `curl` returned "Missing authorization token" — the variable was set in a
> different terminal.

**Pro tip — capture tokens automatically:**

```bash
# Register and capture tokens in one shot:
RESPONSE=$(curl -s -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@eliteproai.com",
    "password": "Password123!",
    "buildingName": "Luxury Tower A"
  }')

export TOKEN=$(echo $RESPONSE | python3 -c "import sys,json; print(json.load(sys.stdin)['accessToken'])")
export REFRESH=$(echo $RESPONSE | python3 -c "import sys,json; print(json.load(sys.stdin)['refreshToken'])")

echo "Access token: ${TOKEN:0:30}..."
echo "Refresh token: ${REFRESH:0:20}..."
```

---

## Step 7: Login (Alternative to Register)

If the user already exists:

```bash
RESPONSE=$(curl -s -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "aaron@eliteproai.com",
    "password": "MySecurePass123!"
  }')

export TOKEN=$(echo $RESPONSE | python3 -c "import sys,json; print(json.load(sys.stdin)['accessToken'])")
export REFRESH=$(echo $RESPONSE | python3 -c "import sys,json; print(json.load(sys.stdin)['refreshToken'])")

echo $RESPONSE | python3 -m json.tool
```

**Error cases:**

```bash
# Wrong password:
curl -s -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "aaron@eliteproai.com", "password": "wrong"}' | python3 -m json.tool
# → {"error": true, "reason": "Invalid email or password."}

# Non-existent email:
curl -s -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "nobody@test.com", "password": "whatever"}' | python3 -m json.tool
# → {"error": true, "reason": "Invalid email or password."}  (same message — no email enumeration)
```

---

## Step 8: Access Protected Endpoints

These all require `Authorization: Bearer $TOKEN`:

### Get My Profile

```bash
curl -s http://localhost:8080/api/v1/users/me \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool
```

Expected:
```json
{
    "id": "...",
    "name": "Aaron Witz",
    "email": "aaron@eliteproai.com",
    "buildingName": "Luxury Tower A",
    "role": "Member"
}
```

### Get My Profile (via Auth controller — same result)

```bash
curl -s http://localhost:8080/api/v1/auth/me \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool
```

### Update My Profile

```bash
curl -s -X PATCH http://localhost:8080/api/v1/users/me \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Aaron W.",
    "buildingName": "Skyline Residences"
  }' | python3 -m json.tool
```

Only include the fields you want to change. All fields are optional.

### Change Password

```bash
curl -s -X POST http://localhost:8080/api/v1/auth/change-password \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "currentPassword": "MySecurePass123!",
    "newPassword": "EvenMoreSecure456!"
  }'
# → 200 OK (empty body)
```

---

## Step 9: Token Refresh

Access tokens expire after **15 minutes**. When you get a 401, use the refresh token to get new ones:

```bash
RESPONSE=$(curl -s -X POST http://localhost:8080/api/v1/auth/refresh \
  -H "Content-Type: application/json" \
  -d "{\"refreshToken\": \"$REFRESH\"}")

# Update your tokens (old refresh token is now revoked — this is "token rotation")
export TOKEN=$(echo $RESPONSE | python3 -c "import sys,json; print(json.load(sys.stdin)['accessToken'])")
export REFRESH=$(echo $RESPONSE | python3 -c "import sys,json; print(json.load(sys.stdin)['refreshToken'])")

echo $RESPONSE | python3 -m json.tool
```

**How token rotation works:**
1. You send your refresh token
2. Server marks the old refresh token as **revoked** (can never be used again)
3. Server issues a brand new access token + a brand new refresh token
4. You must use the **new** refresh token next time

This prevents replay attacks — if someone steals an old refresh token, it's already dead.

---

## Step 10: Logout

```bash
curl -s -X POST http://localhost:8080/api/v1/auth/logout \
  -H "Content-Type: application/json" \
  -d "{\"refreshToken\": \"$REFRESH\"}"
# → 204 No Content

# Now the refresh token is revoked. The access token still works until it
# expires (up to 15 min), but the client (iOS app) deletes it from Keychain.
```

---

## Step 11: Delete Account

```bash
curl -s -X DELETE http://localhost:8080/api/v1/users/me \
  -H "Authorization: Bearer $TOKEN"
# → 204 No Content

# User is gone. All their refresh tokens are revoked.
# Trying to use the token again will fail with 404 (user not found).
```

---

## Step 12: Forgot Password (Stub)

This endpoint exists but doesn't send real emails yet — it always returns 200 OK to prevent email enumeration:

```bash
curl -s -X POST http://localhost:8080/api/v1/auth/forgot-password \
  -H "Content-Type: application/json" \
  -d '{"email": "aaron@eliteproai.com"}'
# → 200 OK (always, even if email doesn't exist)
```

---

## Common Errors & What They Mean

| Error | Cause | Fix |
|-------|-------|-----|
| `"Missing authorization token."` | No `Authorization` header, or `$TOKEN` is empty | Run `echo $TOKEN` — if blank, re-login and export |
| `"Invalid or expired token."` | Token signature bad or TTL exceeded (>15 min) | Refresh the token (Step 9) or login again |
| `"Invalid email or password."` | Wrong credentials | Check email/password |
| `"An account with this email already exists."` | Duplicate registration | Login instead, or use a different email |
| `"Refresh token expired or revoked."` | Token already used (rotation) or >30 days old | Login again from scratch |
| `"User not found."` | Account was deleted | Register again |
| Connection refused | Server not running | Run `swift run` in the Backend directory |
| Connection refused on :5432 | Postgres not running | Run `docker-compose up -d` |

---

## Validation Rules

| Field | Rule |
|-------|------|
| `name` | Cannot be empty |
| `email` | Must be valid email format, stored lowercase, must be unique |
| `password` | Minimum 8 characters |
| `buildingName` | Optional |
| `buildingOwner` | Optional |

---

## Quick Reference: All Endpoints

| Method | Path | Auth? | Body | Returns |
|--------|------|-------|------|---------|
| `GET` | `/health` | No | — | `{"status":"ok"}` |
| `POST` | `/api/v1/auth/register` | No | name, email, password, buildingName? | tokens + user |
| `POST` | `/api/v1/auth/login` | No | email, password | tokens + user |
| `POST` | `/api/v1/auth/refresh` | No | refreshToken | new tokens + user |
| `POST` | `/api/v1/auth/logout` | No | refreshToken | 204 |
| `POST` | `/api/v1/auth/forgot-password` | No | email | 200 |
| `POST` | `/api/v1/auth/reset-password` | No | token, newPassword | 501 (not implemented) |
| `GET` | `/api/v1/auth/me` | **Yes** | — | user profile |
| `POST` | `/api/v1/auth/change-password` | **Yes** | currentPassword, newPassword | 200 |
| `GET` | `/api/v1/users/me` | **Yes** | — | user profile |
| `PATCH` | `/api/v1/users/me` | **Yes** | name?, email?, buildingName?, buildingOwner? | updated user |
| `DELETE` | `/api/v1/users/me` | **Yes** | — | 204 |

---

## Full Copy-Paste Quick Start

```bash
# ── Terminal 1: Start everything ──
cd /Users/aarwitz/repos/EliteProAIDemo/Backend
docker-compose up -d
swift run

# ── Terminal 2: Test the API ──
cd /Users/aarwitz/repos/EliteProAIDemo/Backend

# Health check
curl -s http://localhost:8080/health | python3 -m json.tool

# Register
RESPONSE=$(curl -s -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Aaron","email":"aaron@eliteproai.com","password":"Password123!","buildingName":"Luxury Tower A"}')
export TOKEN=$(echo $RESPONSE | python3 -c "import sys,json; print(json.load(sys.stdin)['accessToken'])")
export REFRESH=$(echo $RESPONSE | python3 -c "import sys,json; print(json.load(sys.stdin)['refreshToken'])")
echo $RESPONSE | python3 -m json.tool

# Get profile
curl -s http://localhost:8080/api/v1/users/me -H "Authorization: Bearer $TOKEN" | python3 -m json.tool

# Update profile
curl -s -X PATCH http://localhost:8080/api/v1/users/me \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Aaron W."}' | python3 -m json.tool

# Refresh tokens
RESPONSE=$(curl -s -X POST http://localhost:8080/api/v1/auth/refresh \
  -H "Content-Type: application/json" \
  -d "{\"refreshToken\": \"$REFRESH\"}")
export TOKEN=$(echo $RESPONSE | python3 -c "import sys,json; print(json.load(sys.stdin)['accessToken'])")
export REFRESH=$(echo $RESPONSE | python3 -c "import sys,json; print(json.load(sys.stdin)['refreshToken'])")

# Logout
curl -s -X POST http://localhost:8080/api/v1/auth/logout \
  -H "Content-Type: application/json" \
  -d "{\"refreshToken\": \"$REFRESH\"}"
```

---

## What Happens in the iOS App

When the iOS app connects, `AuthService` automates this exact flow:

1. **`signUp()`** → calls `/auth/register` → stores tokens in iOS Keychain
2. **`login()`** → calls `/auth/login` → stores tokens in Keychain
3. **Every API call** → `APIClient` reads token from Keychain, adds `Authorization: Bearer` header automatically
4. **On 401 response** → `APIClient` calls `/auth/refresh` with the stored refresh token, retries the original request
5. **`logout()`** → calls `/auth/logout` → clears Keychain
6. **Token scheduling** → `AuthService` sets a timer to refresh the token at ~14 minutes (before the 15 min expiry)

So everything you're doing manually with curl, the app does automatically via `Services/AuthService.swift` + `Services/APIClient.swift` + `Services/KeychainManager.swift`.
