import 'dart:convert';

import 'note.dart';
import 'source.dart';
import 'source_type.dart';
import 'tombstone.dart';

/// Der vollständige Zustand der Bibliothek als Wertobjekt: alle Quellen, alle
/// Notizen, alle Grabsteine, plus [masterGeneration] (siehe `SYNC_DESIGN.md`).
///
/// Wird sowohl aus der DB gelesen (`LibraryArchive.readSnapshot`) als auch aus
/// einer `booknote-library.json` geparst, und ist die Ein-/Ausgabe von
/// `mergeLibrary`. Das JSON-Mapping liegt hier (nicht in `sqlite_mappers.dart`):
/// das Dateiformat ist ein eigener, stabiler Vertrag.
class LibrarySnapshot {
  const LibrarySnapshot({
    this.sources = const [],
    this.notes = const [],
    this.tombstones = const [],
    this.masterGeneration = 0,
  });

  final List<Source> sources;
  final List<Note> notes;
  final List<Tombstone> tombstones;
  final int masterGeneration;

  static const formatId = 'booknote-library';

  /// Höchste Formatversion, die diese App **schreiben** kann. Beim Lesen wird
  /// alles `<=` akzeptiert; höhere Versionen werden abgelehnt.
  static const formatVersion = 1;

  int get sourceCount => sources.length;
  int get noteCount => notes.length;

  // ---- JSON ----

  Map<String, Object?> toJson() => {
    'format': formatId,
    'formatVersion': formatVersion,
    'exportedAt': DateTime.now().toUtc().millisecondsSinceEpoch,
    'masterGeneration': masterGeneration,
    'sources': sources.map(_sourceToJson).toList(),
    'notes': notes.map(_noteToJson).toList(),
    'deleted': tombstones.map(_tombstoneToJson).toList(),
  };

  String toJsonString() => const JsonEncoder.withIndent('  ').convert(toJson());

  /// Parst einen Dateiinhalt. Wirft [LibraryFileException] bei falschem Format.
  static LibrarySnapshot parse(String text) {
    final Object? decoded;
    try {
      decoded = jsonDecode(text);
    } catch (e) {
      throw const LibraryFileException('Die Datei ist kein gültiges JSON.');
    }
    if (decoded is! Map<String, Object?>) {
      throw const LibraryFileException('Unerwarteter Dateiaufbau.');
    }
    if (decoded['format'] != formatId) {
      throw const LibraryFileException(
        'Das ist keine Booknote-Bibliotheksdatei.',
      );
    }
    final version = decoded['formatVersion'];
    if (version is! int || version > formatVersion) {
      throw const LibraryFileException(
        'Die Datei stammt aus einer neueren App-Version.',
      );
    }
    try {
      return LibrarySnapshot(
        masterGeneration: (decoded['masterGeneration'] as num?)?.toInt() ?? 0,
        sources: [
          for (final s in (decoded['sources'] as List? ?? const []))
            _sourceFromJson(s as Map<String, Object?>),
        ],
        notes: [
          for (final n in (decoded['notes'] as List? ?? const []))
            _noteFromJson(n as Map<String, Object?>),
        ],
        tombstones: [
          for (final t in (decoded['deleted'] as List? ?? const []))
            _tombstoneFromJson(t as Map<String, Object?>),
        ],
      );
    } catch (e) {
      throw LibraryFileException('Die Datei ist beschädigt: $e');
    }
  }

  static int _ms(DateTime d) => d.toUtc().millisecondsSinceEpoch;
  static DateTime _dt(Object? ms) =>
      DateTime.fromMillisecondsSinceEpoch((ms as num).toInt(), isUtc: true);

  static Map<String, Object?> _sourceToJson(Source s) => {
    'id': s.id,
    'sourceType': s.sourceType.dbValue,
    'title': s.title,
    'author': s.author,
    'coverUrl': s.coverUrl,
    'createdAt': _ms(s.createdAt),
    'updatedAt': _ms(s.updatedAt),
  };

  static Source _sourceFromJson(Map<String, Object?> j) => Source(
    id: j['id'] as String,
    sourceType: SourceType.fromDbValue(j['sourceType'] as String),
    title: j['title'] as String,
    author: j['author'] as String?,
    coverUrl: j['coverUrl'] as String?,
    createdAt: _dt(j['createdAt']),
    updatedAt: _dt(j['updatedAt']),
  );

  static Map<String, Object?> _noteToJson(Note n) => {
    'id': n.id,
    'sourceId': n.sourceId,
    'page': n.page,
    'position': n.position,
    'text': n.text,
    'rawTranscript': n.rawTranscript,
    'createdAt': _ms(n.createdAt),
    'updatedAt': _ms(n.updatedAt),
  };

  static Note _noteFromJson(Map<String, Object?> j) => Note(
    id: j['id'] as String,
    sourceId: j['sourceId'] as String,
    page: j['page'] as String?,
    position: j['position'] as String?,
    text: j['text'] as String,
    rawTranscript: j['rawTranscript'] as String? ?? '',
    createdAt: _dt(j['createdAt']),
    updatedAt: _dt(j['updatedAt']),
  );

  static Map<String, Object?> _tombstoneToJson(Tombstone t) => {
    'id': t.entityId,
    'type': t.type.dbValue,
    'deletedAt': _ms(t.deletedAt),
  };

  static Tombstone _tombstoneFromJson(Map<String, Object?> j) => Tombstone(
    entityId: j['id'] as String,
    type: TombstoneEntityType.fromDbValue(j['type'] as String),
    deletedAt: _dt(j['deletedAt']),
  );
}

/// Eine Bibliotheksdatei ließ sich nicht lesen (falsches Format, beschädigt,
/// neuere App-Version).
class LibraryFileException implements Exception {
  const LibraryFileException(this.message);

  final String message;

  @override
  String toString() => 'LibraryFileException: $message';
}
