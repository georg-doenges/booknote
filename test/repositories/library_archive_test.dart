import 'package:booknote/models/models.dart';
import 'package:booknote/repositories/repositories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  late AppDatabase db;
  late SqliteBookRepository books;
  late SqliteNoteRepository notes;
  late LibraryArchive archive;

  setUp(() async {
    db = await AppDatabase.open(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    books = SqliteBookRepository(db);
    notes = SqliteNoteRepository(db);
    archive = LibraryArchive(db);
  });
  tearDown(() => db.close());

  Future<List<Tombstone>> tombstones() async {
    final rows = await db.db.query(AppDatabase.tableTombstones);
    return rows
        .map(
          (r) => Tombstone(
            entityId: r['entity_id'] as String,
            type: TombstoneEntityType.fromDbValue(r['entity_type'] as String),
            deletedAt: DateTime.fromMillisecondsSinceEpoch(
              r['deleted_at'] as int,
              isUtc: true,
            ),
          ),
        )
        .toList();
  }

  test('Notiz löschen schreibt einen Grabstein', () async {
    final b = await books.create(title: 'B');
    final n = await notes.create(sourceId: b.id, text: 't', rawTranscript: 'r');
    await notes.delete(n.id);

    final t = await tombstones();
    expect(t, hasLength(1));
    expect(t.single.entityId, n.id);
    expect(t.single.type, TombstoneEntityType.note);
  });

  test('Buch löschen schreibt Grabsteine für Buch und alle Notizen', () async {
    final b = await books.create(title: 'B');
    final n1 = await notes.create(
      sourceId: b.id,
      text: '1',
      rawTranscript: 'r',
    );
    final n2 = await notes.create(
      sourceId: b.id,
      text: '2',
      rawTranscript: 'r',
    );
    await books.delete(b.id);

    final t = await tombstones();
    expect(t.map((x) => x.entityId).toSet(), {b.id, n1.id, n2.id});
    expect(
      t.firstWhere((x) => x.entityId == b.id).type,
      TombstoneEntityType.source,
    );
  });

  test('readSnapshot / replaceWith Roundtrip', () async {
    final b = await books.create(title: 'B', author: 'Mann');
    await notes.create(
      sourceId: b.id,
      page: '7',
      text: 'hallo',
      rawTranscript: 'r',
    );
    final other = await books.create(title: 'Weg');
    await books.delete(other.id); // erzeugt Grabstein

    final snapshot = await archive.readSnapshot();
    expect(snapshot.sources, hasLength(1));
    expect(snapshot.notes, hasLength(1));
    expect(snapshot.tombstones, hasLength(1));

    // Alles platt machen und den Snapshot zurückspielen.
    await books.delete(b.id);
    expect(await books.getAll(), isEmpty);

    await archive.replaceWith(snapshot);

    final restored = await books.getAll();
    expect(restored.single.title, 'B');
    expect(restored.single.author, 'Mann');
    expect(await notes.getBySource(restored.single.id), hasLength(1));
    expect(
      await archive.readSnapshot().then((s) => s.tombstones),
      hasLength(1),
    );
  });

  test('replaceWith setzt masterGeneration', () async {
    await archive.replaceWith(const LibrarySnapshot(masterGeneration: 4));
    expect((await archive.readSnapshot()).masterGeneration, 4);
  });
}
