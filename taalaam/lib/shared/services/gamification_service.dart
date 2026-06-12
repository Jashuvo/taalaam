import 'package:shared_preferences/shared_preferences.dart';

class GamificationService {
  static const _goalClaimedPrefix = 'goal_reward_v1_';
  static const _firstLessonPrefix = 'first_lesson_date_';
  static const _weeklyXpPrefix = 'weekly_xp_';
  static const _weeklyStartPrefix = 'weekly_start_';

  static const int goalRewardXp = 50;
  static const int firstLessonBonusXp = 10;
  static const int perfectBonusXp = 10;

  // Returns whether a first-lesson bonus should be awarded today.
  // Records today's date so it only fires once per calendar day.
  static Future<bool> claimFirstLessonBonus(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_firstLessonPrefix$userId';
    final today = _dateKey(DateTime.now());
    if (prefs.getString(key) == today) return false;
    await prefs.setString(key, today);
    return true;
  }

  // Read-only check (does not mark as claimed) for whether today's
  // first-lesson 2x XP bonus is still available.
  static Future<bool> firstLessonBonusAvailable(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_firstLessonPrefix$userId';
    return prefs.getString(key) != _dateKey(DateTime.now());
  }

  // Returns whether goal reward is available and marks it claimed.
  static Future<bool> claimGoalRewardIfDue(
      String userId, int currentStreak, int? streakGoal) async {
    if (streakGoal == null || currentStreak < streakGoal) return false;
    final prefs = await SharedPreferences.getInstance();
    final key = '$_goalClaimedPrefix${userId}_$streakGoal';
    if (prefs.getBool(key) == true) return false;
    await prefs.setBool(key, true);
    return true;
  }

  // Called when streak goal is changed so the reward resets.
  static Future<void> resetGoalReward(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final toRemove = prefs.getKeys()
        .where((k) => k.startsWith('$_goalClaimedPrefix$userId'))
        .toList();
    for (final k in toRemove) {
      await prefs.remove(k);
    }
  }

  // Returns XP earned in the current Mon–Sun window.
  static Future<int> getWeeklyXp(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final weekKey = _weekStartKey(DateTime.now());
    if (prefs.getString('$_weeklyStartPrefix$userId') != weekKey) {
      await prefs.setString('$_weeklyStartPrefix$userId', weekKey);
      await prefs.setInt('$_weeklyXpPrefix$userId', 0);
      return 0;
    }
    return prefs.getInt('$_weeklyXpPrefix$userId') ?? 0;
  }

  // Adds XP to the weekly bucket, resetting if in a new week.
  static Future<void> addWeeklyXp(String userId, int xp) async {
    final prefs = await SharedPreferences.getInstance();
    final weekKey = _weekStartKey(DateTime.now());
    final storedKey = '$_weeklyStartPrefix$userId';
    final xpKey = '$_weeklyXpPrefix$userId';
    if (prefs.getString(storedKey) != weekKey) {
      await prefs.setString(storedKey, weekKey);
      await prefs.setInt(xpKey, xp);
    } else {
      final current = prefs.getInt(xpKey) ?? 0;
      await prefs.setInt(xpKey, current + xp);
    }
  }

  static String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  static String _weekStartKey(DateTime dt) {
    final monday = dt.subtract(Duration(days: dt.weekday - 1));
    return _dateKey(monday);
  }
}
