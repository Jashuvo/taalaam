import 'package:drift/drift.dart';
import 'vocabulary.dart';

class SrsCards extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()(); // Supabase auth.users.id
  TextColumn get vocabularyId =>
      text().references(Vocabulary, #id)();
  DateTimeColumn get dueDate =>
      dateTime().withDefault(currentDateAndTime)();
  // FSRS-4 fields
  RealColumn get stability =>
      real().withDefault(const Constant(0.0))();
  RealColumn get difficulty =>
      real().withDefault(const Constant(5.0))();
  IntColumn get elapsedDays =>
      integer().withDefault(const Constant(0))();
  IntColumn get scheduledDays =>
      integer().withDefault(const Constant(0))();
  IntColumn get reps => integer().withDefault(const Constant(0))();
  IntColumn get lapses => integer().withDefault(const Constant(0))();
  IntColumn get state => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastReview => dateTime().nullable()();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
