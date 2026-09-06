import '../../models/models.dart';

/// Mapping zwischen Modellobjekten und SQLite-Zeilen.
///
/// Liegt bewusst hier und nicht in den Modellen: Supabase bekommt später
/// sein eigenes Mapping (z.B. ISO-Strings statt Unix-ms).

int _toMillis(DateTime t) => t.toUtc().millisecondsSinceEpoch;
DateTime _fromMillis(int ms) =>
    DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);

/// Normalisiert einen Zeitpunkt auf das, was aus der DB zurückkommt
/// (UTC, Millisekunden-Auflösung). So sind Objekte vor und nach dem
/// Speichern `==`.
DateTime dbNow(DateTime Function() clock) => _fromMillis(_toMillis(clock()));

Map<String, Object?> sourceToRow(Source s) => {
  'id': s.id,
  'source_type': s.sourceType.dbValue,
  'title': s.title,
  'author': s.author,
  'cover_url': s.coverUrl,
  'created_at': _toMillis(s.createdAt),
  'updated_at': _toMillis(s.updatedAt),
};

Source sourceFromRow(Map<String, Object?> r) => Source(
  id: r['id'] as String,
  sourceType: SourceType.fromDbValue(r['source_type'] as String),
  title: r['title'] as String,
  author: r['author'] as String?,
  coverUrl: r['cover_url'] as String?,
  createdAt: _fromMillis(r['created_at'] as int),
  updatedAt: _fromMillis(r['updated_at'] as int),
);

Book bookFromRow(Map<String, Object?> r) => Book.fromSource(sourceFromRow(r));

Map<String, Object?> noteToRow(Note n) => {
  'id': n.id,
  'source_id': n.sourceId,
  'page': n.page,
  'position': n.position,
  'text': n.text,
  'raw_transcript': n.rawTranscript,
  'created_at': _toMillis(n.createdAt),
  'updated_at': _toMillis(n.updatedAt),
};

Note noteFromRow(Map<String, Object?> r) => Note(
  id: r['id'] as String,
  sourceId: r['source_id'] as String,
  page: r['page'] as String?,
  position: r['position'] as String?,
  text: r['text'] as String,
  rawTranscript: r['raw_transcript'] as String,
  createdAt: _fromMillis(r['created_at'] as int),
  updatedAt: _fromMillis(r['updated_at'] as int),
);

Map<String, Object?> tombstoneToRow(Tombstone t) => {
  'entity_id': t.entityId,
  'entity_type': t.type.dbValue,
  'deleted_at': _toMillis(t.deletedAt),
};

Tombstone tombstoneFromRow(Map<String, Object?> r) => Tombstone(
  entityId: r['entity_id'] as String,
  type: TombstoneEntityType.fromDbValue(r['entity_type'] as String),
  deletedAt: _fromMillis(r['deleted_at'] as int),
);
