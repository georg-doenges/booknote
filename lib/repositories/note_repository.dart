import '../models/note.dart';

/// Sortierung von Notizlisten.
enum NoteSort {
  /// Chronologisch, älteste zuerst (Reihenfolge der Aufnahme).
  createdAt,

  /// Nach Seitenzahl aufsteigend; Notizen ohne Seite am Ende, dort chronologisch.
  page,
}

/// Datenzugriff für Notizen.
///
/// Siehe [BookRepository] für die Konventionen (ID-Vergabe, Fehler).
/// Notizen hängen an einer generischen `Source` (Stufe 1: immer ein Buch),
/// deshalb heißt der Schlüssel `sourceId`.
abstract class NoteRepository {
  /// Alle Notizen einer Quelle in der gewünschten Sortierung.
  Future<List<Note>> getBySource(
    String sourceId, {
    NoteSort sort = NoteSort.createdAt,
  });

  /// Eine Notiz nach ID, `null` wenn nicht vorhanden.
  Future<Note?> getById(String id);

  /// Anzahl der Notizen einer Quelle (für Badges in der Bibliothek).
  Future<int> countBySource(String sourceId);

  /// Notizzahl je Quelle (`sourceId` → Anzahl), nur Quellen mit ≥ 1 Notiz.
  /// Reaktiv – für die Zahlen auf den Bibliotheks-Kacheln.
  Stream<Map<String, int>> watchCounts();

  /// Legt eine Notiz an und gibt sie mit vergebener ID zurück.
  /// [rawTranscript] ist der ungeparste Whisper-Text und wird nie verändert.
  Future<Note> create({
    required String sourceId,
    String? page,
    String? position,
    required String text,
    required String rawTranscript,
  });

  /// Speichert Seite/Position/Text einer bestehenden Notiz.
  /// `rawTranscript` wird dabei ignoriert (unveränderlich).
  Future<void> update(Note note);

  Future<void> delete(String id);

  /// Reaktive Sicht auf [getBySource].
  Stream<List<Note>> watchBySource(
    String sourceId, {
    NoteSort sort = NoteSort.createdAt,
  });
}

/// Sortier-Hilfe, damit alle Implementierungen identisch sortieren.
List<Note> sortNotes(List<Note> notes, NoteSort sort) {
  final sorted = List<Note>.of(notes);
  switch (sort) {
    case NoteSort.createdAt:
      sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    case NoteSort.page:
      sorted.sort((a, b) {
        final pa = a.pageNumber;
        final pb = b.pageNumber;
        if (pa == null && pb == null) return a.createdAt.compareTo(b.createdAt);
        if (pa == null) return 1;
        if (pb == null) return -1;
        final byPage = pa.compareTo(pb);
        return byPage != 0 ? byPage : a.createdAt.compareTo(b.createdAt);
      });
  }
  return sorted;
}
