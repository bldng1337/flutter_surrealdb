# flutter_surrealdb

This package exposes a Dart API for SurrealDB backed by the Rust engine.

## Installation

Add the package to your Flutter app:
```yaml
dependencies:
  flutter_surrealdb:
    path: ../flutter_surrealdb
```

## Quick start

```dart
import 'package:flutter_surrealdb/flutter_surrealdb.dart';

Future<void> main() async {
  // Initialize Rust bridge once, usually at app startup.
  await SurrealDB.ensureInitialized();

  final db = await SurrealDB.connect('mem://');

  await db.use(ns: 'app', db: 'main');

  final created = await db.insert(
    const DBTable('person'),
    {'name': 'Ada', 'role': 'engineer'},
  );

  final people = await db.select(const DBTable('person'));
  final firstId = created.first['id'] as DBRecord;
  final onePerson = await db.select(firstId);

  final rows = await db.query('SELECT * FROM person WHERE role = $role', vars: {
    'role': 'engineer',
  });

  print(people);
  print(onePerson);
  print(rows);
  
  final stream = db.live(const DBTable('messages'));
  final sub = stream.listen((event) {
    print('action: ${event.action}, record: ${event.record}, result: ${event.result}');
  });
  
  // Later...
  await sub.cancel();

  db.dispose();
}
```
