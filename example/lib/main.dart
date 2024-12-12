import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_surrealdb/flutter_surrealdb.dart';
import 'package:json_view/json_view.dart';
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  await RustLib.init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _query = "";
  Object? _error;
  dynamic _record;

  SurrealDB? _db;

  void init() async {
    final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
    final path = "${appDocumentsDir.path}/test.db";
    print("path: $path");
    final db = await SurrealDB.newFile(path);
    print("Opened DB");
    setState(() {
      _db = db;
    });
  }

  @override
  void initState() {
    init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('flutter_rust_bridge quickstart')),
        body: Center(
            child: _db == null
                ? const Text("Loading...")
                : Column(
                    children: [
                      TextField(
                        onChanged: (query) {
                          setState(() {
                            _query = query;
                          });
                        },
                        maxLines: null,
                      ),
                      TextButton(
                          onPressed: () async {
                            try {
                              final value = await _db!.query(query: _query);
                              setState(() {
                                _error = null;
                                _record = value;
                              });
                            } catch (e) {
                              setState(() {
                                _error = e;
                              });
                            }
                          },
                          child: const Text("Run")),
                      const Divider(),
                      SelectableText(
                        "Result(${_record.runtimeType}): $_record",
                        maxLines: 5,
                      ),
                      if (_error != null)
                        SelectableText("Error: $_error",
                            maxLines: 5,
                            style: const TextStyle(color: Colors.red)),
                      const Divider(),
                      Expanded(
                          child: JsonView(
                        json: _record,
                      ))
                    ],
                  )),
      ),
    );
  }
}
