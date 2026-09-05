import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';
import '../widgets/note_edit_dialog.dart';
import '../widgets/note_tile.dart';
import 'recording_screen.dart';

/// Alle Notizen eines Buchs: sortieren, bearbeiten, löschen; Buch umbenennen
/// oder löschen. Export folgt in Schritt 7.
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

  Future<void> _renameBook(Book book) async {
    final controller = TextEditingController(text: book.title);
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buch umbenennen'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Titel'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (title == null || title.isEmpty || !mounted) return;
    await AppScope.of(context).books.update(book.copyWith(title: title));
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
            title: Text(book?.title ?? ''),
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
                tooltip: 'Export (kommt in Schritt 7)',
                onPressed: null,
              ),
              if (book != null)
                PopupMenuButton<String>(
                  onSelected: (v) => switch (v) {
                    'rename' => _renameBook(book),
                    'delete' => _deleteBook(book),
                    _ => null,
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'rename', child: Text('Umbenennen')),
                    PopupMenuItem(value: 'delete', child: Text('Buch löschen')),
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
                padding: const EdgeInsets.symmetric(vertical: 8),
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
