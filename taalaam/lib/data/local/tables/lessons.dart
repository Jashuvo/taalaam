import 'package:drift/drift.dart';
import 'units.dart';

class Lessons extends Table {
  TextColumn get id => text()();
  TextColumn get unitId => text().references(Units, #id)();
  TextColumn get titleBn => text()();
  TextColumn get titleAr => text().nullable()();
  IntColumn get sortOrder => integer()();
  IntColumn get xpReward => integer().withDefault(const Constant(10))();
  TextColumn get status =>
      text().withDefault(const Constant('draft'))();
  TextColumn get level =>
      text().withDefault(const Constant('beginner'))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
