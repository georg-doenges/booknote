import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../export/export.dart';
import '../models/models.dart';
import '../theme.dart';
import '../widgets/book_cover_tile.dart';
import 'book_detail_screen.dart';
import 'book_search_screen.dart';
import 'library_sync_sheet.dart';
import 'recording_screen.dart';
import 'settings_screen.dart';

/// Startbildschirm: Bibliothek als Cover-Grid.
///
/// Tippen → RecordingScreen (der wichtigste Pfad).
/// Lange drücken → BookDetailScreen (Notizen, Bearbeiten, Export).
/// AppBar-Lupe → nach Titel/Autor suchen; Chip-Leiste → nach Autor filtern.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _query = TextEditingController();
  bool _searching = false;
  String? _authorFilter;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _addBook() async {
    final result = await Navigator.of(context).push<BookSearchResult>(
      MaterialPageRoute(builder: (_) => const BookSearchScreen()),
    );
    if (result == null || !mounted) return;
    final book = await AppScope.of(context).books.create(
      title: result.title,
      author: result.author,
      coverUrl: result.coverUrl,
    );
    if (!mounted) return;
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => RecordingScreen(book: book)));
  }

  void _stopSearch() {
    setState(() {
      _searching = false;
      _query.clear();
    });
  }

  void _export() => showExportSheet(
    context,
    initialScope: _authorFilter != null
        ? ExportScope.author
        : ExportScope.library,
    author: _authorFilter,
  );

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return Scaffold(
      appBar: _searching
          ? AppBar(
              leading: BackButton(onPressed: _stopSearch),
              title: TextField(
                controller: _query,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Titel oder Autor suchen',
                  border: InputBorder.none,
                ),
              ),
              actions: [
                if (_query.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Leeren',
                    onPressed: () => setState(_query.clear),
                  ),
              ],
            )
          : AppBar(
              title: const Text('Booknote'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: 'Suchen',
                  onPressed: () => setState(() => _searching = true),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    switch (v) {
                      case 'export':
                        _export();
                      case 'sync':
                        showLibrarySyncSheet(context);
                      case 'settings':
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'export',
                      child: Text('Exportieren …'),
                    ),
                    PopupMenuItem(
                      value: 'sync',
                      child: Text('Bibliothek sichern / abgleichen …'),
                    ),
                    PopupMenuItem(
                      value: 'settings',
                      child: Text('Einstellungen'),
                    ),
                  ],
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
            return _EmptyHint(
              text: 'Noch keine Bücher.\nLege mit „+" dein erstes Buch an.',
            );
          }

          final authors = distinctAuthors(books);
          // Ein gewählter Autor, der nicht mehr existiert, wird ignoriert.
          final activeAuthor =
              _authorFilter != null && authors.contains(_authorFilter)
              ? _authorFilter
              : null;
          final visible = filterBooks(
            books,
            query: _query.text,
            author: activeAuthor,
          );

          return Column(
            children: [
              if (authors.length >= 2)
                _AuthorFilterBar(
                  authors: authors,
                  selected: activeAuthor,
                  onSelected: (a) => setState(() => _authorFilter = a),
                ),
              Expanded(
                child: visible.isEmpty
                    ? _EmptyHint(
                        text: 'Nichts gefunden.',
                        onClear: () => setState(() {
                          _query.clear();
                          _authorFilter = null;
                        }),
                      )
                    : _BookGrid(books: visible),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addBook,
        tooltip: 'Neues Buch',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _BookGrid extends StatelessWidget {
  const _BookGrid({required this.books});

  final List<Book> books;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      // Unten Platz für System-Navigationsleiste und FAB.
      padding: EdgeInsets.fromLTRB(
        BooknoteTheme.gap12,
        BooknoteTheme.gap12,
        BooknoteTheme.gap12,
        BooknoteTheme.gap12 +
            BooknoteTheme.fabSafeBottom +
            MediaQuery.paddingOf(context).bottom,
      ),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 140,
        mainAxisSpacing: BooknoteTheme.gap16,
        crossAxisSpacing: BooknoteTheme.gap12,
        childAspectRatio: 0.58,
      ),
      itemCount: books.length,
      itemBuilder: (context, i) {
        final book = books[i];
        return BookCoverTile(
          book: book,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => RecordingScreen(book: book)),
          ),
          onLongPress: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BookDetailScreen(bookId: book.id),
            ),
          ),
        );
      },
    );
  }
}

class _AuthorFilterBar extends StatelessWidget {
  const _AuthorFilterBar({
    required this.authors,
    required this.selected,
    required this.onSelected,
  });

  final List<String> authors;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: BooknoteTheme.gap12),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: BooknoteTheme.gap8),
            child: FilterChip(
              label: const Text('Alle'),
              selected: selected == null,
              onSelected: (_) => onSelected(null),
            ),
          ),
          for (final a in authors)
            Padding(
              padding: const EdgeInsets.only(right: BooknoteTheme.gap8),
              child: FilterChip(
                label: Text(a),
                selected: selected == a,
                onSelected: (on) => onSelected(on ? a : null),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text, this.onClear});

  final String text;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BooknoteTheme.gap24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (onClear != null) ...[
              const SizedBox(height: BooknoteTheme.gap12),
              TextButton(
                onPressed: onClear,
                child: const Text('Filter zurücksetzen'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
