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

/// Key-and-value equality of two maps.
bool mapEq<K, V>(Map<K, V> a, Map<K, V> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (final MapEntry<K, V> e in a.entries) {
    if (!b.containsKey(e.key) || b[e.key] != e.value) {
      return false;
    }
  }
  return true;
}

/// Order-independent hash of a map.
int mapHash<K, V>(Map<K, V> a) {
  int h = 0;
  for (final MapEntry<K, V> e in a.entries) {
    h ^= Object.hash(e.key, e.value);
  }
  return h;
}

/// Reads a list of strings from decoded JSON.
List<String> readStringList(Map<String, Object?> json, String key) {
  final List<String> out = <String>[];
  for (final Object? v in readList(json, key)) {
    if (v is! String) {
      throw FormatException('Expected a string in "$key", got $v');
    }
    out.add(v);
  }
  return out;
}

/// Reads an optional string (absent or null gives null).
String? readOptString(Map<String, Object?> json, String key) {
  final Object? v = json[key];
  if (v == null) {
    return null;
  }
  if (v is String) {
    return v;
  }
  throw FormatException('Expected a string or null at "$key", got $v');
}
