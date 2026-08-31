import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated_io.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_surrealdb/flutter_surrealdb.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => await SurrealDB.ensureInitialized());
  dotest();
}

/// Creates a fresh directory holding a database file and returns the
/// `surrealkv://` endpoint for it.
Future<String> tempEndpoint(String name) async {
  final dir = await Directory.systemTemp.createTemp('surrealdb_share_$name');
  return 'surrealkv://${dir.path}${Platform.pathSeparator}$name.db';
}

void dotest() {
  group('Shared Connections', () {
    test('multiple clients attach to one shared connection', () async {
      final endpoint = await tempEndpoint('basic');
      final a = await SurrealDB.connect(endpoint, shareTag: 'basic');
      await a.use(ns: 'test', db: 'test');
      await a.query('DEFINE TABLE IF NOT EXISTS t');
      await a.create(const DBTable('t'), {'v': 1});

      // A second client attaches instead of failing on the file lock and
      // sees the data written through the first one.
      final b = await SurrealDB.connect(endpoint, shareTag: 'basic');
      await b.use(ns: 'test', db: 'test');
      expect(await b.select(const DBTable('t')), hasLength(1));

      // Disposing one client leaves the shared connection working.
      await a.dispose();
      await b.create(const DBTable('t'), {'v': 2});
      expect(await b.select(const DBTable('t')), hasLength(2));
      await b.dispose();

      // The last client out released the file: a fresh connect reopens it
      // and still sees the data.
      final c = await SurrealDB.connect(endpoint, shareTag: 'basic');
      await c.use(ns: 'test', db: 'test');
      expect(await c.select(const DBTable('t')), hasLength(2));
      await c.dispose();
    });

    test('another isolate attaches while the main isolate holds the database',
        () async {
      final endpoint = await tempEndpoint('isolate');
      final a = await SurrealDB.connect(endpoint, shareTag: 'isolate');
      await a.use(ns: 'test', db: 'test');
      await a.query('DEFINE TABLE IF NOT EXISTS t');
      await a.create(const DBTable('t'), {'v': 'main'});

      // This is the background-service scenario: a second isolate connects
      // to the same file, which would fail on the file lock without the
      // share tag.
      final count = await Isolate.run(() async {
        await SurrealDB.ensureInitialized();
        final b = await SurrealDB.connect(endpoint, shareTag: 'isolate');
        await b.use(ns: 'test', db: 'test');
        await b.create(const DBTable('t'), {'v': 'isolate'});
        final rows = await b.select(const DBTable('t'));
        await b.dispose();
        return rows.length;
      });

      expect(count, 2);
      expect(await a.select(const DBTable('t')), hasLength(2));
      await a.dispose();
    });

    test('memory databases can be shared by tag', () async {
      final a = await SurrealDB.connect('mem://', shareTag: 'memory');
      await a.use(ns: 'test', db: 'test');
      await a.query('DEFINE TABLE IF NOT EXISTS t');
      await a.create(const DBTable('t'), {'v': 1});

      final b = await SurrealDB.connect('mem://', shareTag: 'memory');
      await b.use(ns: 'test', db: 'test');
      expect(await b.select(const DBTable('t')), hasLength(1));
      await a.dispose();
      await b.dispose();
    });

    test('attaching with a different endpoint is rejected', () async {
      final endpointA = await tempEndpoint('mismatch_a');
      final endpointB = await tempEndpoint('mismatch_b');
      final a = await SurrealDB.connect(endpointA, shareTag: 'mismatch');

      await expectLater(
        SurrealDB.connect(endpointB, shareTag: 'mismatch'),
        throwsA(isA<AnyhowException>().having(
          (e) => e.message,
          'message',
          contains('already open'),
        )),
      );
      await a.dispose();
    });

    test('attaching with different options is rejected', () async {
      final endpoint = await tempEndpoint('opts');
      final a = await SurrealDB.connect(endpoint,
          shareTag: 'opts', opts: const Options(queryTimeout: 60000));

      await expectLater(
        SurrealDB.connect(endpoint,
            shareTag: 'opts', opts: const Options(queryTimeout: 1000)),
        throwsA(isA<AnyhowException>().having(
          (e) => e.message,
          'message',
          contains('different options'),
        )),
      );

      // The same options, or none at all, attach fine.
      final b = await SurrealDB.connect(endpoint,
          shareTag: 'opts', opts: const Options(queryTimeout: 60000));
      final c = await SurrealDB.connect(endpoint, shareTag: 'opts');
      await b.dispose();
      await c.dispose();
      await a.dispose();
    });

    test('private clients never merge into a shared connection', () async {
      final endpoint = await tempEndpoint('lock');
      final a = await SurrealDB.connect(endpoint, shareTag: 'lock');

      // Without the tag the client wants its own engine and must fail on
      // the file lock, exactly as before sharing existed.
      await expectLater(
        SurrealDB.connect(endpoint),
        throwsA(anything),
      );
      // The same goes for a second, different tag.
      await expectLater(
        SurrealDB.connect(endpoint, shareTag: 'lock_other'),
        throwsA(anything),
      );

      await a.dispose();
      // Once the shared connection is released the file is openable again.
      final b = await SurrealDB.connect(endpoint);
      await b.dispose();
    });

    test('attached clients get isolated sessions', () async {
      final endpoint = await tempEndpoint('sessions');
      final a = await SurrealDB.connect(endpoint, shareTag: 'sessions');
      await a.use(ns: 'test', db: 'a');
      await a.query('DEFINE TABLE IF NOT EXISTS t');
      await a.create(const DBTable('t'), {'v': 1});

      final b = await SurrealDB.connect(endpoint, shareTag: 'sessions');
      // Point b somewhere else: a's `use` must not have leaked into it.
      await b.use(ns: 'test', db: 'b');
      expect(await b.select(const DBTable('t')), isEmpty);

      // Re-pointing b at a's database makes the record visible.
      await b.use(ns: 'test', db: 'a');
      expect(await b.select(const DBTable('t')), hasLength(1));
      await a.dispose();
      await b.dispose();
    });

    test('live notifications reach every attached client', () async {
      final endpoint = await tempEndpoint('live');
      final a = await SurrealDB.connect(endpoint, shareTag: 'live');
      await a.use(ns: 'test', db: 'test');
      await a.query('DEFINE TABLE IF NOT EXISTS t');

      final b = await SurrealDB.connect(endpoint, shareTag: 'live');
      await b.use(ns: 'test', db: 'test');

      final received = Completer<Notification>();
      final sub = b.live(const DBTable('t')).listen((n) {
        if (n.action == Action.create && !received.isCompleted) {
          received.complete(n);
        }
      });
      await Future.delayed(const Duration(milliseconds: 100));

      // Written through a, delivered to b's live query.
      await a.create(const DBTable('t'), {'v': 1});

      final n = await received.future.timeout(const Duration(seconds: 5),
          onTimeout: () => throw TimeoutException('notification not received'));
      expect(n.result['v'], 1);

      await sub.cancel();
      await a.dispose();
      await b.dispose();
    });

    test('closing a client kills only its own live queries', () async {
      final endpoint = await tempEndpoint('lqkill');
      final a = await SurrealDB.connect(endpoint, shareTag: 'lqkill');
      await a.use(ns: 'test', db: 'test');
      await a.query('DEFINE TABLE IF NOT EXISTS t');

      final b = await SurrealDB.connect(endpoint, shareTag: 'lqkill');
      await b.use(ns: 'test', db: 'test');

      final createOnA = Completer<Notification>();
      final subA = a.live(const DBTable('t')).listen((n) {
        if (n.action == Action.create && !createOnA.isCompleted) {
          createOnA.complete(n);
        }
      });
      // Deliberately never cancelled: cancelling would kill the live query
      // that b.dispose() is supposed to kill.
      final killedOnB = Completer<Notification>();
      b.live(const DBTable('t')).listen((n) {
        if (n.action == Action.killed && !killedOnB.isCompleted) {
          killedOnB.complete(n);
        }
      });
      await Future.delayed(const Duration(milliseconds: 100));

      await b.dispose();
      final killed = await killedOnB.future.timeout(const Duration(seconds: 5),
          onTimeout: () => throw TimeoutException('kill notification missing'));
      expect(killed.action, Action.killed);

      // a's live query survived b's shutdown.
      await a.create(const DBTable('t'), {'v': 1});
      final created = await createOnA.future.timeout(const Duration(seconds: 5),
          onTimeout: () => throw TimeoutException('a lost its live query'));
      expect(created.result['v'], 1);

      await subA.cancel();
      await a.dispose();
    });
  });
}
