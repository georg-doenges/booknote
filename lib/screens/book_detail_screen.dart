import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../export/export.dart';
import '../l10n/l10n.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';
import '../theme.dart';
import '../widgets/book_edit_dialog.dart';
import '../widgets/note_edit_dialog.dart';
import '../widgets/note_tile.dart';
import 'book_search_screen.dart';
import 'recording_screen.dart';

/// Alle Notizen eines Buchs: sortieren, bearbeiten, löschen; Buch bearbeiten,
/// Cover ändern, löschen; Export über den Share-Sheet.
class BookDetailScreen extends StatefulWidget {
  const BookDetailScreen({super.key, required this.bookId});

  final String bookId;

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  NoteSort _sort = NoteSort.page;

  Future<void> _editNote(Note note) async {
    final edited = await showNoteEditDialog(context, note);
    if (edited == null || !mounted) return;
    await AppScope.of(context).notes.update(edited);
  }

  Future<void> _deleteNote(Note note) async {
    final ok = await _confirm(
      context.l10n.bdDeleteNoteTitle,
      noteLocationLabel(note, noPage: context.l10n.noteNoPage),
    );
    if (!ok || !mounted) return;
    await AppScope.of(context).notes.delete(note.id);
  }

  Future<void> _editBook(Book book) async {
    final edited = await showBookEditDialog(context, book);
    if (edited == null || !mounted) return;
    await AppScope.of(context).books.update(edited);
  }

  Future<void> _changeCover(Book book) async {
    final result = await Navigator.of(context).push<BookSearchResult>(
      MaterialPageRoute(
        builder: (_) => BookSearchScreen(
          initialQuery: book.title,
          title: context.l10n.searchChangeCoverTitle,
          allowWithoutCover: false,
          newBook: false,
          bookLanguage: book.language,
        ),
      ),
    );
    if (result == null || !mounted) return;
    // Titel bleibt, wie der Nutzer ihn kennt; Autor nur füllen, wenn leer.
    await AppScope.of(context).books.update(
      book.copyWith(
        coverUrl: result.coverUrl,
        author: book.author ?? result.author,
      ),
    );
  }

  Future<void> _export(Book book) => showExportSheet(
    context,
    initialScope: ExportScope.book,
    book: book,
    author: book.author,
  );

  Future<void> _removeCover(Book book) async {
    await AppScope.of(context).books.update(book.copyWith(clearCoverUrl: true));
  }

  Future<void> _deleteBook(Book book) async {
    final ok = await _confirm(
      context.l10n.bdDeleteBookTitle,
      context.l10n.bdDeleteBookBody(book.title),
    );
    if (!ok || !mounted) return;
    await AppScope.of(context).books.delete(book.id);
    if (mounted) Navigator.of(context).pop();
  }

  Future<bool> _confirm(String title, String body) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(ctx.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(ctx.l10n.commonDelete),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return StreamBuilder<List<Book>>(
      stream: scope.books.watchAll(),
      builder: (context, bookSnap) {
        final book = bookSnap.data
            ?.where((b) => b.id == widget.bookId)
            .firstOrNull;
        if (bookSnap.hasData && book == null) {
          // Buch wurde gelöscht (z.B. von hier aus) → nichts mehr anzeigen.
          return const Scaffold(body: SizedBox.shrink());
        }
        return Scaffold(
          appBar: AppBar(
            title: book == null
                ? const SizedBox.shrink()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(book.title, overflow: TextOverflow.ellipsis),
                      if (book.author != null)
                        Text(
                          book.author!,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                    ],
                  ),
            actions: [
              IconButton(
                icon: Icon(
                  _sort == NoteSort.page
                      ? Icons.format_list_numbered
                      : Icons.schedule,
                ),
                tooltip: _sort == NoteSort.page
                    ? context.l10n.bdSortedByPage
                    : context.l10n.bdSortedChrono,
                onPressed: () => setState(
                  () => _sort = _sort == NoteSort.page
                      ? NoteSort.createdAt
                      : NoteSort.page,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.ios_share),
                tooltip: context.l10n.bdExportTooltip,
                onPressed: book == null ? null : () => _export(book),
              ),
              if (book != null)
                PopupMenuButton<String>(
                  onSelected: (v) => switch (v) {
                    'edit' => _editBook(book),
                    'cover' => _changeCover(book),
                    'nocover' => _removeCover(book),
                    'delete' => _deleteBook(book),
                    _ => null,
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text(context.l10n.bdMenuEdit),
                    ),
                    PopupMenuItem(
                      value: 'cover',
                      child: Text(context.l10n.searchChangeCoverTitle),
                    ),
                    if (book.coverUrl != null)
                      PopupMenuItem(
                        value: 'nocover',
                        child: Text(context.l10n.bdMenuRemoveCover),
                      ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(context.l10n.bdMenuDelete),
                    ),
                  ],
                ),
            ],
          ),
          body: StreamBuilder<List<Note>>(
            stream: scope.notes.watchBySource(widget.bookId, sort: _sort),
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(
                  child: Text(context.l10n.commonError('${snap.error}')),
                );
              }
              final notes = snap.data;
              if (notes == null) {
                return const Center(child: CircularProgressIndicator());
              }
              if (notes.isEmpty) {
                return Center(child: Text(context.l10n.bdNoNotes));
              }
              return ListView.builder(
                // Unten Platz für System-Navigationsleiste und FAB.
                padding: EdgeInsets.fromLTRB(
                  0,
                  BooknoteTheme.gap8,
                  0,
                  BooknoteTheme.gap8 +
                      BooknoteTheme.fabSafeBottom +
                      MediaQuery.paddingOf(context).bottom,
                ),
                itemCount: notes.length,
                itemBuilder: (_, i) => NoteTile(
                  note: notes[i],
                  onTap: () => _editNote(notes[i]),
                  onDelete: () => _deleteNote(notes[i]),
                ),
              );
            },
          ),
          floatingActionButton: book == null
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RecordingScreen(book: book),
                    ),
                  ),
                  icon: const Icon(Icons.mic),
                  label: Text(context.l10n.bdRecord),
                ),
        );
      },
    );
  }
}
