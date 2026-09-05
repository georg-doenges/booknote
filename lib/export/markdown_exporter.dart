import '../models/models.dart';
import '../repositories/note_repository.dart';
import '../widgets/format.dart';
import 'exporter.dart';

/// Markdown-Export gemäß PROJECT.md Abschnitt 8:
///
/// ```markdown
/// # <Buchtitel>
/// *<Autor>*
///
/// ## Notizen
///
/// - **S. 47 (oben):** hier argumentiert der Autor dass… _(05.09.2026, 19:26)_
///
/// ## Ohne Seitenangabe
///
/// - text _(…)_
/// ```
///
/// Notizen mit Seite sind nach Seite sortiert, ohne Seite chronologisch.
/// Der Zeitstempel hängt klein hinten dran (Nutzerwunsch: Referenz).
class MarkdownExporter implements Exporter {
  const MarkdownExporter({this.includeTimestamps = true});

  final bool includeTimestamps;

  @override
  String get formatName => 'Markdown';

  @override
  ExportResult export(Book book, List<Note> notes) {
    final sorted = sortNotes(notes, NoteSort.page);
    final withPage = sorted.where((n) => n.page != null).toList();
    final withoutPage = sorted.where((n) => n.page == null).toList();

    final b = StringBuffer()..writeln('# ${_inline(book.title)}');
    if (book.author != null) b.writeln('*${_inline(book.author!)}*');
    b.writeln();

    b.writeln('## Notizen');
    b.writeln();
    if (withPage.isEmpty) {
      b.writeln('_Keine Notizen mit Seitenangabe._');
    }
    for (final n in withPage) {
      final pos = n.position == null ? '' : ' (${_inline(n.position!)})';
      b.writeln('- **S. ${_inline(n.page!)}$pos:** ${_body(n)}');
    }

    if (withoutPage.isNotEmpty) {
      b.writeln();
      b.writeln('## Ohne Seitenangabe');
      b.writeln();
      for (final n in withoutPage) {
        final pos = n.position == null ? '' : '**${_inline(n.position!)}:** ';
        b.writeln('- $pos${_body(n)}');
      }
    }

    return ExportResult(
      fileName: '${safeFileName(book.title)}.md',
      mimeType: 'text/markdown',
      content: b.toString(),
    );
  }

  String _body(Note n) {
    final text = n.text.isEmpty ? '_(kein Text)_' : _inline(n.text);
    if (!includeTimestamps) return text;
    return '$text _(${formatDateTime(n.createdAt)})_';
  }

  /// Zeilenumbrüche raus, damit ein Listenpunkt ein Listenpunkt bleibt.
  static String _inline(String s) =>
      s.replaceAll(RegExp(r'\s*\r?\n\s*'), ' ').trim();
}
