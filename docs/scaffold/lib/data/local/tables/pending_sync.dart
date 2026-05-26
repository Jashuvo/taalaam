import 'package:drift/drift.dart';

@DataClassName('PendingSyncEntry')
class PendingSync extends Table {
  @override
  String get tableName => 'pending_sync';

  // Auto-increment integer PK — ordering matters for sync replay
  IntColumn get id => integer().autoIncrement()();
  // 'complete_lesson' | 'rate_card' | 'update_streak'
  TextColumn get action => text()();
  TextColumn get payload => text()(); // JSON
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isProcessing =>
      boolean().withDefault(const Constant(false))();
}
