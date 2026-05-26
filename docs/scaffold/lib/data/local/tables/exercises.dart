import 'package:drift/drift.dart';
import 'lessons.dart';

// correct_answer and distractors stored as JSON text — matches Supabase jsonb
class Exercises extends Table {
  TextColumn get id => text()();
  TextColumn get lessonId => text().references(Lessons, #id)();
  TextColumn get type => text()(); // ExerciseType enum value
  IntColumn get sortOrder => integer()();
  TextColumn get promptAr => text().nullable()();
  TextColumn get promptBn => text().nullable()();
  TextColumn get promptEn => text().nullable()();
  TextColumn get correctAnswer => text()(); // JSON
  TextColumn get distractors => text().nullable()(); // JSON
  TextColumn get audioUrl => text().nullable()();
  TextColumn get grammarNoteBn => text().nullable()();
  TextColumn get grammarNoteEn => text().nullable()();
  IntColumn get difficulty =>
      integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
