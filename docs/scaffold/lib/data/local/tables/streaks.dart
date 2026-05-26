import 'package:drift/drift.dart';

class Streaks extends Table {
  TextColumn get userId => text()(); // primary key (one row per user)
  IntColumn get currentStreak =>
      integer().withDefault(const Constant(0))();
  IntColumn get longestStreak =>
      integer().withDefault(const Constant(0))();
  DateTimeColumn get lastActivityDate => dateTime().nullable()();
  IntColumn get totalXp => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {userId};
}
