import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../models/models.dart';
import '../note_repository.dart';
import '../repository_exceptions.dart';
import '../watch_stream.dart';
import 'app_database.dart';
import 'sqlite_mappers.dart';

class SqliteNoteRepository implements NoteRepository {
  SqliteNoteRepository(this._db, {Uuid? uuid, DateTime Function()? clock})
    : _uuid = uuid ?? const Uuid(),
      _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final Uuid _uuid;
  final DateTime Function() _clock;

  static const _table = AppDatabase.tableNotes;

  @override
  Future<List<Note>> getBySource(
    String sourceId, {
    NoteSort sort = NoteSort.createdAt,
  }) async {
    final rows = await _db.db.query(
      _table,
      where: 'source_id = ?',
      whereArgs: [sourceId],
      orderBy: 'created_at, id',
    );
    // Seiten-Sortierung in Dart (sortNotes), damit "88f." etc. überall
    // identisch behandelt wird und Supabase dieselbe Logik nutzen kann.
    return sortNotes(rows.map(noteFromRow).toList(), sort);
  }

  @override
  Future<Note?> getById(String id) async {
    final rows = await _db.db.query(
      _table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : noteFromRow(rows.first);
  }

  @override
  Future<int> countBySource(String sourceId) async {
    final n = Sqflite.firstIntValue(
      await _db.db.rawQuery(
        'SELECT COUNT(*) FROM $_table WHERE source_id = ?',
        [sourceId],
      ),
    );
    return n ?? 0;
  }

  @override
  Future<Note> create({
    required String sourceId,
    String? page,
    String? position,
    required String text,
    required String rawTranscript,
  }) async {
    final now = dbNow(_clock);
    final note = Note(
      id: _uuid.v4(),
      sourceId: sourceId,
      page: page,
      position: position,
      text: text,
      rawTranscript: rawTranscript,
      createdAt: now,
      updatedAt: now,
    );
    await _db.db.transaction((txn) async {
      final exists = await txn.query(
        AppDatabase.tableSources,
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [sourceId],
        limit: 1,
      );
      if (exists.isEmpty) throw EntityNotFoundException('Source', sourceId);
      await txn.insert(_table, noteToRow(note));
    });
    _db.notifyNotes();
    return note;
  }

  @override
  Future<void> update(Note note) async {
    final changed = await _db.db.update(
      _table,
      {
        'page': note.page,
        'position': note.position,
        'text': note.text,
        'updated_at': dbNow(_clock).millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [note.id],
    );
    if (changed == 0) throw EntityNotFoundException('Note', note.id);
    _db.notifyNotes();
  }

  @override
  Future<void> delete(String id) async {
    final deletedAt = dbNow(_clock).millisecondsSinceEpoch;
    final changed = await _db.db.transaction((txn) async {
      final c = await txn.delete(_table, where: 'id = ?', whereArgs: [id]);
      if (c > 0) {
        // Grabstein, damit die Löschung den Geräte-Abgleich übersteht.
        await txn.insert(AppDatabase.tableTombstones, {
          'entity_id': id,
          'entity_type': TombstoneEntityType.note.dbValue,
          'deleted_at': deletedAt,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      return c;
    });
    if (changed == 0) throw EntityNotFoundException('Note', id);
    _db.notifyNotes();
  }

  @override
  Stream<List<Note>> watchBySource(
    String sourceId, {
    NoteSort sort = NoteSort.createdAt,
  }) => watchStreamAsync(
    _db.onNotesChanged,
    () => getBySource(sourceId, sort: sort),
  );
}
