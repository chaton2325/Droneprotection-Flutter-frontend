/// Le backend (PostgreSQL, `now()`) renvoie des dates ISO 8601 avec suffixe
/// de timezone (ex: `2026-09-08T17:55:38.665Z`), deja exploitables telles
/// quelles. On garde un filet de securite pour un ancien format sans
/// timezone (ex: `2026-09-08 17:55:38`, style SQLite) au cas ou.
final _hasTimezone = RegExp(r'(Z|[+-]\d{2}:?\d{2})$');

DateTime? _parseUtc(String? isoDate) {
  if (isoDate == null) return null;
  if (_hasTimezone.hasMatch(isoDate)) return DateTime.tryParse(isoDate);
  return DateTime.tryParse('${isoDate.replaceFirst(' ', 'T')}Z');
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
