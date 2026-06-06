---
paths:
  - "supabase/migrations/**/*.sql"
---

# Migration Rules — Ta'allam

## Naming
- Files: 00XX_descriptive_name.sql (next number after last migration)
- Check supabase/migrations/ for the current highest number before creating

## Current schema (Drift v4, Supabase mirrors it)
Key tables: tracks, units, lessons, exercises, vocabulary, srs_cards, streaks, user_progress, exam_questions
Key columns added recently (bold in CLAUDE.md): is_exam, gem_reward, hearts, context_snippet_ar/bn, audio_url

## After writing a migration
1. supabase db push --linked
2. If Drift tables changed: bump schemaVersion in lib/data/local/database.dart
3. Add onUpgrade case for the new version
4. dart run build_runner build --delete-conflicting-outputs

## RLS policies pattern
- All tables have RLS enabled
- Admin (jubayedsr@gmail.com) gets ALL permissions
- Learners get SELECT on published content, INSERT/UPDATE on their own user data
