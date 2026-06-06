---
paths:
  - "lib/**/*.dart"
---

# Flutter / Dart Rules — Ta'allam

## Arabic text — ALWAYS
- Wrap in Directionality(textDirection: TextDirection.rtl, child: ...)
- Font: NotoNaskhArabic (fontFamily: 'NotoNaskhArabic'), fontSize >= 20, height: 1.8
- Test with: هُوَ أُسْتَاذٌ (should render right-to-left with harakat)

## Styling — never hardcode
- Colors: AppColors.* only (teal, gold, correctBg, wrongBg, correctTile, wrongTile)
- Spacing: use const values or AppSpacing.* — no magic pixel numbers
- Radius: AppRadius.* or BorderRadius.circular(12/16) consistent with existing widgets

## State management
- Riverpod ONLY — no Provider, no Bloc, no setState except for local ephemeral UI state
- Never create StreamProvider/FutureProvider inside build() — always top-level or in initState
- Two entry points: lib/main.dart (learner) and lib/main_admin.dart (admin)

## Models
- All models: Freezed + json_serializable (immutable, factory constructors)
- ExerciseModel.fromJson uses camelCase JSON keys — always map snake_case DB columns manually
- After any Drift table or Freezed model change: dart run build_runner build --delete-conflicting-outputs
- Also bump schemaVersion in lib/data/local/database.dart + add onUpgrade migration

## Exercise widgets
- All exercise widgets accept: ExerciseModel exercise + void Function(bool) onAnswered
- CHECK button pattern: FilledButton disabled until answer selected, then calls onAnswered
- No calls to Supabase or Gemini directly from exercise widgets — use edge functions via Supabase.instance.client.functions.invoke()

## Audio (listen_select)
- Primary: play from exercise.audioUrl (just_audio AudioPlayer)
- Fallback: call generate-exercise-audio edge function → play returned URL
- Final fallback: flutter_tts browser TTS
- _ttsUnavailable = true shows "এই ডিভাইসে আরবি অডিও নেই" + Arabic text visually

## SRS badges (home screen)
- মুখস্থ badge: state == 0 (new cards), capped at 10
- রিভিউ badge: state > 0 (due cards), capped at 20
- Both use INNER JOIN with vocabulary table for consistency
- Providers: newCardCountProvider, reviewCardCountProvider (StreamProvider, not FutureProvider)

## Routing
- go_router in lib/core/router/app_router.dart
- Admin routes: /admin, /admin/upload, /admin/review, /admin/unit/:id
- Learner routes: /home, /lesson/:id, /srs/memorize, /srs/review
- Admin accessible ONLY via main_admin.dart entry point
