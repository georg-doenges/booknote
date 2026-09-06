import 'package:sqflite/sqflite.dart';

import '../../models/models.dart';
import 'app_database.dart';
import 'sqlite_mappers.dart';

/// Liest den kompletten Bibliotheks-Zustand aus der DB und schreibt ihn
/// (nach einem Merge) komplett zurück. Für den Geräte-Abgleich, siehe
/// `SYNC_DESIGN.md`.
class LibraryArchive {
  LibraryArchive(this._db);

  final AppDatabase _db;

  static const _masterGenKey = 'master_generation';

  Future<LibrarySnapshot> readSnapshot() async {
    final sourceRows = await _db.db.query(AppDatabase.tableSources);
    final noteRows = await _db.db.query(AppDatabase.tableNotes);
    final tombRows = await _db.db.query(AppDatabase.tableTombstones);
    final gen = int.tryParse(await _db.getMeta(_masterGenKey) ?? '') ?? 0;
    return LibrarySnapshot(
      sources: sourceRows.map(sourceFromRow).toList(),
      notes: noteRows.map(noteFromRow).toList(),
      tombstones: tombRows.map(tombstoneFromRow).toList(),
      masterGeneration: gen,
    );
  }

  /// Ersetzt den gesamten lokalen Stand durch [snapshot] – in einer
  /// Transaktion. Das Merge-Ergebnis ist per Konstruktion ein Superset der
  /// lebenden lokalen Daten, deshalb ist das „alles ersetzen" verlustfrei.
  Future<void> replaceWith(LibrarySnapshot snapshot) async {
    await _db.db.transaction((txn) async {
      await txn.delete(AppDatabase.tableNotes);
      await txn.delete(AppDatabase.tableSources);
      await txn.delete(AppDatabase.tableTombstones);

      final batch = txn.batch();
      for (final s in snapshot.sources) {
        batch.insert(AppDatabase.tableSources, sourceToRow(s));
      }
      for (final n in snapshot.notes) {
        batch.insert(AppDatabase.tableNotes, noteToRow(n));
      }
      for (final t in snapshot.tombstones) {
        batch.insert(AppDatabase.tableTombstones, tombstoneToRow(t));
      }
      batch.insert(AppDatabase.tableMeta, {
        'key': _masterGenKey,
        'value': '${snapshot.masterGeneration}',
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await batch.commit(noResult: true);
    });
    _db.notifySources();
    _db.notifyNotes();
  }
}
