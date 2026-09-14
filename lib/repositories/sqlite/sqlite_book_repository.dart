import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../models/models.dart';
import '../book_repository.dart';
import '../repository_exceptions.dart';
import '../watch_stream.dart';
import 'app_database.dart';
import 'sqlite_mappers.dart';

class SqliteBookRepository implements BookRepository {
  SqliteBookRepository(this._db, {Uuid? uuid, DateTime Function()? clock})
    : _uuid = uuid ?? const Uuid(),
      _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final Uuid _uuid;
  final DateTime Function() _clock;

  static const _table = AppDatabase.tableSources;
  static const _where = 'source_type = ?';
  static final _whereArgs = [SourceType.book.dbValue];

  @override
  Future<List<Book>> getAll() async {
    final rows = await _db.db.query(
      _table,
      where: _where,
      whereArgs: _whereArgs,
      orderBy: 'created_at DESC, id',
    );
    return rows.map(bookFromRow).toList();
  }

  @override
  Future<Book?> getById(String id) async {
    final rows = await _db.db.query(
      _table,
      where: '$_where AND id = ?',
      whereArgs: [..._whereArgs, id],
      limit: 1,
    );
    return rows.isEmpty ? null : bookFromRow(rows.first);
  }

  @override
  Future<Book> create({
    required String title,
    String? author,
    String? coverUrl,
    AppLanguage language = AppLanguage.german,
  }) async {
    final now = dbNow(_clock);
    final book = Book(
      id: _uuid.v4(),
      title: title,
      author: author,
      coverUrl: coverUrl,
      language: language,
      createdAt: now,
      updatedAt: now,
    );
    await _db.db.insert(_table, sourceToRow(book));
    _db.notifySources();
    return book;
  }

  @override
  Future<void> update(Book book) async {
    final changed = await _db.db.update(
      _table,
      {
        'title': book.title,
        'author': book.author,
        'cover_url': book.coverUrl,
        'updated_at': dbNow(_clock).millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [book.id],
    );
    if (changed == 0) throw EntityNotFoundException('Book', book.id);
    _db.notifySources();
  }

  @override
  Future<void> delete(String id) async {
    final deletedAt = dbNow(_clock).millisecondsSinceEpoch;
    final changed = await _db.db.transaction((txn) async {
      // Notiz-IDs vor dem Löschen merken – die Zeilen fallen per
      // ON DELETE CASCADE, aber wir brauchen für jede einen Grabstein.
      final noteIds = (await txn.query(
        AppDatabase.tableNotes,
        columns: ['id'],
        where: 'source_id = ?',
        whereArgs: [id],
      )).map((r) => r['id'] as String).toList();

      final c = await txn.delete(_table, where: 'id = ?', whereArgs: [id]);
      if (c > 0) {
        final batch = txn.batch();
        batch.insert(AppDatabase.tableTombstones, {
          'entity_id': id,
          'entity_type': TombstoneEntityType.source.dbValue,
          'deleted_at': deletedAt,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        for (final noteId in noteIds) {
          batch.insert(AppDatabase.tableTombstones, {
            'entity_id': noteId,
            'entity_type': TombstoneEntityType.note.dbValue,
            'deleted_at': deletedAt,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await batch.commit(noResult: true);
      }
      return c;
    });
    if (changed == 0) throw EntityNotFoundException('Book', id);
    _db.notifySources();
    _db.notifyNotes();
  }

  @override
  Stream<List<Book>> watchAll() =>
      watchStreamAsync(_db.onSourcesChanged, getAll);
}
