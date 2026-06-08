import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'database.dart';

int _toInt(dynamic v) => (v as num).toInt();

class QuranLocalSource {
  final AppDatabase _db;
  const QuranLocalSource(this._db);

  Future<List<QuranSurah>> getAllSurahs() async {
    try {
      final local = await (_db.select(_db.quranSurahs)
            ..orderBy([(t) => OrderingTerm.asc(t.number)]))
          .get();
      if (local.isNotEmpty) return local;

      final rows = await Supabase.instance.client
          .from('quran_surahs')
          .select()
          .order('number') as List;
      await _db.batch((b) {
        for (final r in rows) {
          b.insert(
            _db.quranSurahs,
            QuranSurahsCompanion.insert(
              number: Value(_toInt(r['number'])),
              nameAr: r['name_ar'] as String,
              nameEn: r['name_en'] as String,
              nameBn: r['name_bn'] as String,
              ayahCount: _toInt(r['ayah_count']),
              revelation: r['revelation'] as String,
            ),
            mode: InsertMode.insertOrReplace,
          );
        }
      });
      return (_db.select(_db.quranSurahs)
            ..orderBy([(t) => OrderingTerm.asc(t.number)]))
          .get();
    } catch (e) {
      return [];
    }
  }

  Future<List<QuranWord>> getAyahWords(int surah, int ayah) async {
    try {
      final local = await (_db.select(_db.quranWords)
            ..where((t) => t.surah.equals(surah) & t.ayah.equals(ayah))
            ..orderBy([(t) => OrderingTerm.asc(t.position)]))
          .get();
      if (local.isNotEmpty) return _fillFallbackMeanings(local);

      final rows = await Supabase.instance.client
          .from('quran_words')
          .select()
          .eq('surah', surah)
          .eq('ayah', ayah)
          .order('position') as List;
      if (rows.isEmpty) return [];

      try {
        await _db.batch((b) {
          for (final r in rows) {
            b.insert(
              _db.quranWords,
              QuranWordsCompanion.insert(
                id: r['id'] as String,
                surah: _toInt(r['surah']),
                ayah: _toInt(r['ayah']),
                position: _toInt(r['position']),
                arabic: r['arabic'] as String,
                meaningBn: Value(r['meaning_bn'] as String?),
              ),
              mode: InsertMode.insertOrReplace,
            );
          }
        });
      } catch (_) {
        // batch failed — return Supabase data directly via the rows we have
        // (they won't be cached, but the UI still works)
        return _buildWordsFromRows(rows, surah, ayah);
      }

      final saved = await (_db.select(_db.quranWords)
            ..where((t) => t.surah.equals(surah) & t.ayah.equals(ayah))
            ..orderBy([(t) => OrderingTerm.asc(t.position)]))
          .get();
      return _fillFallbackMeanings(saved);
    } catch (e) {
      return [];
    }
  }

  // For any word with no Bengali meaning, look for a cached word with the
  // same Arabic text that does have one. This fixes basmala words appearing
  // in ayah 1 of non-Fatiha surahs (alquran.cloud prepends the basmala
  // text to ayah 1, but GTAF meanings are only keyed to surah 1 / Fatiha).
  Future<List<QuranWord>> _fillFallbackMeanings(List<QuranWord> words) async {
    final missing = words.where((w) => w.meaningBn == null).toList();
    if (missing.isEmpty) return words;

    final arabicTexts = missing.map((w) => w.arabic).toSet().toList();
    try {
      final matches = await (_db.select(_db.quranWords)
            ..where((t) =>
                t.arabic.isIn(arabicTexts) & t.meaningBn.isNotNull()))
          .get();
      if (matches.isEmpty) return words;

      // Build a lookup: arabic text → first found meaning
      final fallback = <String, String>{};
      for (final m in matches) {
        fallback.putIfAbsent(m.arabic, () => m.meaningBn!);
      }

      return words.map((w) {
        if (w.meaningBn != null) return w;
        final fb = fallback[w.arabic];
        return fb != null ? w.copyWith(meaningBn: Value(fb)) : w;
      }).toList();
    } catch (_) {
      return words;
    }
  }

  List<QuranWord> _buildWordsFromRows(List rows, int surah, int ayah) {
    try {
      return rows
          .map((r) => QuranWord(
                id: r['id'] as String,
                surah: _toInt(r['surah']),
                ayah: _toInt(r['ayah']),
                position: _toInt(r['position']),
                arabic: r['arabic'] as String,
                meaningBn: r['meaning_bn'] as String?,
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<QuranTafsirData?> getTafsir(int surah, int ayah) {
    return (_db.select(_db.quranTafsir)
          ..where((t) => t.surah.equals(surah) & t.ayah.equals(ayah)))
        .getSingleOrNull();
  }

  Future<void> syncTafsirFromSupabase(int surah) async {
    final rows = await Supabase.instance.client
        .from('quran_tafsir')
        .select()
        .eq('surah', surah)
        .order('ayah') as List;
    try {
      await _db.batch((b) {
        for (final r in rows) {
          b.insert(
            _db.quranTafsir,
            QuranTafsirCompanion.insert(
              id: r['id'] as String,
              surah: _toInt(r['surah']),
              ayah: _toInt(r['ayah']),
              tafsirText: r['text'] as String,
            ),
            mode: InsertMode.insertOrReplace,
          );
        }
      });
    } catch (_) {}
  }
}

final quranLocalSourceProvider = Provider<QuranLocalSource>(
    (ref) => QuranLocalSource(ref.watch(appDatabaseProvider)));
