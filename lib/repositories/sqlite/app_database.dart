import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../repository_exceptions.dart';

/// Öffnet und verwaltet die lokale SQLite-Datenbank.
///
/// Schema (v1), siehe PROJECT.md Abschnitt 4 – mit zwei bewussten Abweichungen:
/// IDs sind TEXT (UUID v4) und es gibt `updated_at` (beides für späteren Sync).
/// Zeitstempel sind Unix-Millisekunden (UTC) als INTEGER.
///
/// Die Klasse kennt nur Schema, Verbindung und Änderungs-Signale; die
/// Repositories machen die eigentlichen Queries.
class AppDatabase {
  AppDatabase._(this._db);

  static const schemaVersion = 3;
  static const defaultFileName = 'booknote.db';

  static const tableSources = 'sources';
  static const tableNotes = 'notes';
  static const tableTombstones = 'tombstones';
  static const tableMeta = 'meta';

  final Database _db;
  Database get db => _db;

  final _sourcesChanged = StreamController<void>.broadcast();
  final _notesChanged = StreamController<void>.broadcast();

  Stream<void> get onSourcesChanged => _sourcesChanged.stream;
  Stream<void> get onNotesChanged => _notesChanged.stream;

  void notifySources() => _sourcesChanged.add(null);
  void notifyNotes() => _notesChanged.add(null);

  /// Öffnet die Datenbank.
  ///
  /// - Ohne Argumente: Datei `booknote.db` im Standard-Datenbankverzeichnis
  ///   der Plattform (Android + iOS, via sqflite).
  /// - [path] überschreibt den Pfad; `inMemoryDatabasePath` für Tests.
  /// - [factory] erlaubt z.B. `databaseFactoryFfi` für Desktop-Tests.
  static Future<AppDatabase> open({
    String? path,
    DatabaseFactory? factory,
  }) async {
    final f = factory ?? databaseFactory;
    final dbPath = path ?? p.join(await f.getDatabasesPath(), defaultFileName);
    try {
      final db = await f.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: schemaVersion,
          onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
      return AppDatabase._(db);
    } catch (e) {
      throw RepositoryException('Datenbank konnte nicht geöffnet werden', e);
    }
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableSources (
        id          TEXT PRIMARY KEY NOT NULL,
        source_type TEXT NOT NULL,
        title       TEXT NOT NULL,
        author      TEXT,
        cover_url   TEXT,
        created_at  INTEGER NOT NULL,
        updated_at  INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE $tableNotes (
        id             TEXT PRIMARY KEY NOT NULL,
        source_id      TEXT NOT NULL
                       REFERENCES $tableSources(id) ON DELETE CASCADE,
        page           TEXT,
        position       TEXT,
        text           TEXT NOT NULL,
        raw_transcript TEXT NOT NULL,
        created_at     INTEGER NOT NULL,
        updated_at     INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_notes_source ON $tableNotes(source_id, created_at)',
    );
    await db.execute(
      'CREATE INDEX idx_sources_created ON $tableSources(created_at)',
    );
    await _createSyncTables(db);
  }

  /// Tabellen für den Geräte-Abgleich (siehe `SYNC_DESIGN.md`).
  static Future<void> _createSyncTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableTombstones (
        entity_id   TEXT PRIMARY KEY NOT NULL,
        entity_type TEXT NOT NULL,
        deleted_at  INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableMeta (
        key   TEXT PRIMARY KEY NOT NULL,
        value TEXT NOT NULL
      )
    ''');
  }

  Future<String?> getMeta(String key) async {
    final rows = await _db.query(
      tableMeta,
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  Future<void> setMeta(String key, String value) => _db.insert(tableMeta, {
    'key': key,
    'value': value,
  }, conflictAlgorithm: ConflictAlgorithm.replace);

  /// Migrationen. Bei Schemaänderung [schemaVersion] erhöhen und hier pro
  /// Versionssprung die nötigen Schritte ergänzen (sqflite führt sie in einer
  /// Transaktion aus).
  ///
  /// Historie:
  /// - v1: sources, notes
  /// - v2: sources.author (TEXT, nullable)
  /// - v3: tombstones + meta (Geräte-Abgleich, siehe `SYNC_DESIGN.md`)
  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE $tableSources ADD COLUMN author TEXT');
    }
    if (oldVersion < 3) {
      await _createSyncTables(db);
    }
  }

  Future<void> close() async {
    await _sourcesChanged.close();
    await _notesChanged.close();
    await _db.close();
  }
}
