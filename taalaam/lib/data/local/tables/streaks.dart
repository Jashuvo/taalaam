import 'package:drift/drift.dart';

class Streaks extends Table {
  TextColumn get userId => text()(); // primary key (one row per user)
  IntColumn get currentStreak =>
      integer().withDefault(const Constant(0))();
  IntColumn get longestStreak =>
      integer().withDefault(const Constant(0))();
  DateTimeColumn get lastActivityDate => dateTime().nullable()();
  IntColumn get totalXp => integer().withDefault(const Constant(0))();
  IntColumn get freezeCount =>
      integer().withDefault(const Constant(0))();
  DateTimeColumn get lastFreezedAt => dateTime().nullable()();
  // Persistent heart pool — SRS sessions can regenerate up to max (5)
  IntColumn get hearts =>
      integer().withDefault(const Constant(5))();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {userId};
}
