import 'package:booknote/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t0 = DateTime.utc(2026, 1, 1);
  Book book(String id, String title, {String? author}) =>
      Book(id: id, title: title, author: author, createdAt: t0, updatedAt: t0);

  final library = [
    book('1', 'Der Zauberberg', author: 'Thomas Mann'),
    book('2', 'Buddenbrooks', author: 'Thomas Mann'),
    book('3', 'Der Prozess', author: 'Franz Kafka'),
    book('4', 'Notizbuch', author: null),
  ];

  group('filterBooks', () {
    test('leere Suche gibt alles zurück, Reihenfolge bleibt', () {
      expect(filterBooks(library).map((b) => b.id), ['1', '2', '3', '4']);
    });

    test('Freitext trifft Titel, Groß-/Kleinschreibung egal', () {
      expect(filterBooks(library, query: 'der ').map((b) => b.id), ['1', '3']);
    });

    test('Freitext trifft auch den Autor', () {
      expect(filterBooks(library, query: 'kafka').map((b) => b.id), ['3']);
    });

    test('Autorfilter grenzt exakt ein', () {
      expect(filterBooks(library, author: 'Thomas Mann').map((b) => b.id), [
        '1',
        '2',
      ]);
    });

    test('Autorfilter und Freitext zusammen', () {
      expect(
        filterBooks(
          library,
          author: 'Thomas Mann',
          query: 'buddenbrooks',
        ).map((b) => b.id),
        ['2'],
      );
    });

    test('nichts passt → leere Liste', () {
      expect(filterBooks(library, query: 'melville'), isEmpty);
    });
  });

  group('distinctAuthors', () {
    test('ohne Dubletten, alphabetisch, ohne leere', () {
      expect(distinctAuthors(library), ['Franz Kafka', 'Thomas Mann']);
    });

    test('leere Bibliothek → leer', () {
      expect(distinctAuthors(const []), isEmpty);
    });
  });
}
