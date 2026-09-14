import '../models/models.dart';
import '../repositories/note_repository.dart';
import '../widgets/format.dart';
import 'exporter.dart';

/// Markdown-Export gemäß PROJECT.md Abschnitt 8.
///
/// Einzelnes Buch:
///
/// ```markdown
/// # <Buchtitel>
/// *<Autor>*
///
/// ## Notizen
///
/// - **S. 47 (oben):** … _(05.09.2026, 19:26)_
///
/// ## Ohne Seitenangabe
///
/// - text
/// ```
///
/// Sammlung (Autor / ganze Bibliothek): eine Datei, je Buch ein `##`-Block
/// mit `###`-Unterabschnitten.
///
/// Notizen mit Seite sind nach Seite sortiert, ohne Seite chronologisch.
class MarkdownExporter implements Exporter {
  const MarkdownExporter();

  @override
  String get formatName => 'Markdown';

  @override
  String get fileExtension => 'md';

  @override
  String get mimeType => 'text/markdown';

  @override
  ExportResult export(ExportRequest request) {
    final b = StringBuffer();

    if (request.isCollection) {
      b
        ..writeln('# ${_inline(request.collectionTitle!)}')
        ..writeln();
      for (var i = 0; i < request.books.length; i++) {
        if (i > 0) b.writeln();
        _writeBook(b, request.books[i], request.includeTimestamps, level: 2);
      }
    } else {
      _writeBook(b, request.books.single, request.includeTimestamps, level: 1);
    }

    final title = request.collectionTitle ?? request.books.single.book.title;
    return ExportResult(
      fileName: '${safeFileName(title)}.md',
      mimeType: mimeType,
      content: b.toString(),
    );
  }

  void _writeBook(
    StringBuffer b,
    ExportBook entry,
    bool includeTimestamps, {
    required int level,
  }) {
    final h = '#' * level;
    final book = entry.book;
    final sorted = sortNotes(entry.notes, NoteSort.page);
    final withPage = sorted.where((n) => n.page != null).toList();
    final withoutPage = sorted.where((n) => n.page == null).toList();

    b.writeln('$h ${_inline(book.title)}');
    if (book.author != null) b.writeln('*${_inline(book.author!)}*');
    b
      ..writeln()
      ..writeln('$h# Notizen')
      ..writeln();
    if (withPage.isEmpty) b.writeln('_Keine Notizen mit Seitenangabe._');
    for (final n in withPage) {
      final pos = n.position == null ? '' : ' (${_inline(n.position!)})';
      b.writeln(
        '- **${pagePrefix(n.language)} ${_inline(n.page!)}$pos:** '
        '${_body(n, includeTimestamps)}',
      );
    }

    if (withoutPage.isNotEmpty) {
      b
        ..writeln()
        ..writeln('$h# Ohne Seitenangabe')
        ..writeln();
      for (final n in withoutPage) {
        final pos = n.position == null ? '' : '**${_inline(n.position!)}:** ';
        b.writeln('- $pos${_body(n, includeTimestamps)}');
      }
    }
  }

  String _body(Note n, bool includeTimestamps) {
    final text = n.text.isEmpty ? '_(kein Text)_' : _inline(n.text);
    if (!includeTimestamps) return text;
    return '$text _(${formatDateTime(n.createdAt)})_';
  }

  /// Zeilenumbrüche raus, damit ein Listenpunkt ein Listenpunkt bleibt.
  static String _inline(String s) =>
      s.replaceAll(RegExp(r'\s*\r?\n\s*'), ' ').trim();
}
