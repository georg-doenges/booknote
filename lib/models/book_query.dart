// Filtern der Bibliothek in Dart. Die App lädt alle Bücher über das Repository
// (`watchAll`) und filtert hier – reicht für eine persönliche Bibliothek und
// hält das Repository-Interface schlank (PROGRESS.md, Wunschliste „Bibliothek
// durchsuchen/filtern"). Reine Funktionen, damit sie ohne UI testbar sind.

import 'book.dart';

/// Bücher, die zum Freitext [query] (Titel **oder** Autor, Teilstring,
/// Groß-/Kleinschreibung egal) und – falls gesetzt – zum exakten [author]
/// passen. Reihenfolge bleibt erhalten.
List<Book> filterBooks(List<Book> books, {String query = '', String? author}) {
  final q = query.trim().toLowerCase();
  return books.where((b) {
    if (author != null && b.author != author) return false;
    if (q.isEmpty) return true;
    return b.title.toLowerCase().contains(q) ||
        (b.author?.toLowerCase().contains(q) ?? false);
  }).toList();
}

/// Alle vorkommenden Autoren (getrimmt, ohne Leere, ohne Dubletten),
/// alphabetisch – für die Filter-Chips.
List<String> distinctAuthors(Iterable<Book> books) {
  final seen = <String>{};
  for (final b in books) {
    final a = b.author?.trim();
    if (a != null && a.isNotEmpty) seen.add(a);
  }
  return seen.toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
}
