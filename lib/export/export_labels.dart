import '../widgets/format.dart';

/// Beschriftungen in den exportierten Dateien (Überschriften, Platzhalter) und
/// das Datumsformat. Die Standardwerte sind deutsch; die UI übergibt die Texte
/// in der Sprache der App (siehe `export_sheet.dart`).
///
/// Bewusst kein `AppLocalizations`: Die Exporter bleiben reine Funktionen ohne
/// Flutter-Abhängigkeit und damit testbar.
class ExportLabels {
  const ExportLabels({
    this.notes = 'Notizen',
    this.withoutPage = 'Ohne Seitenangabe',
    this.noNotesWithPage = 'Keine Notizen mit Seitenangabe',
    this.noText = 'kein Text',
    this.library = 'Bibliothek',
    this.formatDateTime = formatDateTimeDefault,
  });

  /// Abschnittsüberschrift über den Notizen mit Seitenangabe.
  final String notes;

  /// Abschnittsüberschrift über den Notizen ohne Seitenangabe.
  final String withoutPage;

  /// Hinweis, wenn ein Buch keine Notiz mit Seitenangabe hat.
  final String noNotesWithPage;

  /// Platzhalter für eine Notiz ohne erkannten Text.
  final String noText;

  /// Titel der Sammel-Datei „ganze Bibliothek".
  final String library;

  /// Zeitstempel einer Notiz.
  final String Function(DateTime) formatDateTime;
}
