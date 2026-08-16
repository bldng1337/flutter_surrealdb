import 'package:flutter_surrealdb/flutter_surrealdb.dart';
import 'package:uuid/uuid_value.dart';

class Notification {
  final UuidValue id;
  final Action action;
  final DBRecord? record;
  final dynamic result;

  Notification({
    required this.id,
    required this.action,
    required this.record,
    required this.result,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Notification &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          action == other.action &&
          record == other.record &&
          result == other.result;

  @override
  int get hashCode =>
      id.hashCode ^ action.hashCode ^ record.hashCode ^ result.hashCode;

  @override
  String toString() =>
      "Notification(id: $id, action: $action, record: $record, result: $result)";
}
