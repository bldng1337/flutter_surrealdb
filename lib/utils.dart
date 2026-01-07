import 'dart:typed_data';

import 'package:flutter_surrealdb/data/ressource.dart';
import 'package:cbor/cbor.dart';
import 'package:uuid/uuid.dart';

CborValue encodeDateTime(DateTime value) {
  final val = value.toUtc();
  return CborList([
    CborInt(BigInt.from((val.millisecondsSinceEpoch / 1000).floor())),
    CborInt(BigInt.from(
        val.microsecond * 1000 + (val.millisecondsSinceEpoch % 1000) * 1000000))
  ], tags: [
    12
  ]);
}

DateTime decodeDateTime(CborList value) {
  return DateTime.fromMillisecondsSinceEpoch(
          (value.first as CborInt).toInt() * 1000,
          isUtc: true)
      .add(Duration(microseconds: (value.last as CborInt).toInt() ~/ 1000));
}

// TODO: fix params
// TODO: Range
// TODO: Geometry
// TODO: UUID
// TODO: Insert Relation Table
CborValue encodeDBData(dynamic data) {
  return switch (data) {
    final Uint8List a => CborBytes(a),
    final String a => CborString(a),
    final int a => CborInt(BigInt.from(a)),
    final DBTable a => CborString(a.tb, tags: [7]),
    final DBRecord a =>
      CborList([CborString(a.tb), encodeDBData(a.id)], tags: [8]),
    final DateTime a => encodeDateTime(a),
    final Duration a => CborList([
        CborInt(BigInt.from(a.inSeconds)),
        CborInt(BigInt.from(
            (a.inMicroseconds - a.inSeconds * Duration.microsecondsPerSecond) *
                1000))
      ], tags: [
        14
      ]),
    final BigInt a => CborBigInt(a),
    final double a => CborFloat(a),
    final UuidValue a => CborBytes(a.toBytes(), tags: [37]),
    final bool a => CborBool(a),
    final List a => CborList(a.map(encodeDBData).toList()),
    final Map a =>
      CborMap(a.map((k, v) => MapEntry(encodeDBData(k), encodeDBData(v)))),
    final value => (() {
        if (value == null) {
          return const CborNull();
        }
        try {
          return encodeDBData(value.toSurrealObject());
        } on NoSuchMethodError {}
        try {
          return value.toCbor() as CborValue;
        } on NoSuchMethodError {}
        try {
          return encodeDBData(value.toJson());
        } on NoSuchMethodError {}
        throw UnsupportedError(
            'Surreal[Encode]: value of type ${value.runtimeType} is not encodable');
      })(),
  };
}

dynamic decodeDBData(CborValue value) {
  if (value.tags.isNotEmpty) {
    int tag = value.tags.first;
    switch (tag) {
      case 6:
        return null;
      case 7:
        return DBTable(value.toString());
      case 8:
        if (value is! CborList || value.length != 2) {
          throw ArgumentError("Surreal[Decode]: Invalid record");
        }
        return DBRecord(value.first.toString(), decodeDBData(value.last));
      case 12:
        if (value is! CborList || value.length != 2) {
          throw ArgumentError("Surreal[Decode]: Invalid date");
        }
        return decodeDateTime(value);
      case 14:
        if (value is! CborList || value.length != 2) {
          throw ArgumentError("Surreal[Decode]: Invalid duration");
        }
        return Duration(
            seconds: (value.first as CborInt).toInt(),
            microseconds: ((value.last as CborInt).toInt() / 1000).round());
      case 37:
        if (value is! CborBytes) {
          throw ArgumentError("Surreal[Decode]: Invalid UUID");
        }
        return UuidValue.fromList(value.bytes);
    }
  } else if (value is CborInt) {
    return value.toInt();
  } else if (value is CborBigInt) {
    return value.toBigInt();
  } else if (value is CborFloat) {
    return value.value;
  } else if (value is CborBool) {
    return value.value;
  } else if (value is CborString) {
    return value.toString();
  } else if (value is CborList) {
    return value.toList().map(decodeDBData).toList();
  } else if (value is CborMap) {
    final map = value
        .map((k, v) => MapEntry(decodeDBData(k) as String, decodeDBData(v)));
    return map;
  } else if (value is CborNull) {
    return null;
  } else if (value is CborBytes) {
    return Uint8List.fromList(value.bytes);
  }
  throw UnsupportedError(
      "Surreal[Decode]: Unknown type ${value.runtimeType} with tag ${value.tags}");
}
