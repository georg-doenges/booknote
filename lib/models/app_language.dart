/// Sprache für Whisper-Transkription und Cover-Suche.
///
/// Bewusst ein Enum (kein Bool), damit später weitere Sprachen (Französisch …)
/// dazukommen können, ohne die UI-Logik umzubauen. [code] ist ISO 639-1 – so
/// erwarten es sowohl die OpenAI-Whisper-API als auch Google Books / Open
/// Library.
enum AppLanguage {
  german('de', 'Deutsch'),
  english('en', 'English');

  const AppLanguage(this.code, this.label);

  final String code;
  final String label;

  static AppLanguage fromCode(String? code) =>
      values.firstWhere((l) => l.code == code, orElse: () => german);
}
