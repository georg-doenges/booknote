/// Sprache der App-Oberfläche, einer Aufnahme/eines Buchs (Whisper, Notiz-
/// Parser, „S."/„p."-Präfix) und der Cover-Suche.
///
/// Bewusst ein Enum (kein Bool), damit weitere Sprachen dazukommen können,
/// ohne die UI-Logik umzubauen. [code] ist ISO 639-1 – so erwarten es sowohl
/// die OpenAI-Whisper-API als auch Google Books / Open Library und Flutters
/// `Locale`. [label] ist der Eigenname der Sprache und wird nie übersetzt.
enum AppLanguage {
  german('de', 'Deutsch'),
  english('en', 'English'),
  french('fr', 'Français');

  const AppLanguage(this.code, this.label);

  final String code;
  final String label;

  /// Unbekannte Codes (auch `null`) → [german]: so wurden bis zur Einführung
  /// der Mehrsprachigkeit alle Bestandsdaten angelegt.
  static AppLanguage fromCode(String? code) =>
      values.firstWhere((l) => l.code == code, orElse: () => german);

  /// Wie [fromCode], aber `null` bei unbekanntem Code.
  static AppLanguage? tryFromCode(String? code) {
    for (final l in values) {
      if (l.code == code) return l;
    }
    return null;
  }
}
