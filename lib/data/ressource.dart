abstract class Resource {
  String get resource;
}

class DBTable implements Resource {
  final String tb;
  const DBTable(this.tb);

  DBTable.fromJson(Map<String, dynamic> json) : tb = json["tb"];

  Map<String, dynamic> toJson() => {
        "tb": tb,
      };
  @override
  String get resource => tb;

  @override
  String toString() => "DBTable(tb: $tb)";
}

class DBRecord implements Resource {
  final String tb;
  final dynamic id;
  const DBRecord(this.tb, this.id);

  DBTable get table => DBTable(tb);

  DBRecord.fromJson(Map<String, dynamic> json)
      : tb = json["tb"],
        id = json["id"];

  Map<String, dynamic> toJson() => {
        "tb": tb,
        "id": id,
      };

  DBRecord copyWith({String? tb, String? id}) {
    return DBRecord(tb ?? this.tb, id ?? this.id);
  }

  @override
  String get resource {
    if (id is! String) {
      throw ArgumentError(
          "id must be a String otherwise resource makes no sense");
    }
    return "$tb:$id";
  }

  @override
  String toString() {
    return "DBRecord(tb: $tb, id: $id)";
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DBRecord &&
          runtimeType == other.runtimeType &&
          tb == other.tb &&
          id == other.id;
  @override
  int get hashCode => tb.hashCode ^ id.hashCode;
}
