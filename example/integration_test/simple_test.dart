import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_surrealdb/flutter_surrealdb.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => await RustLib.init());
  test('Can call rust function', () async {
    expect(greet(name: "Tom"), "Hello, Tom!");
  });
  test('Construct a Database', () async {
    final db = await SurrealProxy.newMem();
    expect(db, isA<SurrealProxy>());
    db.dispose();
  });

  test('insert and select', () async {
    final db = await SurrealProxy.newMem();
    await db.useNs(namespace: "test");
    await db.useDb(db: "test");
    var data = {
      "hello": "world",
      "num": 1,
      "bool": true,
      "float": 1.0,
      "string": "test",
      "array": ["test1", "test2"],
      "object": {"test": "test"}
    };
    final insert = await db.insert(res: "test", data: data);
    expect(insert["id"], isA<DBRecord>());
    final DBRecord record = insert["id"];
    data["id"] = record;
    final result = await db.select(resource: "test");
    expect(result, [data]);
    final result2 = await db.select(resource: record.resource);
    expect(result2, data);
    db.dispose();
  });

  test("Wrapper create", () async {
    final db = await SurrealDB.newMem();
    await db.use(db: "test", namespace: "test");
    final insert = await db.create(res: const DBTable("test"));
    expect(insert["id"], isA<DBRecord>());
  });

  test("Wrapper insert and select", () async {
    final db = await SurrealDB.newMem();
    await db.useNs(namespace: "test");
    await db.useDb(db: "test");
    var data = {
      "hello": "world",
      "num": 1,
      "array": ["test1", "test2"],
      "object": {"test": "test"}
    };

    final insert = await db.insert(res: const DBTable("test"), data: data);
    expect(insert["id"], isA<DBRecord>());
    final DBRecord record = insert["id"];
    data["id"] = record;
    final result = await db.select(res: const DBTable("test"));
    expect(result, [data]);
    final result2 = await db.select(res: record);
    expect(result2, data);
  });

  test("Wrapper multiselectLive", () async {
    final db = await SurrealDB.newMem();
    await db.useNs(namespace: "test");
    await db.useDb(db: "test");
    var data = {
      "hello": "world",
      "num": 1,
      "array": ["test1", "test2"],
      "object": {"test": "test"}
    };
    final insert = await db.insert(res: const DBTable("test"), data: data);
    expect(insert["id"], isA<DBRecord>());
    final DBRecord record = insert["id"];
    data["id"] = record;
    var lateststream;
    db.selectStream(res: const DBTable("test")).listen((event) {
      lateststream = event;
    });
    data["hello"] = "world2";
    await db.updateContent(res: record, data: data);
    await Future.delayed(const Duration(seconds: 1));
    expect(lateststream, data);
  });

  test("Wrapper updateContent", () async {
    final db = await SurrealDB.newMem();
    await db.useNs(namespace: "test");
    await db.useDb(db: "test");
    var data = {
      "hello": "world",
      "num": 1,
      "array": ["test1", "test2"],
      "object": {"test": "test"}
    };
    final insert = await db.insert(res: const DBTable("test"), data: data);
    expect(insert["id"], isA<DBRecord>());
    final DBRecord record = insert["id"];
    data["id"] = record;
    data["hello"] = "world2";
    await db.updateContent(res: record, data: data);
    final result = await db.select(res: record);
    expect(result, data);
  });

  test("Wrapper updateMerge", () async {
    final db = await SurrealDB.newMem();
    await db.useNs(namespace: "test");
    await db.useDb(db: "test");
    var data = {
      "hello": "world",
      "num": 1,
      "array": ["test1", "test2"],
      "object": {"test": "test"}
    };
    final insert = await db.insert(res: const DBTable("test"), data: data);
    expect(insert["id"], isA<DBRecord>());
    final DBRecord record = insert["id"];
    data["id"] = record;
    await db.updateMerge(res: record, data: {"hello": "world2"});
    data["hello"] = "world2";
    final result = await db.select(res: record);
    expect(result, data);
  });

  test("Wrapper selectStream", () async {
    final db = await SurrealDB.newMem();
    await db.useNs(namespace: "test");
    await db.useDb(db: "test");
    var data = {
      "hello": "world",
      "num": 1,
      "array": ["test1", "test2"],
      "object": {"test": "test"}
    };
    final insert = await db.insert(res: const DBTable("test"), data: data);
    expect(insert["id"], isA<DBRecord>());
    final DBRecord record = insert["id"];
    data["id"] = record;
    var lateststream;
    db.selectStream(res: record).listen((event) {
      lateststream = event;
    });
    data["hello"] = "world2";
    await db.updateContent(res: record, data: data);
    await Future.delayed(const Duration(seconds: 1));
    expect(lateststream, data);
  });

  test("Wrapper query", () async {
    final db = await SurrealDB.newMem();
    await db.useNs(namespace: "test");
    await db.useDb(db: "test");
    var data = {
      "hello": "world",
      "num": 1,
      "array": ["test1", "test2"],
      "object": {"test": "test"}
    };
    final insert = await db.insert(res: const DBTable("test"), data: data);
    expect(insert["id"], isA<DBRecord>());
    final DBRecord record = insert["id"];
    data["id"] = record;
    final result = await db.query(query: "SELECT * FROM test");
    expect(result, [data]);
  });

  test("Wrapper query", () async {
    final db = await SurrealDB.newMem();
    await db.useNs(namespace: "test");
    await db.useDb(db: "test");
    var data = {
      "hello": "world",
      "num": 1,
      "array": ["test1", "test2"],
      "object": {"test": "test"}
    };
    final insert = await db.insert(res: const DBTable("test"), data: data);
    expect(insert["id"], isA<DBRecord>());
    final DBRecord record = insert["id"];
    data["id"] = record;
    final result =
        await db.query(query: "SELECT * FROM \$id", vars: {"id": record});
    expect(result, [data]);
  });

  test("Wrapper query", () async {
    final db = await SurrealDB.newMem();
    await db.useNs(namespace: "test");
    await db.useDb(db: "test");
    var data = {
      "hello": "world",
      "num": 1,
      "array": ["test1", "test2"],
      "object": {"test": "test"}
    };
    final insert = await db.insert(res: const DBTable("test"), data: data);
    expect(insert["id"], isA<DBRecord>());
    final DBRecord record = insert["id"];
    data["id"] = record;
    final result = await db.query(query: "RETURN false;");
    print(result);
  });
}