import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() => driftDatabase(name: 'taalaam');
}

// Manual provider — keeps Riverpod alive for the lifetime of the app
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
