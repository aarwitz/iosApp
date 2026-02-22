#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────
# EliteProAI — Railway Deployment Setup
#
# Prerequisites:
#   1. Railway CLI installed:  brew install railway
#   2. Logged in:  railway login
#
# Usage:
#   cd Backend
#   chmod +x deploy-railway.sh
#   ./deploy-railway.sh
# ──────────────────────────────────────────────────────────────
set -euo pipefail

echo "═══════════════════════════════════════════"
echo "  EliteProAI — Railway Deployment Setup"
echo "═══════════════════════════════════════════"
echo ""

# ── Step 1: Check Railway CLI ──
if ! command -v railway &> /dev/null; then
    echo "❌ Railway CLI not found. Install it:"
    echo "   brew install railway"
    exit 1
fi
echo "✅ Railway CLI found: $(railway --version)"

# ── Step 2: Check login ──
if ! railway whoami &> /dev/null 2>&1; then
    echo "🔐 Not logged in. Opening browser for Railway login..."
    railway login
fi
echo "✅ Logged in as: $(railway whoami 2>/dev/null || echo 'authenticated')"

# ── Step 3: Initialize project (or link existing) ──
echo ""
if ! railway status &> /dev/null 2>&1; then
    echo "📦 No Railway project linked. Initializing..."
    echo "   This will create a new project on Railway."
    railway init
else
    echo "✅ Railway project already linked."
fi

# ── Step 4: Link or create a service ──
echo ""
echo "🔗 Linking a service..."
echo "   If prompted, select an existing service or create a new one (e.g. 'backend')."
echo ""
if ! railway service 2>/dev/null; then
    echo ""
    echo "   ℹ️  If no services are listed, Railway will create one on first deploy."
    echo "   We'll continue and deploy — the service gets created automatically."
fi

# ── Step 5: Add Postgres ──
echo ""
echo "🗄️  Next: Add a PostgreSQL database to your Railway project."
echo ""
echo "   1. Open your Railway dashboard:  railway open"
echo "   2. Click '+ New' → 'Database' → 'PostgreSQL'"
echo "   3. In Postgres settings → 'Variables' tab, copy DATABASE_URL"
echo "   4. Go to your backend service → 'Variables' tab"
echo "   5. Add a reference variable: DATABASE_URL = \${{Postgres.DATABASE_URL}}"
echo ""
echo "   (This wires Postgres credentials to your backend service automatically)"
echo ""
read -p "   Press Enter once Postgres is added and DATABASE_URL is referenced..."

# ── Step 6: Set environment variables ──
echo ""
echo "🔑 Setting environment variables..."

# Generate a secure JWT secret
JWT_SECRET=$(openssl rand -base64 32)
echo "   Generated JWT_SECRET: ${JWT_SECRET:0:10}..."

# Try setting variables — may fail if service not linked yet; that's OK
if railway variables set JWT_SECRET="$JWT_SECRET" 2>/dev/null; then
    echo "✅ JWT_SECRET set on service."
else
    echo "⚠️  Could not set variables via CLI."
    echo "   Set them manually in the Railway dashboard → your service → Variables:"
    echo "     JWT_SECRET = $JWT_SECRET"
fi

# ── Step 7: Deploy ──
echo ""
echo "🚀 Deploying to Railway..."
echo "   This builds the Dockerfile and pushes to Railway's infrastructure."
echo "   First deploy takes ~5-10 minutes (Swift compilation)."
echo ""
railway up

echo ""
echo "═══════════════════════════════════════════"
echo "  ✅ Deployment initiated!"
echo "═══════════════════════════════════════════"
echo ""
echo "  Next steps:"
echo "  1. Watch build logs:     railway logs"
echo "  2. Open dashboard:       railway open"
echo "  3. Get your public URL:  railway domain"
echo "     (Select 'Generate Domain' if no custom domain)"
echo ""
echo "  Once deployed, test with:"
echo "    curl https://YOUR-APP.up.railway.app/health"
echo ""
echo "  Then update your iOS APIClient staging URL:"
echo "    case .staging: return URL(string: \"https://YOUR-APP.up.railway.app/api/v1\")!"
echo ""
