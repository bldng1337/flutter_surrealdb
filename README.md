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

  final rows = await db.query('SELECT * FROM person WHERE role = \$role', vars: {
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

## Sharing a database across isolates

A file-backed database (`surrealkv://…`, `rocksdb://…`) holds a file lock while
it is open, so a second `SurrealDB.connect` to the same path — for example from
a background service isolate — fails while your main client is running.

Pass the same `shareTag` to opt into a process-wide connection: every client
(within the same process, from any isolate) that connects with that tag attaches
to the single underlying engine instead of opening the file again. Each attached
client gets its own session, so `use`, variables and authentication stay
per-client.

```dart
// Main isolate
final db = await SurrealDB.connect('surrealkv:///path/to/db', shareTag: 'main');

// Background isolate (e.g. a workmanager task) — attaches instead of
// failing on the file lock:
await SurrealDB.ensureInitialized();
final db = await SurrealDB.connect('surrealkv:///path/to/db', shareTag: 'main');
```

Notes:

- Attaching with a different endpoint or different options under a tag that is
  already open throws; the endpoint and options of a shared connection are fixed
  when it is created. Connecting with no tag (or a different tag) keeps the
  pre-existing behaviour of a fully private client — including failing on the
  file lock if the database is already open.
- `dispose` releases one client's attachment: its session and live queries are
  closed, and once the last client detaches the connection is shut down and the
  file lock is released.
- `mem://` databases can be shared the same way; without a tag every connect
  still gets its own private in-memory database.
