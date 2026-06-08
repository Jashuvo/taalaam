import 'package:drift/drift.dart';
import 'connection_native.dart'
    if (dart.library.html) 'connection_web.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'tables/bookmarks.dart';
import 'tables/exercises.dart';
import 'tables/lessons.dart';
import 'tables/pending_sync.dart';
import 'tables/srs_cards.dart';
import 'tables/streaks.dart';
import 'tables/tracks.dart';
import 'tables/units.dart';
import 'tables/user_progress.dart';
import 'tables/vocabulary.dart';

part 'database.g.dart';

class QuranWords extends Table {
  TextColumn get id => text()();
  IntColumn get surah => integer()();
  IntColumn get ayah => integer()();
  IntColumn get position => integer()();
  TextColumn get arabic => text()();
  TextColumn get meaningBn => text().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

class QuranSurahs extends Table {
  IntColumn get number => integer()();
  TextColumn get nameAr => text()();
  TextColumn get nameEn => text()();
  TextColumn get nameBn => text()();
  IntColumn get ayahCount => integer()();
  TextColumn get revelation => text()();
  @override
  Set<Column> get primaryKey => {number};
}

class QuranTafsir extends Table {
  TextColumn get id         => text()();
  IntColumn  get surah      => integer()();
  IntColumn  get ayah       => integer()();
  TextColumn get tafsirText => text()();
  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [
  Tracks,
  Units,
  Lessons,
  Exercises,
  Vocabulary,
  SrsCards,
  UserProgress,
  Streaks,
  PendingSync,
  Bookmarks,
  QuranWords,
  QuranSurahs,
  QuranTafsir,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 10;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await customStatement(
            'ALTER TABLE streaks ADD COLUMN freeze_count INTEGER NOT NULL DEFAULT 0');
        await customStatement(
            'ALTER TABLE streaks ADD COLUMN last_freezed_at INTEGER');
        await customStatement('''
          CREATE TABLE IF NOT EXISTS bookmarks (
            id TEXT NOT NULL PRIMARY KEY,
            user_id TEXT NOT NULL,
            lesson_id TEXT NOT NULL REFERENCES lessons (id),
            created_at INTEGER NOT NULL DEFAULT 0
          )
        ''');
      }
      if (from < 3) {
        await customStatement(
            'ALTER TABLE lessons ADD COLUMN gem_reward INTEGER NOT NULL DEFAULT 0');
        await customStatement(
            'ALTER TABLE lessons ADD COLUMN is_exam INTEGER NOT NULL DEFAULT 0');
      }
      if (from < 4) {
        await customStatement(
            'ALTER TABLE streaks ADD COLUMN hearts INTEGER NOT NULL DEFAULT 5');
        await customStatement(
            'ALTER TABLE vocabulary ADD COLUMN context_snippet_ar TEXT');
        await customStatement(
            'ALTER TABLE vocabulary ADD COLUMN context_snippet_bn TEXT');
      }
      if (from < 5) {
        await customStatement(
            'ALTER TABLE vocabulary ADD COLUMN grammar_note_bn TEXT');
      }
      if (from < 6) {
        await customStatement(
            'ALTER TABLE units ADD COLUMN tier_level INTEGER NOT NULL DEFAULT 1');
        await customStatement(
            'ALTER TABLE units ADD COLUMN sequence_order INTEGER NOT NULL DEFAULT 1');
      }
      if (from < 7) {
        await customStatement(
            'ALTER TABLE units ADD COLUMN unlock_metadata TEXT');
      }
      if (from < 8) {
        try {
          await customStatement(
              'ALTER TABLE vocabulary ADD COLUMN grammar_note_bn TEXT');
        } catch (_) {}
      }
      if (from < 9) {
        await customStatement(
            'ALTER TABLE streaks ADD COLUMN streak_goal INTEGER');
      }
      if (from < 10) {
        await customStatement('''
          CREATE TABLE IF NOT EXISTS quran_words (
            id TEXT NOT NULL PRIMARY KEY,
            surah INTEGER NOT NULL,
            ayah INTEGER NOT NULL,
            position INTEGER NOT NULL,
            arabic TEXT NOT NULL,
            meaning_bn TEXT
          )
        ''');
        await customStatement('''
          CREATE TABLE IF NOT EXISTS quran_surahs (
            number INTEGER NOT NULL PRIMARY KEY,
            name_ar TEXT NOT NULL,
            name_en TEXT NOT NULL,
            name_bn TEXT NOT NULL,
            ayah_count INTEGER NOT NULL,
            revelation TEXT NOT NULL
          )
        ''');
        await customStatement('''
          CREATE TABLE IF NOT EXISTS quran_tafsir (
            id TEXT NOT NULL PRIMARY KEY,
            surah INTEGER NOT NULL,
            ayah INTEGER NOT NULL,
            tafsir_text TEXT NOT NULL
          )
        ''');
      }
    },
  );

  static QueryExecutor _openConnection() => openDatabaseConnection();
}

// Manual provider — keeps Riverpod alive for the lifetime of the app
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
