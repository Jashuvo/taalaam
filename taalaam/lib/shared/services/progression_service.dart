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
    // Fire-and-forget: check if the whole Halaqah circle is active today
    checkAndUpdateGroupStreak(userId).then((_) {}).catchError((_) {});
    return SrsReward(
      xp: srsXpReward,
      newHearts: newHearts,
      heartBefore: heartBefore,
      streakDays: streak?.currentStreak ?? 1,
    );
  }

  /// Increments group_streak by 1 when every member of the user's Halaqah
  /// circle has logged streak activity today. Safe to call fire-and-forget.
  Future<void> checkAndUpdateGroupStreak(String userId) async {
    try {
      final client = Supabase.instance.client;

      // Resolve user's group
      final memberRows = await client
          .from('group_memberships')
          .select('group_id')
          .eq('user_id', userId)
          .limit(1);
      if ((memberRows as List).isEmpty) return;
      final groupId = memberRows.first['group_id'] as String;

      // Prevent double-incrementing on the same day
      final groupRow = await client
          .from('groups')
          .select('group_streak, last_streak_update')
          .eq('id', groupId)
          .single();
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final lastUpdate = groupRow['last_streak_update'] as String?;
      if (lastUpdate != null && lastUpdate.startsWith(today)) return;

      // Collect all member IDs
      final allMemberRows = await client
          .from('group_memberships')
          .select('user_id')
          .eq('group_id', groupId);
      final memberIds = (allMemberRows as List)
          .map((r) => r['user_id'] as String)
          .toList();
      if (memberIds.isEmpty) return;

      // Check how many members have streak activity today
      final activeRows = await client
          .from('streaks')
          .select('user_id')
          .inFilter('user_id', memberIds)
          .gte('last_activity_date', today);
      if ((activeRows as List).length < memberIds.length) return;

      // All members active today → increment group streak
      final newStreak = (groupRow['group_streak'] as int? ?? 0) + 1;
      await client.from('groups').update({
        'group_streak': newStreak,
        'last_streak_update': DateTime.now().toIso8601String(),
      }).eq('id', groupId);
    } catch (_) {
      // Non-fatal — group feature is optional
    }
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

  /// Awards bonus XP (e.g. milestone rewards) without touching streak or hearts.
  Future<void> awardBonusXp(String userId, int xp) async {
    final existing = await (_db.select(_db.streaks)
          ..where((t) => t.userId.equals(userId)))
        .getSingleOrNull();
    if (existing == null) return;
    final newXp = existing.totalXp + xp;
    await (_db.update(_db.streaks)
          ..where((t) => t.userId.equals(userId)))
        .write(StreaksCompanion(totalXp: drift.Value(newXp)));
    Supabase.instance.client.from('streaks').upsert({
      'user_id': userId,
      'total_xp': newXp,
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
