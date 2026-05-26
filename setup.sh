#!/usr/bin/env bash
# Ta'allam — Project Setup
# Run ONCE from this directory: chmod +x setup.sh && ./setup.sh

set -e

PROJECT="taalaam"
SCAFFOLD="$(dirname "$0")/docs/scaffold"
DOCS="$(dirname "$0")/docs"

echo "🕌 Ta'allam (تعلَّم) — Project Setup"
echo "======================================"

# ── Preflight checks ──────────────────────────────────────────────
if ! command -v flutter &>/dev/null; then
  echo ""
  echo "❌  Flutter not found. Install it first:"
  echo "    macOS (Homebrew):  brew install --cask flutter"
  echo "    Or via fvm:        brew install fvm && fvm install stable && fvm global stable"
  echo "    Then restart your terminal and re-run: ./setup.sh"
  echo ""
  exit 1
fi
FLUTTER_VERSION=$(flutter --version 2>/dev/null | head -1)
echo "✓ $FLUTTER_VERSION"

SUPABASE_AVAIL=false
if command -v supabase &>/dev/null; then
  SUPABASE_AVAIL=true
  echo "✓ Supabase CLI $(supabase --version)"
else
  echo "⚠️  Supabase CLI not found — install later: brew install supabase/tap/supabase"
fi

# ── Flutter project ───────────────────────────────────────────────
echo ""
if [ -d "$PROJECT" ] && [ -f "$PROJECT/pubspec.yaml" ]; then
  echo "==> $PROJECT/ exists — skipping flutter create"
else
  echo "==> Creating Flutter project: $PROJECT"
  flutter create --org com.taalaam --platforms android,ios,web "$PROJECT"
fi

# ── Apply scaffold (overrides flutter defaults) ───────────────────
echo "==> Applying scaffold files..."
if [ ! -d "$SCAFFOLD" ]; then
  echo "  ✗ ERROR: docs/scaffold/ not found"
  exit 1
fi
cp -r "$SCAFFOLD/." "$PROJECT/"
echo "  ✓ Scaffold applied"

# ── Copy docs into project ────────────────────────────────────────
echo "==> Copying docs..."
mkdir -p "$PROJECT/docs"
for f in architecture.md schema.md features.md conventions.md content-pipeline.md free-services.md CLAUDE.md; do
  [ -f "$DOCS/$f" ] && cp "$DOCS/$f" "$PROJECT/docs/$f"
done
[ -f "$DOCS/CLAUDE.md" ] && cp "$DOCS/CLAUDE.md" "$PROJECT/CLAUDE.md"
echo "  ✓ Docs copied"

# ── SQL migration ─────────────────────────────────────────────────
echo "==> Setting up Supabase migrations..."
mkdir -p "$PROJECT/supabase/migrations"
[ -f "$DOCS/0001_initial_schema.sql" ] && \
  cp "$DOCS/0001_initial_schema.sql" "$PROJECT/supabase/migrations/0001_initial_schema.sql" && \
  echo "  ✓ Migration copied"

# ── Supabase init ─────────────────────────────────────────────────
if [ "$SUPABASE_AVAIL" = true ]; then
  if [ ! -f "$PROJECT/supabase/config.toml" ]; then
    echo "==> Initializing Supabase..."
    (cd "$PROJECT" && supabase init)
    echo "  ✓ Supabase initialized"
  else
    echo "  ✓ Supabase already initialized"
  fi
fi

# ── Done ──────────────────────────────────────────────────────────
echo ""
echo "✅  Setup complete!"
echo ""
echo "Next steps:"
echo ""
echo "  cd $PROJECT"
if [ "$SUPABASE_AVAIL" != true ]; then
  echo "  brew install supabase/tap/supabase"
  echo "  supabase init && supabase start"
else
  if [ ! -f "$PROJECT/supabase/config.toml" ]; then
    echo "  supabase init && supabase start"
  else
    echo "  supabase start"
  fi
fi
echo "  flutter pub get"
echo "  dart run build_runner build --delete-conflicting-outputs"
echo "  flutter run -d chrome -t lib/main_admin.dart"
echo ""
echo "📖  Read docs/features.md and start checking off Phase 1 items"
echo "🕌  بَارَكَ اللَّهُ فِيكَ"
