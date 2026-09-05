/// Kleine Formatierhilfen ohne `intl`-Abhängigkeit.
library;

String _two(int n) => n.toString().padLeft(2, '0');

/// `05.09.2026, 19:26` in lokaler Zeit.
String formatDateTime(DateTime t) {
  final l = t.toLocal();
  return '${_two(l.day)}.${_two(l.month)}.${l.year}, ${_two(l.hour)}:${_two(l.minute)}';
}
