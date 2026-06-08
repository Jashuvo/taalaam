import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'database.dart';

class QuranLocalSource {
  final AppDatabase _db;
  const QuranLocalSource(this._db);

  Future<List<QuranWord>> getAyahWords(int surah, int ayah) =>
      (_db.select(_db.quranWords)
            ..where((t) => t.surah.equals(surah) & t.ayah.equals(ayah))
            ..orderBy([(t) => OrderingTerm.asc(t.position)]))
          .get();

  Future<List<QuranSurah>> getAllSurahs() =>
      (_db.select(_db.quranSurahs)
            ..orderBy([(t) => OrderingTerm.asc(t.number)]))
          .get();

  Future<QuranTafsirData?> getTafsir(int surah, int ayah) =>
      (_db.select(_db.quranTafsir)
            ..where((t) => t.surah.equals(surah) & t.ayah.equals(ayah)))
          .getSingleOrNull();

  Future<int> wordCount() async {
    final r = await _db
        .customSelect('SELECT COUNT(*) AS c FROM quran_words')
        .getSingle();
    return r.data['c'] as int;
  }

  Future<void> syncWordsFromSupabase() async {
    final client = Supabase.instance.client;
    int page = 0;
    const pageSize = 1000;
    while (true) {
      final rows = await client
          .from('quran_words')
          .select()
          .range(page * pageSize, (page + 1) * pageSize - 1)
          .order('surah')
          .order('ayah')
          .order('position');
      if ((rows as List).isEmpty) break;
      await _db.batch((b) {
        for (final r in rows) {
          b.insert(
            _db.quranWords,
            QuranWordsCompanion.insert(
              id: r['id'] as String,
              surah: r['surah'] as int,
              ayah: r['ayah'] as int,
              position: r['position'] as int,
              arabic: r['arabic'] as String,
              meaningBn: Value(r['meaning_bn'] as String?),
            ),
            mode: InsertMode.insertOrReplace,
          );
        }
      });
      page++;
    }
  }

  Future<void> syncSurahsFromSupabase() async {
    final rows = await Supabase.instance.client
        .from('quran_surahs')
        .select()
        .order('number') as List;
    await _db.batch((b) {
      for (final r in rows) {
        b.insert(
          _db.quranSurahs,
          QuranSurahsCompanion.insert(
            number: Value(r['number'] as int),
            nameAr: r['name_ar'] as String,
            nameEn: r['name_en'] as String,
            nameBn: r['name_bn'] as String,
            ayahCount: r['ayah_count'] as int,
            revelation: r['revelation'] as String,
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> syncTafsirFromSupabase(int surah) async {
    final rows = await Supabase.instance.client
        .from('quran_tafsir')
        .select()
        .eq('surah', surah)
        .order('ayah') as List;
    await _db.batch((b) {
      for (final r in rows) {
        b.insert(
          _db.quranTafsir,
          QuranTafsirCompanion.insert(
            id: r['id'] as String,
            surah: r['surah'] as int,
            ayah: r['ayah'] as int,
            tafsirText: r['text'] as String,
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }
}

final quranLocalSourceProvider = Provider<QuranLocalSource>(
    (ref) => QuranLocalSource(ref.watch(appDatabaseProvider)));
