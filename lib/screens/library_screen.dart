import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/models.dart';
import '../widgets/book_cover_tile.dart';
import 'book_detail_screen.dart';
import 'book_search_screen.dart';
import 'recording_screen.dart';
import 'settings_screen.dart';

/// Startbildschirm: Bibliothek als Cover-Grid.
///
/// Tippen → RecordingScreen (der wichtigste Pfad).
/// Lange drücken → BookDetailScreen (Notizen, Bearbeiten, Export).
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  Future<void> _addBook(BuildContext context) async {
    final result = await Navigator.of(context).push<BookSearchResult>(
      MaterialPageRoute(builder: (_) => const BookSearchScreen()),
    );
    if (result == null || !context.mounted) return;
    final book = await AppScope.of(context).books.create(
      title: result.title,
      author: result.author,
      coverUrl: result.coverUrl,
    );
    if (!context.mounted) return;
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => RecordingScreen(book: book)));
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booknote'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Einstellungen',
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: StreamBuilder<List<Book>>(
        stream: scope.books.watchAll(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Fehler: ${snapshot.error}'));
          }
          final books = snapshot.data;
          if (books == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (books.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Noch keine Bücher.\nLege mit „+" dein erstes Buch an.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 140,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.58,
            ),
            itemCount: books.length,
            itemBuilder: (context, i) {
              final book = books[i];
              return BookCoverTile(
                book: book,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => RecordingScreen(book: book),
                  ),
                ),
                onLongPress: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BookDetailScreen(bookId: book.id),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addBook(context),
        tooltip: 'Neues Buch',
        child: const Icon(Icons.add),
      ),
    );
  }
}
