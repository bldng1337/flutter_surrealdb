import 'dart:async';
import 'dart:convert';

import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_surrealdb/flutter_surrealdb.dart';
import 'package:flutter_surrealdb/error/query.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => await SurrealDB.ensureInitialized());
  dotest();
}

void dotest() {
  late SurrealDB db;

  setUp(() async {
    db = await SurrealDB.connect("mem://");
    await db.use(db: "test", ns: "test");
  });

  tearDown(() {
    db.dispose();
  });

  group('Missing table', () {
    test('select on a never-defined table returns an empty list', () async {
      final result = await db.select(const DBTable('never_defined_table'));
      expect(result, isA<List>());
      expect(result, isEmpty);
    });

    test('select of a record on a never-defined table returns null', () async {
      final result =
          await db.select(const DBRecord('never_defined_table', 'some_id'));
      expect(result, isNull);
    });

    test('live on a never-defined table works and receives notifications',
        () async {
      const table = DBTable('never_defined_live_table');
      final notificationReceived = Completer<Notification>();

      final subscription = db.live(table).listen((notification) {
        if (notification.action == Action.create) {
          notificationReceived.complete(notification);
        }
      });

      await Future.delayed(const Duration(milliseconds: 100));
      await db.create(table, {'name': 'test'});

      final notification = await notificationReceived.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('Notification not received'),
      );
      expect(notification.result['name'], equals('test'));

      await subscription.cancel();
    });

    test('raw query on a never-defined table throws QueryError', () async {
      // Raw statements keep server semantics: the error is reported in the
      // statement result instead of being normalized by the select fallback.
      await expectLater(
        db.query('SELECT * FROM never_defined_table'),
        throwsA(isA<QueryError>()),
      );
    });
  });

  group('Query errors', () {
    test('a failing statement throws instead of returning the message',
        () async {
      await expectLater(
        db.query("THROW 'expected failure'"),
        throwsA(isA<QueryError>()),
      );
    });

    test('a parse error throws', () async {
      // Parse errors fail the whole RPC call, surfacing as an exception from
      // the Rust bridge rather than a statement-level QueryError.
      await expectLater(
        db.query('SELECT * FROM'),
        throwsException,
      );
    });
  });

  group('Value equality', () {
    test('DBTable compares by table name', () async {
      expect(DBTable('users'), equals(DBTable('users')));
      expect(DBTable('users'), isNot(equals(DBTable('other'))));
      expect({DBTable('users'), DBTable('other')}.contains(DBTable('users')),
          isTrue);
      final byKey = {DBTable('users'): 1};
      expect(byKey[DBTable('users')], equals(1));
    });

    test('record ids round-trip through the engine with equality', () async {
      const record = DBRecord('equality_table', 'fixed');
      await db.create(record, {'v': 1});
      final selected = await db.select(record);
      expect(selected, isA<Map>());
      expect(selected['id'], equals(record));
    });
  });

  group('Durations', () {
    test('positive durations round-trip', () async {
      final result = await db.query(
        'RETURN \$d',
        vars: {'d': const Duration(microseconds: 1500999)},
      );
      expect(result, [const Duration(microseconds: 1500999)]);
    });

    test('negative durations fail with a clear error', () async {
      await expectLater(
        db.query('RETURN \$d', vars: {'d': const Duration(seconds: -1)}),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });

  group('Export / Import', () {
    test('streamed export round-trips through import', () async {
      await db.insert(const DBTable('export_table'), [
        {'id': const DBRecord('export_table', 'one'), 'name': 'One'},
        {'id': const DBRecord('export_table', 'two'), 'name': 'Two'},
      ]);

      final chunks = await db.exportStream().toList();
      expect(chunks, isNotEmpty);
      final dump = utf8.decode(chunks.expand((chunk) => chunk).toList());
      expect(dump, contains('export_table'));

      final restored = await SurrealDB.connect("mem://");
      try {
        await restored.use(db: "test", ns: "test");
        await restored.import(data: dump);
        final rows = await restored.select(const DBTable('export_table'));
        expect(rows, isA<List>());
        expect(rows.length, equals(2));
      } finally {
        await restored.dispose();
      }
    });

    test('buffered export matches the streamed export', () async {
      await db.insert(const DBTable('export_buffered'),
          {'id': const DBRecord('export_buffered', 'x'), 'n': 1});

      final buffered = await db.export();
      final streamed =
          utf8.decode(await db.exportStream().toList().then((chunks) =>
              chunks.expand((chunk) => chunk).toList()));
      expect(buffered, equals(streamed));
      expect(buffered, contains('export_buffered'));
    });
  });

  group('Notification stream lifecycle', () {
    test('notifications still work after every live stream was cancelled',
        () async {
      const table = DBTable('lifecycle_table');

      // Start and fully cancel one live query first.
      final first = Completer<Notification>();
      final firstSubscription = db.live(table).listen((n) {
        if (n.action == Action.create && !first.isCompleted) {
          first.complete(n);
        }
      });
      await Future.delayed(const Duration(milliseconds: 100));
      await db.create(table, {'round': 1});
      await first.future.timeout(const Duration(seconds: 5));
      await firstSubscription.cancel();

      // A brand new live query on the same engine must still receive
      // notifications (this used to break the whole stream for good).
      final second = Completer<Notification>();
      final secondSubscription = db.live(table).listen((n) {
        if (n.action == Action.create && !second.isCompleted) {
          second.complete(n);
        }
      });
      await Future.delayed(const Duration(milliseconds: 100));
      await db.create(table, {'round': 2});

      final notification = await second.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('Notification not received'),
      );
      expect(notification.result['round'], equals(2));

      await secondSubscription.cancel();
    });
  });
}
