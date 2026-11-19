// Small helpers shared by the hand-written models. Pure Dart.

/// Element-wise list equality (order matters).
bool listEq<T>(List<T> a, List<T> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

/// Order-sensitive hash of a list.
int listHash<T>(List<T> a) => Object.hashAll(a);

/// Reads an int from decoded JSON, accepting whole-valued doubles.
int readInt(Map<String, Object?> json, String key) {
  final Object? v = json[key];
  if (v is int) {
    return v;
  }
  if (v is double && v == v.roundToDouble()) {
    return v.toInt();
  }
  throw FormatException('Expected an int at "$key", got $v');
}

double readDouble(Map<String, Object?> json, String key) {
  final Object? v = json[key];
  if (v is num) {
    return v.toDouble();
  }
  throw FormatException('Expected a number at "$key", got $v');
}

String readString(Map<String, Object?> json, String key) {
  final Object? v = json[key];
  if (v is String) {
    return v;
  }
  throw FormatException('Expected a string at "$key", got $v');
}

bool readBool(Map<String, Object?> json, String key) {
  final Object? v = json[key];
  if (v is bool) {
    return v;
  }
  throw FormatException('Expected a bool at "$key", got $v');
}

Map<String, Object?> readMap(Map<String, Object?> json, String key) {
  final Object? v = json[key];
  if (v is Map<String, Object?>) {
    return v;
  }
  throw FormatException('Expected an object at "$key", got $v');
}

List<Object?> readList(Map<String, Object?> json, String key) {
  final Object? v = json[key];
  if (v is List<Object?>) {
    return v;
  }
  throw FormatException('Expected a list at "$key", got $v');
}

/// Looks an enum value up by name, with a clear error for unknown names.
T readEnum<T extends Enum>(List<T> values, Map<String, Object?> json, String key) {
  final String name = readString(json, key);
  for (final T v in values) {
    if (v.name == name) {
      return v;
    }
  }
  throw FormatException('Unknown value "$name" at "$key"');
}
