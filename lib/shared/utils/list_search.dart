/// Returns true when [query] is empty or matches any of [fields] (case-insensitive).
bool matchesListSearch(String query, Iterable<String> fields) {
  final trimmed = query.trim();
  if (trimmed.isEmpty) return true;
  final q = trimmed.toLowerCase();
  return fields.any((field) => field.toLowerCase().contains(q));
}
