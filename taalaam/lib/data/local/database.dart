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
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 6;

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
