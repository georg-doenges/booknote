import 'package:booknote/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 9, 5, 12);

  Note note({String? page}) => Note(
    id: 'n1',
    sourceId: 's1',
    page: page,
    text: 't',
    rawTranscript: 'raw',
    createdAt: now,
    updatedAt: now,
  );

  group('Note.pageNumber', () {
    test('plain number', () => expect(note(page: '47').pageNumber, 47));
    test('with f.', () => expect(note(page: '88f.').pageNumber, 88));
    test('with ff.', () => expect(note(page: '12ff.').pageNumber, 12));
    test('null page', () => expect(note().pageNumber, isNull));
    test('non-numeric', () => expect(note(page: 'xy').pageNumber, isNull));
  });

  test('Note.copyWith clears page and position', () {
    final n = note(page: '5').copyWith(position: 'oben');
    expect(n.position, 'oben');
    final cleared = n.copyWith(clearPage: true, clearPosition: true);
    expect(cleared.page, isNull);
    expect(cleared.position, isNull);
    expect(cleared.rawTranscript, 'raw');
  });

  test('Book.fromSource keeps fields', () {
    final s = Source(
      id: 'b1',
      sourceType: SourceType.book,
      title: 'Titel',
      coverUrl: 'http://x/y.jpg',
      createdAt: now,
      updatedAt: now,
    );
    final b = Book.fromSource(s);
    expect(b, equals(s));
    expect(b.copyWith(clearCoverUrl: true).coverUrl, isNull);
  });

  test('SourceType round-trips through dbValue', () {
    expect(SourceType.fromDbValue('book'), SourceType.book);
    expect(() => SourceType.fromDbValue('x'), throwsArgumentError);
  });
}
