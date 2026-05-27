import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/local/database.dart';

class SyncService {
  final AppDatabase _db;
  final SupabaseClient _supabase;

  SyncService(this._db, this._supabase);

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

  // Sync published units for a track, deleting any stale local rows.
  Future<void> syncUnits(String trackId) async {
    final rows = await _supabase
        .from('units')
        .select()
        .eq('track_id', trackId)
        .eq('status', 'published')
        .order('sort_order');

    final remoteIds = (rows as List).map((r) => r['id'] as String).toSet();

    // Delete exercises + lessons belonging to units removed from Supabase
    final localUnits = await (_db.select(_db.units)
          ..where((t) => t.trackId.equals(trackId)))
        .get();
    for (final unit in localUnits) {
      if (!remoteIds.contains(unit.id)) {
        await _deleteUnitLocally(unit.id);
      }
    }

    // Upsert fresh rows
    for (final r in rows) {
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

  // Sync lessons for a unit, deleting stale local rows.
  Future<void> syncLessons(String unitId) async {
    final rows = await _supabase
        .from('lessons')
        .select()
        .eq('unit_id', unitId)
        .order('sort_order');

    final remoteIds = (rows as List).map((r) => r['id'] as String).toSet();

    // Delete exercises belonging to lessons removed from Supabase
    final localLessons = await (_db.select(_db.lessons)
          ..where((t) => t.unitId.equals(unitId)))
        .get();
    for (final lesson in localLessons) {
      if (!remoteIds.contains(lesson.id)) {
        await _deleteLessonLocally(lesson.id);
      }
    }

    // Upsert fresh rows
    for (final r in rows) {
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

  Future<void> _deleteUnitLocally(String unitId) async {
    final lessons = await (_db.select(_db.lessons)
          ..where((t) => t.unitId.equals(unitId)))
        .get();
    for (final l in lessons) {
      await _deleteLessonLocally(l.id);
    }
    await (_db.delete(_db.units)..where((t) => t.id.equals(unitId))).go();
  }

  Future<void> _deleteLessonLocally(String lessonId) async {
    await (_db.delete(_db.exercises)
          ..where((t) => t.lessonId.equals(lessonId)))
        .go();
    await (_db.delete(_db.vocabulary)
          ..where((t) => t.lessonId.equals(lessonId)))
        .go();
    await (_db.delete(_db.lessons)..where((t) => t.id.equals(lessonId))).go();
  }

  Future<void> flushPendingSync() async {
    final pending = await _db.select(_db.pendingSync).get();
    for (final item in pending) {
      try {
        await _db.delete(_db.pendingSync).delete(item);
      } catch (_) {}
    }
  }
}
