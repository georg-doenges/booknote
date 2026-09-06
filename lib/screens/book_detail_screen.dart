import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../export/export.dart';
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
    final ok = await _confirm('Notiz löschen?', noteLocationLabel(note));
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
          title: 'Cover suchen',
          allowWithoutCover: false,
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

  Future<void> _export(Book book) async {
    final scope = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final notes = await scope.notes.getBySource(book.id);
      final result = scope.exporter.export(book, notes);
      await shareExport(result);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Export fehlgeschlagen: $e')),
      );
    }
  }

  Future<void> _removeCover(Book book) async {
    await AppScope.of(context).books.update(book.copyWith(clearCoverUrl: true));
  }

  Future<void> _deleteBook(Book book) async {
    final ok = await _confirm(
      'Buch löschen?',
      '„${book.title}" und alle zugehörigen Notizen werden gelöscht.',
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
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Löschen'),
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
                    ? 'Sortiert nach Seite (tippen: chronologisch)'
                    : 'Sortiert chronologisch (tippen: nach Seite)',
                onPressed: () => setState(
                  () => _sort = _sort == NoteSort.page
                      ? NoteSort.createdAt
                      : NoteSort.page,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.ios_share),
                tooltip: 'Als Markdown teilen',
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
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Titel / Autor bearbeiten'),
                    ),
                    const PopupMenuItem(
                      value: 'cover',
                      child: Text('Cover suchen'),
                    ),
                    if (book.coverUrl != null)
                      const PopupMenuItem(
                        value: 'nocover',
                        child: Text('Cover entfernen'),
                      ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Buch löschen'),
                    ),
                  ],
                ),
            ],
          ),
          body: StreamBuilder<List<Note>>(
            stream: scope.notes.watchBySource(widget.bookId, sort: _sort),
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(child: Text('Fehler: ${snap.error}'));
              }
              final notes = snap.data;
              if (notes == null) {
                return const Center(child: CircularProgressIndicator());
              }
              if (notes.isEmpty) {
                return const Center(
                  child: Text('Noch keine Notizen zu diesem Buch.'),
                );
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
                  label: const Text('Aufnehmen'),
                ),
        );
      },
    );
  }
}
