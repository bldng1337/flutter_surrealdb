import 'dart:typed_data';

import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_surrealdb/flutter_surrealdb.dart';
import 'package:uuid/uuid.dart';
import 'package:uuid/uuid_value.dart';
import 'package:uuid/v4.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => await RustLib.init());
  test('Construct a Database', () async {
    final db = await SurrealDB.connect("mem://");
    db.dispose();
  });

  test('insert and select', () async {
    final db = await SurrealDB.connect("mem://");
    await db.use(db: "test", ns: "test");
    var data = {
      "hello": "world",
      "num": 1,
      "bool": true,
      "float": 1.0,
      "string": "test",
      "array": ["test1", "test2"],
      "object": {"test": "test"}
    };
    final insert = await db.insert(const DBTable("test"), data);
    expect(insert[0]["id"], isA<DBRecord>());
    final DBRecord record = insert[0]["id"];
    data["id"] = record;
    final result = await db.select(const DBTable("test"));
    expect(result, [data]);
    final result2 = await db.select(record);
    expect(result2, data);
    db.dispose();
  });

  test('select type', () async {
    final db = await SurrealDB.connect("mem://");
    await db.use(db: "test", ns: "test");
    var data = {
      "hello": "world",
      "num": 1,
      "bool": true,
      "float": 1.0,
      "string": "test",
      "array": ["test1", "test2"],
      "object": {"test": "test"}
    };
    final insert = await db.insert(const DBTable("test"), data);
    expect(insert[0], isA<Map<String, dynamic>>());
    final select = await db.select(insert[0]["id"]);
    expect(select, isA<Map<String, dynamic>>());
  });

  test("Wrapper create", () async {
    final db = await SurrealDB.connect("mem://");
    await db.use(db: "test", ns: "test");
    final insert = await db.insert(const DBTable("test"), {"some": "data"});
    expect(insert[0]["id"], isA<DBRecord>());
  });

  test("live select", () async {
    final db = await SurrealDB.connect("mem://");
    await db.use(db: "test", ns: "test");
    var data = {
      "hello": "world",
      "num": 1,
      "array": ["test1", "test2"],
      "object": {"test": "test"}
    };
    final insert = await db.insert(const DBTable("test"), data);
    expect(insert[0]["id"], isA<DBRecord>());
    final DBRecord record = insert[0]["id"];
    data["id"] = record;
    var lateststream;
    final streamid = await db.query("LIVE SELECT * FROM test");
    expect(streamid[0], isA<UuidValue>());
    db.liveOf(streamid[0]).listen((event) {
      lateststream = event.result;
    });
    data["hello"] = "world2";
    await db.update(record, data);
    await Future.delayed(const Duration(seconds: 1));
    expect(lateststream, data);
  });

  test("Wrapper insert and select", () async {
    final db = await SurrealDB.connect("mem://");
    await db.use(db: "test", ns: "test");
    var data = {
      "hello": "world",
      "num": 1,
      "array": ["test1", "test2"],
      "object": {"test": "test"}
    };

    final insert = await db.insert(const DBTable("test"), data);
    expect(insert[0]["id"], isA<DBRecord>());
    final DBRecord record = insert[0]["id"];
    data["id"] = record;
    final result = await db.select(const DBTable("test"));
    expect(result, [data]);
    final result2 = await db.select(record);
    expect(result2, data);
  });

  test("Wrapper multi watch", () async {
    final db = await SurrealDB.connect("mem://");
    await db.use(db: "test", ns: "test");
    var data = {
      "hello": "world",
      "num": 1,
      "array": ["test1", "test2"],
      "object": {"test": "test"}
    };
    final insert = await db.insert(const DBTable("test"), data);
    expect(insert[0]["id"], isA<DBRecord>());
    final DBRecord record = insert[0]["id"];
    data["id"] = record;
    var lateststream;
    db.live(const DBTable("test")).listen((event) {
      expect(event.action, Action.update);
      lateststream = event.result;
    });
    data["hello"] = "world2";
    await db.update(record, data);
    await Future.delayed(const Duration(seconds: 1));
    expect(lateststream, data);
  });

  test("Wrapper updateContent", () async {
    final db = await SurrealDB.connect("mem://");
    await db.use(db: "test", ns: "test");
    var data = {
      "hello": "world",
      "num": 1,
      "array": ["test1", "test2"],
      "object": {"test": "test"}
    };
    final insert = await db.insert(const DBTable("test"), data);
    expect(insert[0]["id"], isA<DBRecord>());
    final DBRecord record = insert[0]["id"];
    data["id"] = record;
    data["hello"] = "world2";
    await db.update(record, data);
    final result = await db.select(record);
    expect(result, data);
  });

  test("Wrapper updateMerge", () async {
    final db = await SurrealDB.connect("mem://");
    await db.use(db: "test", ns: "test");
    var data = {
      "hello": "world",
      "num": 1,
      "array": ["test1", "test2"],
      "object": {"test": "test"}
    };
    final insert = await db.insert(const DBTable("test"), data);
    expect(insert[0]["id"], isA<DBRecord>());
    final DBRecord record = insert[0]["id"];
    data["id"] = record;
    await db.update(record, {"hello": "world2"}, dataExpr: DataExpr.merge);
    data["hello"] = "world2";
    final result = await db.select(record);
    expect(result, data);
  }, skip: true);

  test("Wrapper watch", () async {
    final db = await SurrealDB.connect("mem://");
    await db.use(db: "test", ns: "test");
    var data = {
      "hello": "world",
      "num": 1,
      "array": ["test1", "test2"],
      "object": {"test": "test"}
    };
    final insert = await db.insert(const DBTable("test"), data);
    expect(insert[0]["id"], isA<DBRecord>());
    final DBRecord record = insert[0]["id"];
    data["id"] = record;
    var lateststream;
    db.live(record.table).listen((event) {
      lateststream = event.result;
    });
    data["hello"] = "world2";
    await db.update(record, data);
    await Future.delayed(const Duration(seconds: 1));
    expect(lateststream, data);
  });

  test("Wrapper query", () async {
    final db = await SurrealDB.connect("mem://");
    await db.use(db: "test", ns: "test");
    var data = {
      "hello": "world",
      "num": 1,
      "array": ["test1", "test2"],
      "object": {"test": "test"}
    };
    final insert = await db.insert(const DBTable("test"), data);
    expect(insert[0]["id"], isA<DBRecord>());
    final DBRecord record = insert[0]["id"];
    data["id"] = record;
    final result = await db.query("SELECT * FROM test");
    expect(result, [
      [data]
    ]);
  });

  test("Wrapper query2", () async {
    final db = await SurrealDB.connect("mem://");
    await db.use(db: "test", ns: "test");
    var data = {
      "hello": "world",
      "num": 1,
      "array": ["test1", "test2"],
      "object": {"test": "test"}
    };
    final insert = await db.insert(const DBTable("test"), data);
    expect(insert[0]["id"], isA<DBRecord>());
    final DBRecord record = insert[0]["id"];
    data["id"] = record;
    final result = await db.query("SELECT * FROM \$id", vars: {"id": record});
    expect(result, [
      [data]
    ]);
  });

  test("Wrapper query3", () async {
    final db = await SurrealDB.connect("mem://");
    await db.use(db: "test", ns: "test");
    var data = {
      "hello": "world",
      "num": 1,
      "array": ["test1", "test2"],
      "object": {"test": "test"}
    };
    final insert = await db.insert(const DBTable("test"), data);
    expect(insert[0]["id"], isA<DBRecord>());
    final DBRecord record = insert[0]["id"];
    data["id"] = record;
    final result = await db.query("RETURN false;");
    expect(result, [false]);
  });

  test("Encoding", () async {
    final Map<String, dynamic> obj = {
      "sid": const DBRecord("test", "test"),
      "num": 2,
      "num2": 2.3,
      "bool": true,
      "null": null,
      "string": "test",
      "array": ["test1", "test2"],
      "object": {"test": "test"},
      "duration": const Duration(seconds: 10, milliseconds: 500),
      "datetimeutc": DateTime.now().toUtc(),
      "uuid": "a75d0e30-3eb1-4732-8f90-668e4af81921",
      "uuid2": UuidValue.fromString(const UuidV4().generate()),
      "bytes": Uint8List.fromList([1, 2, 3]),
    };
    final decoded = decodeDBData(encodeDBData(obj));
    expect(decoded, obj);
  });

  test("Test datatypes", () async {
    final db = await SurrealDB.connect("mem://");
    await db.use(db: "test", ns: "test");
    var data = {
      "hello": "world",
      "num": 1,
      "array": ["test1", "test2"],
      "object": {"test": "test"}
    };
    final insert = await db.insert(const DBTable("test"), data);
    expect(insert[0]["id"], isA<DBRecord>());
    final DBRecord record = insert[0]["id"];
    data["id"] = record;
    final Map<String, dynamic> obj = {
      "sid": const DBRecord("test", "test"),
      "num": 2,
      "num2": 2.3,
      "bool": true,
      "null": null,
      "string": "test",
      "array": ["test1", "test2"],
      "object": {"test": "test"},
      // "duration": const Duration(seconds: 10, milliseconds: 500),
      "datetimeutc": DateTime.now().toUtc(),
      "uuid": "a75d0e30-3eb1-4732-8f90-668e4af81921",
    };

    final result = await db.query("RETURN \$obj;", vars: {"obj": obj});
    expect(result, [obj]);
  });
}
