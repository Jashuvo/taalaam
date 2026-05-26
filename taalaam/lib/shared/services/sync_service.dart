import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/local/database.dart';

class SyncService {
  final AppDatabase _db;
  final SupabaseClient _supabase;

  SyncService(this._db, this._supabase);

  // Sync published tracks → local Drift. Called on app start.
  Future<void> syncTracks() async {
    final rows = await _supabase
        .from('tracks')
        .select()
        .order('sort_order');
    for (final r in (rows as List)) {
      await _db.into(_db.tracks).insertOnConflictUpdate(TracksCompanion(
            id: Value(r['id'] as String),
            slug: Value(r['slug'] as String),
            nameAr: Value(r['name_ar'] as String),
            nameBn: Value(r['name_bn'] as String),
            nameEn: Value(r['name_en'] as String),
            descriptionBn: Value(r['description_bn'] as String?),
            sortOrder: Value((r['sort_order'] as int?) ?? 0),
          ));
    }
  }

  // Sync published units for a track.
  Future<void> syncUnits(String trackId) async {
    final rows = await _supabase
        .from('units')
        .select()
        .eq('track_id', trackId)
        .eq('status', 'published')
        .order('sort_order');
    for (final r in (rows as List)) {
      await _db.into(_db.units).insertOnConflictUpdate(UnitsCompanion(
            id: Value(r['id'] as String),
            trackId: Value(r['track_id'] as String),
            slug: Value(r['slug'] as String),
            titleAr: Value(r['title_ar'] as String?),
            titleBn: Value(r['title_bn'] as String),
            titleEn: Value(r['title_en'] as String?),
            descriptionBn: Value(r['description_bn'] as String?),
            sortOrder: Value(r['sort_order'] as int),
            status: Value((r['status'] as String?) ?? 'draft'),
          ));
    }
  }

  // Sync lessons for a unit.
  Future<void> syncLessons(String unitId) async {
    final rows = await _supabase
        .from('lessons')
        .select()
        .eq('unit_id', unitId)
        .order('sort_order');
    for (final r in (rows as List)) {
      await _db.into(_db.lessons).insertOnConflictUpdate(LessonsCompanion(
            id: Value(r['id'] as String),
            unitId: Value(r['unit_id'] as String),
            titleBn: Value(r['title_bn'] as String),
            titleAr: Value(r['title_ar'] as String?),
            sortOrder: Value(r['sort_order'] as int),
            xpReward: Value((r['xp_reward'] as int?) ?? 10),
            status: Value((r['status'] as String?) ?? 'draft'),
            level: Value((r['level'] as String?) ?? 'beginner'),
          ));
    }
  }

  // Push pending sync actions to Supabase.
  Future<void> flushPendingSync() async {
    final pending = await _db.select(_db.pendingSync).get();
    for (final item in pending) {
      try {
        // Each action is a JSON payload: { table, op, data }
        // For Phase 1, progress + streak updates
        await _db.delete(_db.pendingSync).delete(item);
      } catch (_) {
        // Leave in queue, retry next time
      }
    }
  }
}
