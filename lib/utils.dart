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
    // SurrealDB durations are unsigned on the wire ([u64 seconds, u32
    // nanos]); the engine rejects negative values, so fail with a clear
    // error instead of a cryptic decode failure on the Rust side.
    final Duration a when a.isNegative => throw UnsupportedError(
        'Surreal[Encode]: negative durations are not supported by SurrealDB'),
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

/// Decodes [bytes] as a CBOR-encoded SurrealDB value, falling back to the raw
/// bytes when the payload cannot be decoded.
///
/// This is used for live-query notifications where an undecodable payload
/// must not take down the whole notification stream.
dynamic decodeDBDataBytes(Uint8List bytes) {
  try {
    return decodeDBData(cbor.decode(bytes));
  } catch (_) {
    return bytes;
  }
}

dynamic decodeDBData(CborValue value) {
  // Nested tags accumulate in `tags` (outermost first). Range bound tags
  // (50 = included, 51 = excluded) are only meaningful inside a range and
  // wrap another value, so they are skipped here; if no other recognized
  // tag remains, the wrapped value is decoded structurally.
  bool hasBoundTag = false;
  for (final tag in value.tags) {
    if (tag == 50 || tag == 51) {
      hasBoundTag = true;
      continue;
    }
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
      case 9:
        return UuidValue.fromString(value.toString());
      case 10:
        // Decimals keep full precision when left in their string form.
        return value.toString();
      case 12:
        if (value is! CborList || value.length != 2) {
          throw ArgumentError("Surreal[Decode]: Invalid date");
        }
        return decodeDateTime(value);
      case 13:
        // Duration in its textual form; there is no lossless Dart
        // representation, so keep it as the string.
        return value.toString();
      case 14:
        if (value is! CborList || value.length > 2 || value.isEmpty) {
          throw ArgumentError("Surreal[Decode]: Invalid duration");
        }
        if (value.length == 1) {
          if (value.first is! CborInt) {
            throw ArgumentError("Surreal[Decode]: Invalid duration");
          }
          return Duration(seconds: (value.first as CborInt).toInt());
        }
        if (value.first is! CborInt || value.last is! CborInt) {
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
      case 49:
        if (value is! CborList || value.length != 2) {
          throw ArgumentError("Surreal[Decode]: Invalid range");
        }
        return {
          "beg": _decodeRangeBound(value.first),
          "end": _decodeRangeBound(value.last),
        };
      case 55:
        if (value is! CborList || value.length != 2) {
          throw ArgumentError("Surreal[Decode]: Invalid file");
        }
        return {
          "bucket": value.first.toString(),
          "key": value.last.toString()
        };
      case 56:
        if (value is! CborList) {
          throw ArgumentError("Surreal[Decode]: Invalid set");
        }
        return value.toList().map(decodeDBData).toList();
      case 88:
        if (value is! CborList || value.length != 2) {
          throw ArgumentError("Surreal[Decode]: Invalid point");
        }
        return {
          "type": "Point",
          "coordinates": [decodeDBData(value.first), decodeDBData(value.last)],
        };
      case 89:
        return {
          "type": "LineString",
          "coordinates": _decodeGeometryElements(value),
        };
      case 90:
        return {
          "type": "Polygon",
          "coordinates": _decodeGeometryElements(value),
        };
      case 91:
        return {
          "type": "MultiPoint",
          "coordinates": _decodeGeometryElements(value),
        };
      case 92:
        return {
          "type": "MultiLineString",
          "coordinates": _decodeGeometryElements(value),
        };
      case 93:
        return {
          "type": "MultiPolygon",
          "coordinates": _decodeGeometryElements(value),
        };
      case 94:
        return {
          "type": "GeometryCollection",
          "geometries": _decodeGeometryElements(value),
        };
      default:
        continue;
    }
  }
  if (value.tags.isEmpty || hasBoundTag) {
    return _decodeStructural(value);
  }
  throw UnsupportedError(
      "Surreal[Decode]: Unknown type ${value.runtimeType} with tag ${value.tags}");
}

dynamic _decodeStructural(CborValue value) {
  if (value is CborInt) {
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

/// Decodes the elements of a geometry value (each element carries its own
/// geometry tag and is decoded recursively).
List<dynamic> _decodeGeometryElements(CborValue value) {
  if (value is! CborList) {
    throw ArgumentError("Surreal[Decode]: Invalid geometry");
  }
  return value.toList().map(decodeDBData).toList();
}

/// Decodes one bound of a range (tag 49). Bounds are tagged values (50 =
/// included, 51 = excluded) or plain null when unbounded. Decoded bounds keep
/// their inclusiveness: `{"included": true, "value": v}` or null.
dynamic _decodeRangeBound(CborValue value) {
  if (value is CborNull) {
    return null;
  }
  if (value.tags.isNotEmpty) {
    final tag = value.tags.first;
    if (tag == 50) {
      return {"included": true, "value": decodeDBData(value)};
    }
    if (tag == 51) {
      return {"included": false, "value": decodeDBData(value)};
    }
  }
  throw ArgumentError("Surreal[Decode]: Invalid range bound");
}
