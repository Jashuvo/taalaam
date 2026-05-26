import 'package:drift/drift.dart';

class Tracks extends Table {
  TextColumn get id => text()();
  TextColumn get slug => text().unique()();
  TextColumn get nameAr => text()();
  TextColumn get nameBn => text()();
  TextColumn get nameEn => text()();
  TextColumn get descriptionBn => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
