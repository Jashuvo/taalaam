import 'package:flutter_test/flutter_test.dart';
import 'package:taalaam/features/track_quran/data/quran_coverage_service.dart';

void main() {
  // ── normalizeArabic ──────────────────────────────────────────────────────────

  group('normalizeArabic', () {
    test('strips fathah, kasrah, dammah, tanwin', () {
      // كِتَابٌ → كتاب
      expect(
        normalizeArabic('كِتَابٌ'),
        'كتاب',
      );
    });

    test('strips shadda and sukun', () {
      // اللَّهُ (with shadda+fathah on lam, damma on ha)
      expect(
        normalizeArabic('اللَّهُ'),
        'الله',
      );
    });

    test('normalizes alif wasla (U+0671) → plain alif (U+0627)', () {
      expect(normalizeArabic('ٱ'), 'ا');
    });

    test('normalizes alif with madda above (U+0622) → plain alif', () {
      expect(normalizeArabic('آ'), 'ا');
    });

    test('normalizes alif with hamza above (U+0623) → plain alif', () {
      expect(normalizeArabic('أ'), 'ا');
    });

    test('normalizes alif with hamza below (U+0625) → plain alif', () {
      expect(normalizeArabic('إ'), 'ا');
    });

    test('converts taa marbutah (U+0629) → haa (U+0647)', () {
      // مَدْرَسَةٌ → مدرسه
      expect(
        normalizeArabic('مَدْرَسَةٌ'),
        'مدرسه',
      );
    });

    test('harakat-full form matches stripped form', () {
      // كِتَابٌ and كتاب should normalize to the same string
      final withHarakat    = normalizeArabic('كِتَابٌ');
      final withoutHarakat = normalizeArabic('كتاب');
      expect(withHarakat, withoutHarakat);
    });

    test('strips tatweel (U+0640)', () {
      expect(normalizeArabic('اـل'), 'ال');
    });
  });

  // ── computeCoverage ──────────────────────────────────────────────────────────

  group('computeCoverage', () {
    test('3 fake quran_words rows — 1 known word — correct percent', () {
      // Simulate quran_words table with 3 token rows, each a distinct word.
      // arabic column values (with full harakat as stored in quran_words):
      //   كِتَابٌ  (U+0643 U+0650 U+062A U+064E U+0627 U+0628 U+064C)
      //   ٱللَّهُ  (alif-wasla + lam lam shadda-fathah ha damma)
      //   رَحِيمٌ  (ra fathah ha kasrah ya meem tanwin-damm)
      final freqMap = {
        normalizeArabic('كِتَابٌ'): 1,
        normalizeArabic('ٱللَّهُ'): 1,
        normalizeArabic('رَحِيمٌ'): 1,
      };

      // User knows the harakat-full form — normalization must match
      final knownForms = {
        normalizeArabic('كِتَابٌ'),
      };

      final result = computeCoverage(freqMap, knownForms);

      expect(result.totalCount, 3);
      expect(result.knownCount, 1);
      expect(result.percent, closeTo(33.333, 0.001));
    });

    test('no known forms yields 0%', () {
      final freqMap = {normalizeArabic('كتاب'): 5};
      final result  = computeCoverage(freqMap, <String>{});
      expect(result.percent, 0.0);
      expect(result.knownCount, 0);
      expect(result.totalCount, 5);
    });

    test('empty freq map yields 0% regardless of known forms', () {
      final result = computeCoverage({}, {'كتاب'});
      expect(result.percent, 0.0);
      expect(result.totalCount, 0);
    });

    test('all known yields 100%', () {
      final freqMap = {
        'كتاب': 10,
        'رحيم': 5,
      };
      final result = computeCoverage(freqMap, freqMap.keys);
      expect(result.percent, closeTo(100.0, 0.001));
      expect(result.knownCount, 15);
      expect(result.totalCount, 15);
    });

    test('high-frequency word dominates percent', () {
      // 1 rare word (1 token) + 1 frequent word (99 tokens) = 100 total
      final freqMap = {'كتاب': 1, 'الله': 99};
      // Only knowing the frequent word: 99/100 = 99%
      final result = computeCoverage(freqMap, {'الله'});
      expect(result.percent, closeTo(99.0, 0.001));
    });
  });
}
