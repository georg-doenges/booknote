import '../models/models.dart';
import 'export_labels.dart';

/// Ein Buch mit seinen (noch unsortierten) Notizen – Baustein einer
/// Export-Anfrage.
class ExportBook {
  const ExportBook(this.book, this.notes);

  final Book book;
  final List<Note> notes;
}

/// Was exportiert werden soll: ein Buch, alle Bücher eines Autors oder die
/// ganze Bibliothek.
class ExportRequest {
  const ExportRequest({
    required this.books,
    this.collectionTitle,
    this.includeTimestamps = true,
    this.labels = const ExportLabels(),
  });

  /// Ein einzelnes Buch.
  ExportRequest.single(
    Book book,
    List<Note> notes, {
    this.includeTimestamps = true,
    this.labels = const ExportLabels(),
  }) : books = [ExportBook(book, notes)],
       collectionTitle = null;

  final List<ExportBook> books;

  /// Überschrift der Sammel-Datei („Bibliothek" oder ein Autorname).
  /// `null` → genau ein Buch, der Dateititel ist der Buchtitel.
  final String? collectionTitle;

  final bool includeTimestamps;

  /// Überschriften/Platzhalter der Datei in der gewünschten Sprache.
  final ExportLabels labels;

  bool get isCollection => collectionTitle != null;
}

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

/// Wandelt eine [ExportRequest] in ein Zielformat um.
///
/// Reine Funktion ohne I/O, damit sie testbar bleibt; Schreiben/Teilen macht
/// `shareExport()`. Weitere Formate (JSON, …) implementieren dieses Interface.
abstract class Exporter {
  /// Anzeigename, z.B. „Markdown".
  String get formatName;

  /// Datei-Endung ohne Punkt, z.B. `md`.
  String get fileExtension;

  String get mimeType;

  ExportResult export(ExportRequest request);
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
