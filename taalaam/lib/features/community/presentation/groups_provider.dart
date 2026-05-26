import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/presentation/auth_provider.dart';

// ── Data models ───────────────────────────────────────────────────────────────

class GroupModel {
  final String id;
  final String name;
  final String inviteCode;
  final String? createdBy;
  final int maxMembers;
  final int streakGoal;
  const GroupModel({
    required this.id,
    required this.name,
    required this.inviteCode,
    this.createdBy,
    required this.maxMembers,
    required this.streakGoal,
  });

  factory GroupModel.fromJson(Map<String, dynamic> j) => GroupModel(
        id: j['id'] as String,
        name: j['name'] as String,
        inviteCode: j['invite_code'] as String,
        createdBy: j['created_by'] as String?,
        maxMembers: (j['max_members'] as int?) ?? 10,
        streakGoal: (j['streak_goal'] as int?) ?? 0,
      );
}

class GroupMember {
  final String userId;
  final String joinedAt;
  final int currentStreak;
  final int totalXp;
  const GroupMember({
    required this.userId,
    required this.joinedAt,
    required this.currentStreak,
    required this.totalXp,
  });
}

// ── Providers ─────────────────────────────────────────────────────────────────

/// All groups the current user belongs to
final myGroupsProvider = FutureProvider<List<GroupModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final c = Supabase.instance.client;
  // Fetch group_memberships for this user, then load group details
  final memberships = await c
      .from('group_memberships')
      .select('group_id')
      .eq('user_id', user.id);
  final ids = (memberships as List).map((m) => m['group_id'] as String).toList();
  if (ids.isEmpty) return [];
  final rows = await c.from('groups').select().inFilter('id', ids);
  return (rows as List).map((r) => GroupModel.fromJson(r)).toList();
});

/// Members of a specific group with their streak data
final groupMembersProvider =
    FutureProvider.family<List<GroupMember>, String>((ref, groupId) async {
  final c = Supabase.instance.client;
  final memberships = await c
      .from('group_memberships')
      .select('user_id, joined_at')
      .eq('group_id', groupId);
  final userIds = (memberships as List)
      .map((m) => m['user_id'] as String)
      .toList();
  if (userIds.isEmpty) return [];

  final streaks = await c
      .from('streaks')
      .select('user_id, current_streak, total_xp')
      .inFilter('user_id', userIds);

  final streakMap = <String, Map<String, dynamic>>{};
  for (final s in streaks as List) {
    streakMap[s['user_id'] as String] = s;
  }

  return (memberships).map((m) {
    final uid = m['user_id'] as String;
    final s = streakMap[uid];
    return GroupMember(
      userId: uid,
      joinedAt: m['joined_at'] as String,
      currentStreak: (s?['current_streak'] as int?) ?? 0,
      totalXp: (s?['total_xp'] as int?) ?? 0,
    );
  }).toList()
    ..sort((a, b) => b.currentStreak.compareTo(a.currentStreak));
});

/// Member count for a group (used in list tile subtitle)
final groupMemberCountProvider =
    FutureProvider.family<int, String>((ref, groupId) async {
  final c = Supabase.instance.client;
  final rows = await c
      .from('group_memberships')
      .select('user_id')
      .eq('group_id', groupId);
  return (rows as List).length;
});

// ── Actions ───────────────────────────────────────────────────────────────────

class GroupsNotifier extends StateNotifier<AsyncValue<void>> {
  final String _userId;
  GroupsNotifier(this._userId) : super(const AsyncValue.data(null));

  final _c = Supabase.instance.client;

  Future<String?> createGroup(String name, {int streakGoal = 0}) async {
    state = const AsyncValue.loading();
    try {
      final row = await _c
          .from('groups')
          .insert({
            'name': name,
            'created_by': _userId,
            'streak_goal': streakGoal,
          })
          .select()
          .single();
      final groupId = row['id'] as String;
      await _c.from('group_memberships').insert({
        'group_id': groupId,
        'user_id': _userId,
      });
      state = const AsyncValue.data(null);
      return groupId;
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      return null;
    }
  }

  Future<String?> joinByCode(String code) async {
    state = const AsyncValue.loading();
    try {
      final rows = await _c
          .from('groups')
          .select()
          .eq('invite_code', code.toUpperCase().trim())
          .maybeSingle();
      if (rows == null) {
        state = AsyncValue.error('কোড সঠিক নয়।', StackTrace.current);
        return null;
      }
      final group = GroupModel.fromJson(rows);
      // Check member count against max
      final count = await _c
          .from('group_memberships')
          .select('user_id')
          .eq('group_id', group.id);
      if ((count as List).length >= group.maxMembers) {
        state = AsyncValue.error('এই গ্রুপ পূর্ণ।', StackTrace.current);
        return null;
      }
      await _c.from('group_memberships').upsert({
        'group_id': group.id,
        'user_id': _userId,
      });
      state = const AsyncValue.data(null);
      return group.id;
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      return null;
    }
  }

  Future<void> leaveGroup(String groupId) async {
    await _c
        .from('group_memberships')
        .delete()
        .eq('group_id', groupId)
        .eq('user_id', _userId);
  }

  Future<void> updateGoal(String groupId, int goal) async {
    await _c
        .from('groups')
        .update({'streak_goal': goal})
        .eq('id', groupId);
  }
}

final groupsNotifierProvider = StateNotifierProvider.autoDispose
    .family<GroupsNotifier, AsyncValue<void>, String>(
  (ref, userId) => GroupsNotifier(userId),
);
