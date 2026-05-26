import 'package:drift/drift.dart';
import 'lessons.dart';

@DataClassName('UserProgressEntry')
class UserProgress extends Table {
  @override
  String get tableName => 'user_progress';

  TextColumn get id => text()();
  TextColumn get userId => text()(); // Supabase auth.users.id
  TextColumn get lessonId => text().references(Lessons, #id)();
  DateTimeColumn get completedAt =>
      dateTime().withDefault(currentDateAndTime)();
  IntColumn get xpEarned => integer().withDefault(const Constant(0))();
  IntColumn get accuracyPct =>
      integer().withDefault(const Constant(0))();
  IntColumn get heartsRemaining =>
      integer().withDefault(const Constant(5))();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
