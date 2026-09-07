import 'package:booknote/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t0 = DateTime.utc(2026, 1, 1);

  Source source(String id, {String? author, int updated = 0}) => Source(
    id: id,
    sourceType: SourceType.book,
    title: 'Titel $id',
    author: author,
    coverUrl: null,
    createdAt: t0,
    updatedAt: t0.add(Duration(minutes: updated)),
  );
  Note note(String id, String sourceId, {int updated = 0}) => Note(
    id: id,
    sourceId: sourceId,
    page: '5',
    position: 'oben',
    text: 'Text $id',
    rawTranscript: 'raw $id',
    createdAt: t0,
    updatedAt: t0.add(Duration(minutes: updated)),
  );
  Tombstone tomb(String id, TombstoneEntityType type) =>
      Tombstone(entityId: id, type: type, deletedAt: t0);

  test('JSON-Roundtrip erhält alle Felder', () {
    final snap = LibrarySnapshot(
      masterGeneration: 3,
      sources: [source('s1', author: 'Mann')],
      notes: [note('n1', 's1', updated: 2)],
      tombstones: [tomb('x', TombstoneEntityType.note)],
    );

    final back = LibrarySnapshot.parse(snap.toJsonString());

    expect(back.masterGeneration, 3);
    expect(back.sources.single, source('s1', author: 'Mann'));
    expect(back.notes.single, note('n1', 's1', updated: 2));
    expect(back.tombstones.single, tomb('x', TombstoneEntityType.note));
  });

  test('toJson trägt Format-Kennung und Version', () {
    final json = const LibrarySnapshot().toJson();
    expect(json['format'], 'booknote-library');
    expect(json['formatVersion'], 1);
  });

  test('masterHard: Default false, Roundtrip', () {
    expect(const LibrarySnapshot().masterHard, isFalse);
    final back = LibrarySnapshot.parse(
      const LibrarySnapshot(
        masterGeneration: 2,
        masterHard: true,
      ).toJsonString(),
    );
    expect(back.masterHard, isTrue);
    expect(back.masterGeneration, 2);
  });

  test('parse lehnt fremdes JSON ab', () {
    expect(
      () => LibrarySnapshot.parse('{"foo": 1}'),
      throwsA(isA<LibraryFileException>()),
    );
    expect(
      () => LibrarySnapshot.parse('kein json'),
      throwsA(isA<LibraryFileException>()),
    );
  });

  test('parse lehnt neuere Formatversion ab', () {
    expect(
      () => LibrarySnapshot.parse(
        '{"format":"booknote-library","formatVersion":99,'
        '"sources":[],"notes":[],"deleted":[]}',
      ),
      throwsA(isA<LibraryFileException>()),
    );
  });

  test('parse verträgt fehlende Listen', () {
    final snap = LibrarySnapshot.parse(
      '{"format":"booknote-library","formatVersion":1}',
    );
    expect(snap.sources, isEmpty);
    expect(snap.notes, isEmpty);
    expect(snap.tombstones, isEmpty);
    expect(snap.masterGeneration, 0);
  });
}
