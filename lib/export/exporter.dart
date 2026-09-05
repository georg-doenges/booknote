import '../models/models.dart';

/// Ergebnis eines Exports: Dateiname, MIME-Typ und Inhalt als Text.
class ExportResult {
  const ExportResult({
    required this.fileName,
    required this.mimeType,
    required this.content,
  });

  final String fileName;
  final String mimeType;
  final String content;
}

/// Wandelt ein Buch samt Notizen in ein Zielformat um.
///
/// Reine Funktion ohne I/O, damit sie testbar bleibt; Schreiben/Teilen macht
/// `shareExport()`. Weitere Formate (JSON, …) implementieren dieses Interface.
abstract class Exporter {
  /// Anzeigename, z.B. "Markdown".
  String get formatName;

  ExportResult export(Book book, List<Note> notes);
}

/// Macht aus einem Titel einen brauchbaren Dateinamen (ohne Extension).
String safeFileName(String title, {String fallback = 'booknote'}) {
  final cleaned = title
      .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (cleaned.isEmpty) return fallback;
  return cleaned.length > 80 ? cleaned.substring(0, 80).trim() : cleaned;
}
