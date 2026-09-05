/// Eine einzelne Notiz zu einer Quelle (Buch).
///
/// [page] und [position] sind bewusst freie Strings (`"47"`, `"47f."`,
/// `"oben"`, `"Zeile 10"`), so wie sie der Parser aus dem Transkript zieht.
/// [rawTranscript] hält immer den ungeparsten Whisper-Output als Sicherung.
class Note {
  const Note({
    required this.id,
    required this.sourceId,
    this.page,
    this.position,
    required this.text,
    required this.rawTranscript,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;

  /// Fremdschlüssel auf `Source.id`.
  final String sourceId;

  /// Seitenangabe, z.B. `"47"` oder `"88f."`. `null` = nicht erkannt.
  final String? page;

  /// Position auf der Seite: `"oben"`, `"mitte"`, `"unten"`, `"Zeile 10"`.
  final String? position;

  /// Der eigentliche Notiztext (bearbeitbar).
  final String text;

  /// Ungeparster Transkript-Text, wird nie verändert.
  final String rawTranscript;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Numerischer Anteil der Seitenangabe, für die Sortierung nach Seite.
  /// `"88f."` → 88, `null` oder nicht-numerisch → `null`.
  int? get pageNumber {
    final p = page;
    if (p == null) return null;
    final match = RegExp(r'^\d+').firstMatch(p.trim());
    return match == null ? null : int.tryParse(match.group(0)!);
  }

  Note copyWith({
    String? page,
    bool clearPage = false,
    String? position,
    bool clearPosition = false,
    String? text,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id,
      sourceId: sourceId,
      page: clearPage ? null : (page ?? this.page),
      position: clearPosition ? null : (position ?? this.position),
      text: text ?? this.text,
      rawTranscript: rawTranscript,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Note &&
      other.id == id &&
      other.sourceId == sourceId &&
      other.page == page &&
      other.position == position &&
      other.text == text &&
      other.rawTranscript == rawTranscript &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    sourceId,
    page,
    position,
    text,
    rawTranscript,
    createdAt,
    updatedAt,
  );

  @override
  String toString() => 'Note($id, S.$page $position: "$text")';
}
