import 'package:booknote/export/export.dart';
import 'package:booknote/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t0 = DateTime.utc(2026, 9, 5, 10, 0);
  Book book({
    String id = 'b',
    String title = 'Der Zauberberg',
    String? author,
  }) =>
      Book(id: id, title: title, author: author, createdAt: t0, updatedAt: t0);
  Note note(
    String id,
    String? page,
    String text, {
    String sourceId = 'b',
    String? position,
    int minute = 0,
  }) => Note(
    id: id,
    sourceId: sourceId,
    page: page,
    position: position,
    text: text,
    rawTranscript: 'raw',
    createdAt: t0.add(Duration(minutes: minute)),
    updatedAt: t0,
  );

  const md = MarkdownExporter();

  test('einzelnes Buch: Struktur wie PROJECT.md 8', () {
    final r = md.export(
      ExportRequest.single(book(author: 'Thomas Mann'), [
        note('1', '88f.', 'der Konflikt eskaliert', position: 'mitte'),
        note('2', null, 'nur ein Gedanke', minute: 1),
        note('3', '12', 'schöne Metapher über das Meer', minute: 2),
        note(
          '4',
          '47',
          'hier argumentiert der Autor dass…',
          position: 'oben',
          minute: 3,
        ),
      ], includeTimestamps: false),
    );

    expect(r.fileName, 'Der Zauberberg.md');
    expect(r.mimeType, 'text/markdown');
    expect(r.content, '''
# Der Zauberberg
*Thomas Mann*

## Notizen

- **S. 12:** schöne Metapher über das Meer
- **S. 47 (oben):** hier argumentiert der Autor dass…
- **S. 88f. (mitte):** der Konflikt eskaliert

## Ohne Seitenangabe

- nur ein Gedanke
''');
  });

  test('ohne Autor keine Autorzeile; ohne Seiten-Notizen Hinweis', () {
    final r = md.export(
      ExportRequest.single(book(), [
        note('1', null, 'x', position: 'oben'),
      ], includeTimestamps: false),
    );
    expect(r.content, '''
# Der Zauberberg

## Notizen

_Keine Notizen mit Seitenangabe._

## Ohne Seitenangabe

- **oben:** x
''');
  });

  test('Zeitstempel hängt hinten dran', () {
    final r = md.export(ExportRequest.single(book(), [note('1', '3', 'x')]));
    expect(
      r.content,
      contains(RegExp(r'- \*\*S\. 3:\*\* x _\(\d\d\.\d\d\.2026, \d\d:\d\d\)_')),
    );
  });

  test('Zeilenumbrüche werden zu Leerzeichen, leerer Text markiert', () {
    final r = md.export(
      ExportRequest.single(book(), [
        note('1', '3', 'erste\nzweite  \n dritte'),
        note('2', '4', ''),
      ], includeTimestamps: false),
    );
    expect(r.content, contains('- **S. 3:** erste zweite dritte\n'));
    expect(r.content, contains('- **S. 4:** _(kein Text)_\n'));
  });

  test(
    'Sammlung: eine Datei, je Buch ein ##-Block mit ###-Unterabschnitten',
    () {
      final r = md.export(
        ExportRequest(
          collectionTitle: 'Thomas Mann',
          includeTimestamps: false,
          books: [
            ExportBook(
              book(id: 'b', title: 'Buddenbrooks', author: 'Thomas Mann'),
              [note('1', '5', 'Verfall einer Familie')],
            ),
            ExportBook(
              book(id: 'z', title: 'Der Zauberberg', author: 'Thomas Mann'),
              [note('2', null, 'Zeit als Thema', sourceId: 'z')],
            ),
          ],
        ),
      );

      expect(r.fileName, 'Thomas Mann.md');
      expect(r.content, '''
# Thomas Mann

## Buddenbrooks
*Thomas Mann*

### Notizen

- **S. 5:** Verfall einer Familie

## Der Zauberberg
*Thomas Mann*

### Notizen

_Keine Notizen mit Seitenangabe._

### Ohne Seitenangabe

- Zeit als Thema
''');
    },
  );

  test('safeFileName entfernt Sonderzeichen und kürzt', () {
    expect(safeFileName('Was: ist / das?'), 'Was ist das');
    expect(safeFileName('   '), 'booknote');
    expect(safeFileName('a' * 100).length, 80);
  });
}
