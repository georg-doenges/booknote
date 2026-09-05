import 'source.dart';
import 'source_type.dart';

/// Ein Buch: die erste (und in Stufe 1 einzige) Ausprägung von [Source].
///
/// Bewusst nur ein dünner Typ über [Source], damit Bücher überall dort
/// einsetzbar sind, wo generisch mit Quellen gearbeitet wird.
class Book extends Source {
  const Book({
    required super.id,
    required super.title,
    super.coverUrl,
    required super.createdAt,
    required super.updatedAt,
  }) : super(sourceType: SourceType.book);

  /// Wandelt eine generische [Source] vom Typ `book` in ein [Book] um.
  factory Book.fromSource(Source source) {
    if (source.sourceType != SourceType.book) {
      throw ArgumentError('Source ${source.id} ist kein Buch');
    }
    return Book(
      id: source.id,
      title: source.title,
      coverUrl: source.coverUrl,
      createdAt: source.createdAt,
      updatedAt: source.updatedAt,
    );
  }

  @override
  Book copyWith({
    String? title,
    String? coverUrl,
    bool clearCoverUrl = false,
    DateTime? updatedAt,
  }) {
    return Book(
      id: id,
      title: title ?? this.title,
      coverUrl: clearCoverUrl ? null : (coverUrl ?? this.coverUrl),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
