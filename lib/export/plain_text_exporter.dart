import '../models/models.dart';
import '../repositories/note_repository.dart';
import '../widgets/format.dart';
import 'exporter.dart';

/// Reiner Text – dieselbe Gliederung wie [MarkdownExporter], nur ohne
/// Markdown-Zeichen. Für Nutzer, die die Notizen woanders einkleben wollen.
///
/// ```text
/// Der Zauberberg
/// Thomas Mann
///
/// Notizen
///   S. 47 (oben): … (05.09.2026, 19:26)
///
/// Ohne Seitenangabe
///   nur ein Gedanke
/// ```
class PlainTextExporter implements Exporter {
  const PlainTextExporter();

  @override
  String get formatName => 'Text';

  @override
  String get fileExtension => 'txt';

  @override
  String get mimeType => 'text/plain';

  @override
  ExportResult export(ExportRequest request) {
    final b = StringBuffer();

    if (request.isCollection) {
      final title = _inline(request.collectionTitle!);
      b
        ..writeln(title)
        ..writeln('=' * title.length)
        ..writeln();
      for (var i = 0; i < request.books.length; i++) {
        if (i > 0) b.writeln();
        _writeBook(
          b,
          request.books[i],
          request.includeTimestamps,
          indent: true,
        );
      }
    } else {
      _writeBook(
        b,
        request.books.single,
        request.includeTimestamps,
        indent: false,
      );
    }

    final title = request.collectionTitle ?? request.books.single.book.title;
    return ExportResult(
      fileName: '${safeFileName(title)}.txt',
      mimeType: mimeType,
      content: b.toString(),
    );
  }

  void _writeBook(
    StringBuffer b,
    ExportBook entry,
    bool includeTimestamps, {
    required bool indent,
  }) {
    final book = entry.book;
    final sorted = sortNotes(entry.notes, NoteSort.page);
    final withPage = sorted.where((n) => n.page != null).toList();
    final withoutPage = sorted.where((n) => n.page == null).toList();
    final pad = indent ? '  ' : '';

    b.writeln('$pad${_inline(book.title)}');
    if (book.author != null) b.writeln('$pad${_inline(book.author!)}');
    b
      ..writeln()
      ..writeln('${pad}Notizen');
    if (withPage.isEmpty) b.writeln('$pad  (keine Notizen mit Seitenangabe)');
    for (final n in withPage) {
      final pos = n.position == null ? '' : ' (${_inline(n.position!)})';
      b.writeln(
        '$pad  ${pagePrefix(n.language)} ${_inline(n.page!)}$pos: '
        '${_body(n, includeTimestamps)}',
      );
    }

    if (withoutPage.isNotEmpty) {
      b
        ..writeln()
        ..writeln('${pad}Ohne Seitenangabe');
      for (final n in withoutPage) {
        final pos = n.position == null ? '' : '${_inline(n.position!)}: ';
        b.writeln('$pad  $pos${_body(n, includeTimestamps)}');
      }
    }
  }

  String _body(Note n, bool includeTimestamps) {
    final text = n.text.isEmpty ? '(kein Text)' : _inline(n.text);
    if (!includeTimestamps) return text;
    return '$text (${formatDateTime(n.createdAt)})';
  }

  static String _inline(String s) =>
      s.replaceAll(RegExp(r'\s*\r?\n\s*'), ' ').trim();
}
