import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/local/database.dart';
import '../../../data/local/quran_local_source.dart';

class TadabburData {
  final int surah;
  final int ayah;
  final String surahNameBn;
  final String surahNameAr;
  final String ayahAr;
  final String? tafsirSnippet;
  const TadabburData({
    required this.surah,
    required this.ayah,
    required this.surahNameBn,
    required this.surahNameAr,
    required this.ayahAr,
    this.tafsirSnippet,
  });
}

// Returns the "daily tadabbur" ayah for a given userId.
// Algorithm:
//   1. Find the most recent completed lesson for this user.
//   2. Find an ayah_read exercise in that lesson to get surah_name (Arabic).
//   3. Match surah_name against quran_surahs.nameAr to get surah number.
//   4. Daily ayah = (daySeed % ayahCount) + 1 where daySeed = year*10000+month*100+day.
//   5. Fallback surah = 1 (Al-Fatiha) if anything is missing.
final tadabburProvider =
    FutureProvider.family.autoDispose<TadabburData?, String>((ref, userId) async {
  final db     = ref.watch(appDatabaseProvider);
  final source = ref.watch(quranLocalSourceProvider);

  // ── 1. Most recent completed lesson ──────────────────────────────────────
  final progressRows = await (db.select(db.userProgress)
        ..where((t) => t.userId.equals(userId))
        ..orderBy([(t) => drift.OrderingTerm.desc(t.completedAt)])
        ..limit(1))
      .get();

  int? foundSurah;

  if (progressRows.isNotEmpty) {
    final lessonId = progressRows.first.lessonId;

    // ── 2. Find an ayah_read exercise in that lesson ──────────────────────
    final exercises = await (db.select(db.exercises)
          ..where((t) => t.lessonId.equals(lessonId) & t.type.equals('ayah_read')))
        .get();

    for (final ex in exercises) {
      try {
        final ca = jsonDecode(ex.correctAnswer) as Map<String, dynamic>;
        final surahNameAr = ca['surah_name'] as String?;
        if (surahNameAr == null || surahNameAr.isEmpty) continue;

        // ── 3. Match nameAr → surah number ──────────────────────────────
        final row = await (db.select(db.quranSurahs)
              ..where((t) => t.nameAr.equals(surahNameAr)))
            .getSingleOrNull();
        if (row != null) {
          foundSurah = row.number;
          break;
        }
      } catch (_) {
        continue;
      }
    }
  }

  // Fallback to Al-Fatiha if we couldn't determine surah.
  final surahNum = foundSurah ?? 1;

  // ── 4. Get surah metadata ─────────────────────────────────────────────────
  final surahRow = await (db.select(db.quranSurahs)
        ..where((t) => t.number.equals(surahNum)))
      .getSingleOrNull();
  if (surahRow == null) return null;

  final now      = DateTime.now();
  final daySeed  = now.year * 10000 + now.month * 100 + now.day;
  final ayahNum  = (daySeed % surahRow.ayahCount) + 1;

  // ── 5. Load words for this ayah (Drift-first) ────────────────────────────
  final words = await source.getAyahWords(surahNum, ayahNum);
  if (words.isEmpty) return null;

  final ayahAr = words
      .where((w) => w.arabic.runes.any((r) => r >= 0x0600 && r <= 0x06D5))
      .map((w) => w.arabic)
      .join(' ');

  // ── 6. Load tafsir snippet (first sentence only) ─────────────────────────
  final tafsir  = await source.getTafsir(surahNum, ayahNum);
  String? snippet;
  if (tafsir != null) {
    // Split on '।' (Bengali danda) or '\n'; take first meaningful segment.
    final parts = tafsir.tafsirText
        .split(RegExp(r'।|\n'))
        .map((s) => s.trim())
        .where((s) => s.length > 10)
        .toList();
    if (parts.isNotEmpty) {
      snippet = parts.length > 1
          ? '${parts[0]}। ${parts[1]}।'
          : '${parts[0]}।';
    }
  }

  return TadabburData(
    surah: surahNum,
    ayah: ayahNum,
    surahNameBn: surahRow.nameBn,
    surahNameAr: surahRow.nameAr,
    ayahAr: ayahAr,
    tafsirSnippet: snippet,
  );
});
