import 'package:drift/drift.dart';
import 'tracks.dart';

class Units extends Table {
  TextColumn get id => text()();
  TextColumn get trackId => text().references(Tracks, #id)();
  TextColumn get slug => text()();
  TextColumn get titleAr => text().nullable()();
  TextColumn get titleBn => text()();
  TextColumn get titleEn => text().nullable()();
  TextColumn get descriptionBn => text().nullable()();
  IntColumn get sortOrder => integer()();
  TextColumn get status =>
      text().withDefault(const Constant('draft'))();
  TextColumn get sourceMaterialId => text().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get downloadedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
