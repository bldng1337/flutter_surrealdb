import 'dart:async';
import 'package:uuid/uuid_value.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_surrealdb/flutter_surrealdb.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => await SurrealDB.ensureInitialized());
  dotest();
}

void dotest() {
  group('Live Query Tests', () {
    late SurrealDB db;
    const testTable = DBTable('live_test');

    setUp(() async {
      db = await SurrealDB.connect("mem://");
      await db.use(db: "test", ns: "test");
      await db.delete(testTable);
    });

    tearDown(() {
      db.dispose();
    });

    test('should create live query and receive create notification', () async {
      final notificationReceived = Completer<Notification>();

      final subscription = db.live(testTable).listen((notification) {
        if (notification.action == Action.create) {
          notificationReceived.complete(notification);
        }
      });

      await Future.delayed(const Duration(milliseconds: 100));

      await db.create(testTable, {'name': 'test', 'value': 42});

      final notification = await notificationReceived.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('Notification not received'),
      );

      expect(notification.action, equals(Action.create));
      expect(notification.result, isNotNull);
      expect(notification.result['name'], equals('test'));
      expect(notification.result['value'], equals(42));

      await subscription.cancel();
    });

    test('should receive update notification', () async {
      final createReceived = Completer<Notification>();
      final updateReceived = Completer<Notification>();
      late DBRecord record;

      final subscription = db.live(testTable).listen((notification) {
        if (notification.action == Action.create) {
          createReceived.complete(notification);
          record = notification.result['id'];
        } else if (notification.action == Action.update) {
          updateReceived.complete(notification);
        }
      });

      await Future.delayed(const Duration(milliseconds: 100));

      await db.create(testTable, {'name': 'initial', 'value': 1});
      await createReceived.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () =>
            throw TimeoutException('Create notification not received'),
      );

      await db.update(record, {'name': 'updated', 'value': 2});

      final notification = await updateReceived.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () =>
            throw TimeoutException('Update notification not received'),
      );

      expect(notification.action, equals(Action.update));
      expect(notification.result['name'], equals('updated'));
      expect(notification.result['value'], equals(2));

      await subscription.cancel();
    });

    test('should receive delete notification', () async {
      final createReceived = Completer<Notification>();
      final deleteReceived = Completer<Notification>();
      late DBRecord record;

      final subscription = db.live(testTable).listen((notification) {
        if (notification.action == Action.create) {
          createReceived.complete(notification);
          record = notification.result['id'];
        } else if (notification.action == Action.delete) {
          deleteReceived.complete(notification);
        }
      });

      await Future.delayed(const Duration(milliseconds: 100));

      await db.create(testTable, {'name': 'to_delete'});
      await createReceived.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () =>
            throw TimeoutException('Create notification not received'),
      );

      await db.delete(record);

      final notification = await deleteReceived.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () =>
            throw TimeoutException('Delete notification not received'),
      );

      expect(notification.action, equals(Action.delete));

      await subscription.cancel();
    });

    test('should handle multiple notifications in sequence', () async {
      final notifications = <Notification>[];
      final receivedCompleter = Completer<void>();
      const expectedCount = 3;
      int count = 0;

      final subscription = db.live(testTable).listen((notification) {
        notifications.add(notification);
        count++;
        if (count >= expectedCount) {
          receivedCompleter.complete();
        }
      });

      await Future.delayed(const Duration(milliseconds: 100));

      for (int i = 0; i < expectedCount; i++) {
        await db.create(testTable, {'index': i});
      }

      await receivedCompleter.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () =>
            throw TimeoutException('Not all notifications received'),
      );

      expect(notifications.length, equals(expectedCount));
      for (var i = 0; i < expectedCount; i++) {
        expect(notifications[i].action, equals(Action.create));
        expect(notifications[i].result['index'], equals(i));
      }

      await subscription.cancel();
    });

    test('should handle multiple concurrent live queries', () async {
      const table1 = DBTable('live_test_1');
      const table2 = DBTable('live_test_2');

      final notifications1 = <Notification>[];
      final notifications2 = <Notification>[];
      final allReceived = Completer<void>();
      int receivedCount = 0;
      const expectedPerTable = 2;

      final sub1 = db.live(table1).listen((n) {
        notifications1.add(n);
        receivedCount++;
        if (receivedCount >= expectedPerTable * 2) allReceived.complete();
      });

      final sub2 = db.live(table2).listen((n) {
        notifications2.add(n);
        receivedCount++;
        if (receivedCount >= expectedPerTable * 2) allReceived.complete();
      });

      await Future.delayed(const Duration(milliseconds: 100));

      for (int i = 0; i < expectedPerTable; i++) {
        await db.create(table1, {'table': 1, 'index': i});
        await db.create(table2, {'table': 2, 'index': i});
        await Future.delayed(const Duration(milliseconds: 50));
      }

      await allReceived.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () =>
            throw TimeoutException('Not all notifications received'),
      );

      expect(notifications1.length, equals(expectedPerTable));
      expect(notifications2.length, equals(expectedPerTable));

      for (var n in notifications1) {
        expect(n.result['table'], equals(1));
      }

      for (var n in notifications2) {
        expect(n.result['table'], equals(2));
      }

      await sub1.cancel();
      await sub2.cancel();
    });

    test('should handle rapid successive operations', () async {
      final notifications = <Notification>[];
      final receivedCompleter = Completer<void>();
      const operations = 50;
      int count = 0;

      final subscription = db.live(testTable).listen((notification) {
        notifications.add(notification);
        count++;
        if (count >= operations) {
          receivedCompleter.complete();
        }
      });

      await Future.delayed(const Duration(milliseconds: 100));

      for (int i = 0; i < operations; i++) {
        await db.create(testTable, {'index': i});
      }

      await receivedCompleter.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () =>
            throw TimeoutException('Not all rapid operations received'),
      );

      expect(notifications.length, equals(operations));
      expect(notifications.every((n) => n.action == Action.create), isTrue);

      await subscription.cancel();
    });
  });
}
