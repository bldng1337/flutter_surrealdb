import 'dart:convert';

import 'package:flutter_surrealdb/flutter_surrealdb.dart';

//TODO: Parse https://pub.dev/packages/geojson_vi
dynamic surrencodeType(String value) {
  final ret = json.decode(value, reviver: (key, value) {
    if (value is Map) {
      if (value.length == 1) {
        if (value.containsKey("Strand")) {
          return value["Strand"];
        } else if (value.containsKey("Bool")) {
          return value["Bool"];
        } else if (value.containsKey("Number")) {
          if (value["Number"].containsKey("Int")) {
            return value["Number"]["Int"];
          }
          if (value["Number"].containsKey("Float")) {
            return value["Number"]["Float"];
          }
        } else if (value.containsKey("Array")) {
          return value["Array"];
        } else if (value.containsKey("String")) {
          return value["String"];
        } else if (value.containsKey("Thing")) {
          return DBRecord.fromJson(
              {"tb": value["Thing"]["tb"], "id": value["Thing"]["id"]});
        } else if (value.containsKey("Object")) {
          return value["Object"];
        } else if (value.containsKey("Datetime")) {
          return DateTime.tryParse(value["Datetime"]);
        } else if (value.containsKey("Uuid")) {
          return value["Uuid"];
        }
      }
    }
    if (value == "Null" || value == "None") {
      return null;
    }
    return value;
  });
  return ret;
}

String surrdecodeType(dynamic value) {
  final ret = json.encode(wrap(value));
  return ret;
}

dynamic wrap(dynamic value) {
  if(value ==null){
    return "Null";
  }
  return switch (value) {
    final List<dynamic> val => {"Array": val.map(wrap).toList()},
    final String val => {"Strand": val},
    final bool val => {"Bool": val},
    final int val => {
        "Number": {"Int": val}
      },
    final num val => {
        "Number": {"Float": val.toDouble()}
      },
    final DateTime val => wrapDateTime(val),
    final DBRecord val => wrap(val.toJson()),
    final Map<String, dynamic> val => wrapMap(val),
    _ => wrap(value.toJson()),
  };
}

Map<String, dynamic> wrapDateTime(DateTime value) {
  if (value.isUtc) {
    return {"Datetime": value.toIso8601String()};
  }
  return {
    "Datetime":
        "${value.toIso8601String()}+${_twoDigits(value.timeZoneOffset.inHours)}:${_twoDigits(value.timeZoneOffset.inMinutes % 60)}"
  };
}

String _twoDigits(int n) {
  if (n >= 10) return "$n";
  return "0$n";
}

Map<String, dynamic> wrapMap(Map<String, dynamic> map) {
  if (map.containsKey("tb") && map.containsKey("id")) {
    return {
      "Thing": {
        "tb": map["tb"],
        "id": {"String": map["id"]}
      }
    };
  }
  final wrapped = map.map((key, value) => MapEntry(key, wrap(value)));
  return {"Object": wrapped};
}
