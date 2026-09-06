import 'package:booknote/repositories/repositories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'repository_contract.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  runRepositoryContract('SQLite', () async {
    final db = await AppDatabase.open(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    return RepositoryPair(
      SqliteBookRepository(db),
      SqliteNoteRepository(db),
      dispose: db.close,
    );
  });

  test('Schema: foreign_keys aktiv, Tabellen vorhanden', () async {
    final db = await AppDatabase.open(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    final fk = await db.db.rawQuery('PRAGMA foreign_keys');
    expect(fk.first.values.first, 1);
    final tables = await db.db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name",
    );
    expect(
      tables.map((r) => r['name']),
      containsAll([
        AppDatabase.tableSources,
        AppDatabase.tableNotes,
        AppDatabase.tableTombstones,
        AppDatabase.tableMeta,
      ]),
    );
    expect(await db.db.getVersion(), AppDatabase.schemaVersion);
    await db.close();
  });
}
