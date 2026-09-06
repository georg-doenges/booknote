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

  const txt = PlainTextExporter();

  test('Format-Metadaten', () {
    expect(txt.formatName, 'Text');
    expect(txt.fileExtension, 'txt');
    expect(txt.mimeType, 'text/plain');
  });

  test('einzelnes Buch: reiner Text, Seiten sortiert', () {
    final r = txt.export(
      ExportRequest.single(book(author: 'Thomas Mann'), [
        note('1', '88f.', 'der Konflikt eskaliert', position: 'mitte'),
        note('2', null, 'nur ein Gedanke', minute: 1),
        note('3', '12', 'schöne Metapher', minute: 2),
      ], includeTimestamps: false),
    );

    expect(r.fileName, 'Der Zauberberg.txt');
    expect(r.content, '''
Der Zauberberg
Thomas Mann

Notizen
  S. 12: schöne Metapher
  S. 88f. (mitte): der Konflikt eskaliert

Ohne Seitenangabe
  nur ein Gedanke
''');
  });

  test('Sammlung: Titel mit Unterstrich-Linie, je Buch eingerückt', () {
    final r = txt.export(
      ExportRequest(
        collectionTitle: 'Bibliothek',
        includeTimestamps: false,
        books: [
          ExportBook(book(title: 'A-Buch'), [note('1', '5', 'eins')]),
          ExportBook(book(id: 'c', title: 'B-Buch'), [
            note('2', '7', 'zwei', sourceId: 'c'),
          ]),
        ],
      ),
    );

    expect(r.content, '''
Bibliothek
==========

  A-Buch

  Notizen
    S. 5: eins

  B-Buch

  Notizen
    S. 7: zwei
''');
  });
}
