import 'package:flutter_surrealdb/flutter_surrealdb.dart';
import 'package:uuid/uuid_value.dart';

class Notification {
  final UuidValue id;
  final Action action;
  final DBRecord record;
  final dynamic result;

  Notification({
    required this.id,
    required this.action,
    required this.record,
    required this.result,
  });
}
