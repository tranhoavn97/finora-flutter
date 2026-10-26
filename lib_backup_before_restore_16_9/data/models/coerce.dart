/// Portable JSON value coercion helpers for Supabase documents.
int toLongValue(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toInt();
  if (value is String) {
    final parsedInt = int.tryParse(value);
    if (parsedInt != null) return parsedInt;
    try {
      final parsedDate = DateTime.parse(value);
      return parsedDate.millisecondsSinceEpoch;
    } catch (_) {}
  }
  return 0;
}

int? toLongOrNull(dynamic value) {
  if (value == null) return null;
  return toLongValue(value);
}

double toDoubleValue(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

bool toBoolValue(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is String) return value.toLowerCase() == 'true';
  if (value is num) return value.toInt() != 0;
  return false;
}

String toStringValue(dynamic value) => value?.toString() ?? '';

String? toStringOrNull(dynamic value) => value?.toString();

int maxInt(int a, int b) => a > b ? a : b;

Map<String, dynamic> removeNulls(Map<String, dynamic> map) {
  return Map<String, dynamic>.fromEntries(
    map.entries.where((e) => e.value != null),
  );
}

