import 'package:booknote/models/models.dart';
import 'package:booknote/repositories/repositories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Stellt sicher, dass eine v1-Datenbank sauber auf die aktuelle Version
/// migriert wird und bestehende Daten erhalten bleiben.
void main() {
  setUpAll(sqfliteFfiInit);

  test('v1 → aktuell: author-Spalte wird ergänzt, Daten bleiben', () async {
    final path =
        '${await databaseFactoryFfi.getDatabasesPath()}/mig_${DateTime.now().microsecondsSinceEpoch}.db';
    await databaseFactoryFfi.deleteDatabase(path);

    // v1-Schema von Hand anlegen (so wie AppDatabase v1 es erzeugt hat).
    final v1 = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE sources (
              id TEXT PRIMARY KEY NOT NULL, source_type TEXT NOT NULL,
              title TEXT NOT NULL, cover_url TEXT,
              created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL)''');
          await db.execute('''
            CREATE TABLE notes (
              id TEXT PRIMARY KEY NOT NULL,
              source_id TEXT NOT NULL REFERENCES sources(id) ON DELETE CASCADE,
              page TEXT, position TEXT, text TEXT NOT NULL,
              raw_transcript TEXT NOT NULL,
              created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL)''');
        },
      ),
    );
    await v1.insert('sources', {
      'id': 'b1',
      'source_type': 'book',
      'title': 'Alt',
      'created_at': 1,
      'updated_at': 1,
    });
    await v1.close();

    final db = await AppDatabase.open(path: path, factory: databaseFactoryFfi);
    expect(await db.db.getVersion(), AppDatabase.schemaVersion);

    final books = SqliteBookRepository(db);
    final old = (await books.getById('b1'))!;
    expect(old.title, 'Alt');
    expect(old.author, isNull);
    // v4: language-Spalte fehlte in v1 → Default Deutsch für Altdaten.
    expect(old.language, AppLanguage.german);

    await books.update(old.copyWith(author: 'Neu'));
    expect((await books.getById('b1'))!.author, 'Neu');

    // v3: Sync-Tabellen sind da und benutzbar.
    final tables = (await db.db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table'",
    )).map((r) => r['name']);
    expect(
      tables,
      containsAll([AppDatabase.tableTombstones, AppDatabase.tableMeta]),
    );
    await db.setMeta('k', 'v');
    expect(await db.getMeta('k'), 'v');

    // v4: notes.language ist nutzbar (Default Deutsch, explizit Englisch).
    final notes = SqliteNoteRepository(db);
    final note = await notes.create(
      sourceId: 'b1',
      text: 'x',
      rawTranscript: 'x',
    );
    expect(note.language, AppLanguage.german);
    final enNote = await notes.create(
      sourceId: 'b1',
      text: 'y',
      rawTranscript: 'y',
      language: AppLanguage.english,
    );
    expect(enNote.language, AppLanguage.english);

    await db.close();
    await databaseFactoryFfi.deleteDatabase(path);
  });
}
