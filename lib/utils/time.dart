/// Les dates renvoyees par le backend (SQLite `datetime('now')`) sont en UTC
/// mais sans suffixe de timezone, d'ou le parsing manuel ci-dessous.
DateTime? _parseUtc(String? sqliteDate) {
  if (sqliteDate == null) return null;
  return DateTime.tryParse('${sqliteDate.replaceFirst(' ', 'T')}Z');
}

String timeAgo(String? sqliteDate) {
  final date = _parseUtc(sqliteDate);
  if (date == null) return '';
  final seconds = DateTime.now().toUtc().difference(date).inSeconds;

  if (seconds < 5) return "a l'instant";
  if (seconds < 60) return 'il y a ${seconds}s';
  final minutes = seconds ~/ 60;
  if (minutes < 60) return 'il y a $minutes min';
  final hours = minutes ~/ 60;
  if (hours < 24) return 'il y a $hours h';
  final days = hours ~/ 24;
  return 'il y a $days j';
}
