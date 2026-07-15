import 'dart:io';

import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_surrealdb/flutter_surrealdb.dart';
import 'package:path/path.dart' as p;

/// Namespace/database used for the wire-compatibility fixtures.
const String compatNs = 'compat';
const String compatDb = 'compat';

/// Directory (relative to the current working directory) that holds one
/// subdirectory per engine version, each containing a SurrealKV database
/// written by that version of the engine.
const String fixturesRoot = 'data';

/// Canonical dataset written for the current engine version and verified for
/// every previously written version.
///
/// Keep this stable: changing it would break compatibility checks against
/// fixtures written by older versions. Each entry is the exact record content
/// (including its `id`) that must round-trip across engine versions.
final List<Map<String, dynamic>> compatRecords = [
  {
    'id': const DBRecord('person', 'alice'),
    'name': 'Alice',
    'age': 30,
    'height': 1.68,
    'active': true,
    'tags': ['admin', 'user'],
    'address': {'city': 'NYC', 'zip': '10001'},
    'score': null,
  },
  {
    'id': const DBRecord('person', 'bob'),
    'name': 'Bob',
    'age': 25,
    'height': 1.80,
    'active': false,
    'tags': ['user'],
    'address': {'city': 'LA', 'zip': '90001'},
    'score': 99,
  },
];

/// Writes [compatRecords] into the database on the current connection.
Future<void> seedDatabase(SurrealDB db) async {
  for (final record in compatRecords) {
    final id = record['id'] as DBRecord;
    final data = Map<String, dynamic>.of(record)..remove('id');
    await db.upsert(id, data);
  }
}

/// Reads the database back and asserts that [compatRecords] round-trip exactly.
///
/// Any mismatch (missing record, changed value, type drift) fails the check,
/// which is the signal that the on-disk/wire format is not compatible.
Future<void> verifyDatabase(SurrealDB db) async {
  final all = await db.select(const DBTable('person'));
  expect(all, isA<List>(),
      reason: 'select(person) should return a list of records');
  expect((all as List).length, equals(compatRecords.length),
      reason: 'person table should contain all seeded records');

  for (final expected in compatRecords) {
    final id = expected['id'] as DBRecord;
    final record = await db.select(id);
    expect(record, isA<Map>(), reason: 'record $id should exist');
    expect(record, equals(expected),
        reason: 'record $id should match the canonical content');
  }
}

/// Builds a SurrealKV endpoint for [dir], normalising Windows backslashes so
/// the path survives SurrealDB's `split_once("://")` endpoint parsing. A
/// relative path is used on purpose to avoid Windows drive-letter colons
/// confusing the parser.
String endpointFor(Directory dir) =>
    'surrealkv://${dir.path.replaceAll('\\', '/')}';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => await SurrealDB.ensureInitialized());
  dotest();
}

void dotest() {
  String version = 'unknown';
  setUpAll(() async {
    final surreal = await SurrealDB.connect('mem://');
    version = await surreal.engineVersion();
    surreal.dispose();
  });

  // Writes the canonical dataset using the current engine's serialization into
  // `data/<current-version>/`, replacing any previously written fixture for
  // this version, and verifies it reads back on the same connection.
  test('Write current serialization', () async {
    final dir = Directory(p.join(fixturesRoot, version));
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
    await dir.create(recursive: true);
    print('Writing canonical dataset for version $version into ${dir.absolute.path}');

    final surreal = await SurrealDB.connect(endpointFor(dir));
    await surreal.use(db: compatDb, ns: compatNs);
    await seedDatabase(surreal);
    await verifyDatabase(surreal);
    surreal.dispose();
  });

  // Opens every fixture directory (one per engine version) and verifies the
  // canonical data round-trips. A failure means the on-disk/wire format is not
  // compatible between that version and the current one.
  //
  // The current version's own directory is skipped: SurrealKV holds an OS-level
  // lock on an open database for the lifetime of the process (its background
  // sync thread keeps a handle alive and there is no Drop-based shutdown), so a
  // directory can only be opened once per process. The write test above already
  // opened and verified the current version's directory.
  test('Read previous serializations', () async {
    final root = Directory(fixturesRoot);
    final failures = <Object>[];
    var checked = 0;
    // On a first run there may be no fixtures yet (only the current version,
    // written above, exists) so there is nothing to verify here.
    if (root.existsSync()) {
      for (final entry in root.listSync()) {
        if (entry is! Directory) continue;
        final fixtureVersion = p.basename(entry.path);
        if (fixtureVersion == version) continue; // locked this run, see above

        SurrealDB? surreal;
        try {
          surreal = await SurrealDB.connect(endpointFor(entry));
          await surreal.use(db: compatDb, ns: compatNs);
          await verifyDatabase(surreal);
          checked++;
        } catch (e, st) {
          failures.add('version $fixtureVersion:\n$e\n$st');
        } finally {
          surreal?.dispose();
        }
      }
    }

    expect(
      failures,
      isEmpty,
      reason:
          'incompatible fixture(s) detected (${failures.length} failed, $checked ok):\n\n${failures.join('\n\n')}',
    );
  });
}
