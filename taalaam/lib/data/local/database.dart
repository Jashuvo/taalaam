import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
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
  int get schemaVersion => 2;

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
    },
  );

  static QueryExecutor _openConnection() => driftDatabase(name: 'taalaam');
}

// Manual provider — keeps Riverpod alive for the lifetime of the app
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
