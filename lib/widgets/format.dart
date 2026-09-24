/// Kleine Formatierhilfen.
library;

import 'package:intl/intl.dart';

import '../models/app_language.dart';

String _two(int n) => n.toString().padLeft(2, '0');

/// `05.09.2026, 19:26` in lokaler Zeit – ohne Locale-Daten, deshalb auch in
/// reinen Dart-Tests und als Vorgabe der Exporter nutzbar.
String formatDateTimeDefault(DateTime t) {
  final l = t.toLocal();
  return '${_two(l.day)}.${_two(l.month)}.${l.year}, ${_two(l.hour)}:${_two(l.minute)}';
}

/// Datum + Uhrzeit in der Sprache der App: Deutsch numerisch
/// (`05.09.2026, 19:26`), Englisch/Französisch mit ausgeschriebenem Monat
/// (`Sep 5, 2026, 7:26 PM` / `5 sept. 2026, 19:26`), damit Tag und Monat nie
/// verwechselt werden. Braucht initialisierte Locale-Daten (in der App durch
/// die Material-Lokalisierung gegeben).
String formatDateTime(DateTime t, [String languageCode = 'de']) {
  final l = t.toLocal();
  return switch (languageCode) {
    'de' => formatDateTimeDefault(l),
    _ => DateFormat.yMMMd(languageCode).add_jm().format(l),
  };
}

/// Sprachabhängiges Präfix für Seitenangaben: „S." (Deutsch) / „p."
/// (Englisch, Französisch).
String pagePrefix(AppLanguage language) =>
    language == AppLanguage.german ? 'S.' : 'p.';
