import 'package:drift/drift.dart';
import 'lessons.dart';

@DataClassName('VocabEntry')
class Vocabulary extends Table {
  @override
  String get tableName => 'vocabulary';

  TextColumn get id => text()();
  TextColumn get arabic => text()();
  TextColumn get transliteration => text().nullable()();
  TextColumn get meaningBn => text()();
  TextColumn get meaningEn => text().nullable()();
  TextColumn get rootLetters => text().nullable()();
  TextColumn get wordType => text().nullable()();
  TextColumn get gender => text().nullable()();
  TextColumn get audioUrl => text().nullable()();
  TextColumn get lessonId =>
      text().nullable().references(Lessons, #id)();
  IntColumn get frequencyRank => integer().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
