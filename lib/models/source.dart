import 'source_type.dart';

/// Generische Notiz-Quelle (Buch, später Video, Ideen-Notizbuch, ...).
///
/// Unveränderliches Wertobjekt. IDs sind Strings (UUID v4), damit sie
/// geräteübergreifend eindeutig bleiben und ein späterer Cloud-Sync keine
/// ID-Migration braucht.
class Source {
  const Source({
    required this.id,
    required this.sourceType,
    required this.title,
    this.author,
    this.coverUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final SourceType sourceType;
  final String title;

  /// Autor(en) als Freitext, z.B. "Thomas Mann" oder "A. Müller, B. Schmidt".
  final String? author;

  /// URL des Coverbilds, `null` = Platzhalter anzeigen.
  final String? coverUrl;

  final DateTime createdAt;

  /// Zeitpunkt der letzten Änderung. Wird für spätere Sync-Konfliktauflösung
  /// gebraucht (last-write-wins) und ist deshalb von Anfang an dabei.
  final DateTime updatedAt;

  Source copyWith({
    String? title,
    String? author,
    bool clearAuthor = false,
    String? coverUrl,
    bool clearCoverUrl = false,
    DateTime? updatedAt,
  }) {
    return Source(
      id: id,
      sourceType: sourceType,
      title: title ?? this.title,
      author: clearAuthor ? null : (author ?? this.author),
      coverUrl: clearCoverUrl ? null : (coverUrl ?? this.coverUrl),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Source &&
      other.id == id &&
      other.sourceType == sourceType &&
      other.title == title &&
      other.author == author &&
      other.coverUrl == coverUrl &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    sourceType,
    title,
    author,
    coverUrl,
    createdAt,
    updatedAt,
  );

  @override
  String toString() => 'Source($id, ${sourceType.dbValue}, "$title")';
}
