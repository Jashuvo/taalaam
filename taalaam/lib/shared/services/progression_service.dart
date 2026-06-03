import 'package:drift/drift.dart' as drift;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/local/database.dart';
import '../../core/constants/app_constants.dart';

/// Result of a completed SRS session — shown in the reward done screen.
class SrsReward {
  final int xp;
  final int newHearts;
  final int heartBefore;
  final int streakDays;
  const SrsReward({
    required this.xp,
    required this.newHearts,
    required this.heartBefore,
    required this.streakDays,
  });

  bool get heartGained => newHearts > heartBefore;
}

/// Handles XP, streak, and heart updates for SRS batch completions.
/// Uses identical streak logic to lesson_screen._updateStreak to ensure
/// same-day double-counting is handled correctly (diff==0 → no increment).
class ProgressionService {
  final AppDatabase _db;
  ProgressionService(this._db);

  static const int srsXpReward = 10;

  Future<SrsReward> awardSrsSession(String userId) async {
    final now = DateTime.now();
    final heartBefore = await _currentHearts(userId);
    await _updateStreak(userId, srsXpReward, now);
    final newHearts = await _incrementHearts(userId);
    final streak = await (_db.select(_db.streaks)
          ..where((t) => t.userId.equals(userId)))
        .getSingleOrNull();
    return SrsReward(
      xp: srsXpReward,
      newHearts: newHearts,
      heartBefore: heartBefore,
      streakDays: streak?.currentStreak ?? 1,
    );
  }

  Future<int> _currentHearts(String userId) async {
    final row = await (_db.select(_db.streaks)
          ..where((t) => t.userId.equals(userId)))
        .getSingleOrNull();
    return row?.hearts ?? AppConstants.heartsPerLesson;
  }

  Future<void> _updateStreak(
      String userId, int xpEarned, DateTime now) async {
    final today = DateTime(now.year, now.month, now.day);
    final existing = await (_db.select(_db.streaks)
          ..where((t) => t.userId.equals(userId)))
        .getSingleOrNull();

    int newStreak, newLongest, newTotalXp;

    if (existing == null) {
      newStreak = 1;
      newLongest = 1;
      newTotalXp = xpEarned;
    } else {
      newTotalXp = existing.totalXp + xpEarned;
      final lastDate = existing.lastActivityDate;
      if (lastDate == null) {
        newStreak = 1;
      } else {
        final lastDay =
            DateTime(lastDate.year, lastDate.month, lastDate.day);
        final diff = today.difference(lastDay).inDays;
        if (diff == 0) {
          newStreak = existing.currentStreak;
        } else if (diff == 1) {
          newStreak = existing.currentStreak + 1;
        } else {
          newStreak = 1;
        }
      }
      newLongest = newStreak > existing.longestStreak
          ? newStreak
          : existing.longestStreak;
    }

    await _db.into(_db.streaks).insertOnConflictUpdate(StreaksCompanion(
          userId: drift.Value(userId),
          currentStreak: drift.Value(newStreak),
          longestStreak: drift.Value(newLongest),
          lastActivityDate: drift.Value(today),
          totalXp: drift.Value(newTotalXp),
          updatedAt: drift.Value(now),
        ));

    Supabase.instance.client.from('streaks').upsert({
      'user_id': userId,
      'current_streak': newStreak,
      'longest_streak': newLongest,
      'last_activity_date': today.toIso8601String().substring(0, 10),
      'total_xp': newTotalXp,
    }).then((_) {}).catchError((_) {});
  }

  Future<int> _incrementHearts(String userId) async {
    final existing = await (_db.select(_db.streaks)
          ..where((t) => t.userId.equals(userId)))
        .getSingleOrNull();
    final current = existing?.hearts ?? AppConstants.heartsPerLesson;
    final newHearts =
        (current + 1).clamp(0, AppConstants.heartsPerLesson);
    if (existing != null) {
      await (_db.update(_db.streaks)
            ..where((t) => t.userId.equals(userId)))
          .write(StreaksCompanion(hearts: drift.Value(newHearts)));
    }
    return newHearts;
  }
}
