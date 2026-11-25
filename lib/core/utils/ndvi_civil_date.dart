// Chaves de data NDVI no dia civil (`yyyy-MM-dd`), sem fuso na persistência.

String ndviImageDateKey(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String ndviNormalizeImageDateStorage(String raw) {
  final trimmed = raw.trim();
  if (trimmed.length >= 10 && trimmed[4] == '-' && trimmed[7] == '-') {
    return trimmed.substring(0, 10);
  }
  return trimmed;
}

DateTime ndviParseCivilImageDate(String raw) {
  final key = ndviNormalizeImageDateStorage(raw);
  final parts = key.split('-');
  if (parts.length != 3) {
    return DateTime.parse(raw);
  }
  final year = int.parse(parts[0]);
  final month = int.parse(parts[1]);
  final day = int.parse(parts[2]);
  return DateTime(year, month, day);
}