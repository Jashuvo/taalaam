import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/local/database.dart';

// ── Harakat normalization ──────────────────────────────────────────────────────
// Strips diacritics and normalizes alif/taa variants for cross-source matching.
// Handles quranic-track vocabulary (from quran_words) vs SRS vocabulary arabic forms.
String normalizeArabic(String s) {
  final buf = StringBuffer();
  for (final rune in s.runes) {
    // Strip harakat (0x064B–0x065F), superscript alif (0x0670),
    // Quranic annotation signs (0x06D6–0x06ED), tatweel (0x0640).
    if ((rune >= 0x064B && rune <= 0x065F) ||
        rune == 0x0670 ||
        (rune >= 0x06D6 && rune <= 0x06ED) ||
        rune == 0x0640) {
      continue;
    }
    // Alif wasla (0x0671), alif with madda (0x0622),
    // alif with hamza above (0x0623), alif with hamza below (0x0625) → plain alif (0x0627).
    if (rune == 0x0671 || rune == 0x0622 ||
        rune == 0x0623 || rune == 0x0625) {
      buf.writeCharCode(0x0627);
      continue;
    }
    // Taa marbutah (0x0629) → haa (0x0647).
    if (rune == 0x0629) {
      buf.writeCharCode(0x0647);
      continue;
    }
    buf.writeCharCode(rune);
  }
  return buf.toString();
}

// ── Result model ───────────────────────────────────────────────────────────────
class CoverageResult {
  final double percent;
  final int knownCount;
  final int totalCount;
  const CoverageResult({
    required this.percent,
    required this.knownCount,
    required this.totalCount,
  });
}

// ── Pure computation (testable without DB) ────────────────────────────────────
CoverageResult computeCoverage(
    Map<String, int> freqMap, Iterable<String> knownForms) {
  var knownTokens = 0;
  for (final form in knownForms) {
    knownTokens += freqMap[form] ?? 0;
  }
  final total = freqMap.values.fold(0, (a, b) => a + b);
  final pct =
      total == 0 ? 0.0 : (knownTokens / total * 100).clamp(0.0, 100.0);
  return CoverageResult(
      percent: pct, knownCount: knownTokens, totalCount: total);
}

// ── Module-level freq map cache ────────────────────────────────────────────────
// Built once from quran_words on first coverage request; persists for app lifetime.
Map<String, int>? _cachedFreqMap;

Future<Map<String, int>> _getOrBuildFreqMap(AppDatabase db) async {
  if (_cachedFreqMap != null) return _cachedFreqMap!;
  final rows = await db.select(db.quranWords).get();
  final map = <String, int>{};
  for (final row in rows) {
    final norm = normalizeArabic(row.arabic);
    map[norm] = (map[norm] ?? 0) + 1;
  }
  _cachedFreqMap = map;
  return map;
}

// ── Word-knowledge sets provider ──────────────────────────────────────────────
// Emits per-userId (mastered, learning) sets of normalized arabic forms.
// mastered: state==2 OR scheduledDays>=7; learning: has card but not mastered.
// Reuses normalizeArabic — single source of truth for tinting and coverage.
final knownWordFormsProvider = StreamProvider.family
    .autoDispose<({Set<String> mastered, Set<String> learning}), String>(
        (ref, userId) {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.srsCards).join([
    drift.innerJoin(db.vocabulary,
        db.vocabulary.id.equalsExp(db.srsCards.vocabularyId)),
  ])
        ..where(db.srsCards.userId.equals(userId)))
      .watch()
      .map((rows) {
    final mastered = <String>{};
    final learning = <String>{};
    for (final row in rows) {
      final card = row.readTable(db.srsCards);
      final vocab = row.readTable(db.vocabulary);
      final norm = normalizeArabic(vocab.arabic);
      if (card.state == 2 || card.scheduledDays >= 7) {
        mastered.add(norm);
      } else {
        learning.add(norm);
      }
    }
    return (mastered: mastered, learning: learning);
  });
});

// ── Riverpod provider ──────────────────────────────────────────────────────────
// Watches SRS cards live; re-emits CoverageResult on every lesson completion.
// "Known" = state == 2 (review-passed) OR scheduledDays >= 7.
final quranCoverageProvider =
    StreamProvider.family.autoDispose<CoverageResult, String>(
        (ref, userId) async* {
  final db = ref.watch(appDatabaseProvider);

  final knownStream = (db.select(db.srsCards).join([
    drift.innerJoin(db.vocabulary,
        db.vocabulary.id.equalsExp(db.srsCards.vocabularyId)),
  ])
        ..where(db.srsCards.userId.equals(userId) &
            (db.srsCards.state.equals(2) |
                db.srsCards.scheduledDays.isBiggerOrEqualValue(7))))
      .watch()
      .map((rows) {
    final seen = <String>{};
    for (final row in rows) {
      seen.add(normalizeArabic(row.readTable(db.vocabulary).arabic));
    }
    return seen;
  });

  await for (final knownForms in knownStream) {
    final freqMap = await _getOrBuildFreqMap(db);
    yield computeCoverage(freqMap, knownForms);
  }
});
