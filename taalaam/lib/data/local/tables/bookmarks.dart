import 'package:drift/drift.dart';
import 'lessons.dart';

class Bookmarks extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get lessonId => text().references(Lessons, #id)();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
