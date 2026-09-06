import '../models/models.dart';

/// Zwei Bibliotheks-Stände zusammenführen (`SYNC_DESIGN.md` §4).
///
/// **Rein additiv:** Alles, was auf einer der beiden Seiten noch lebt, ist
/// danach dabei. Bei einem Inhaltskonflikt (dieselbe ID auf beiden Seiten
/// lebendig) gewinnt der neuere `updatedAt`. **Löschungen werden nicht
/// übertragen** – Grabsteine werden mitgeführt, aber nicht angewendet. Sie
/// wirken erst beim [adoptMaster].
///
/// Invariante der Ausgabe: lebendig und Grabstein schließen sich aus (kommt ein
/// Eintrag im Merge wieder zum Leben, verschwindet sein Grabstein).
LibrarySnapshot mergeLibrary(
  LibrarySnapshot a,
  LibrarySnapshot b, {
  required DateTime now,
  bool gcEnabled = true,
  int gcDays = 120,
}) {
  final sources = _newestById<Source>(
    [...a.sources, ...b.sources],
    (s) => s.id,
    (s) => s.updatedAt,
  );
  final notes = _newestById<Note>(
    [...a.notes, ...b.notes],
    (n) => n.id,
    (n) => n.updatedAt,
  );
  return _finish(
    sources: sources,
    notes: notes,
    incomingTombstones: [...a.tombstones, ...b.tombstones],
    masterGeneration: a.masterGeneration > b.masterGeneration
        ? a.masterGeneration
        : b.masterGeneration,
    now: now,
    gcEnabled: gcEnabled,
    gcDays: gcDays,
  );
}

/// Einen Master-Stand übernehmen (`SYNC_DESIGN.md` §5).
///
/// [master] ist verbindlich für alles, was er kennt: seine lebenden Einträge
/// gewinnen, seine Grabsteine werden **angewendet** (entsprechende lokale
/// Einträge fallen weg). Lokale Einträge, die der Master **nie gesehen hat**
/// (weder lebendig noch als Grabstein), bleiben erhalten – sie sind auf diesem
/// Gerät neu dazugekommen.
LibrarySnapshot adoptMaster(
  LibrarySnapshot local,
  LibrarySnapshot master, {
  required DateTime now,
  bool gcEnabled = true,
  int gcDays = 120,
}) {
  final knownToMaster = <String>{
    ...master.sources.map((s) => s.id),
    ...master.notes.map((n) => n.id),
    ...master.tombstones.map((t) => t.entityId),
  };

  final sources = {for (final s in master.sources) s.id: s};
  for (final s in local.sources) {
    if (!knownToMaster.contains(s.id)) sources[s.id] = s;
  }
  final notes = {for (final n in master.notes) n.id: n};
  for (final n in local.notes) {
    if (!knownToMaster.contains(n.id)) notes[n.id] = n;
  }

  return _finish(
    sources: sources,
    notes: notes,
    incomingTombstones: [...local.tombstones, ...master.tombstones],
    masterGeneration: master.masterGeneration,
    now: now,
    gcEnabled: gcEnabled,
    gcDays: gcDays,
  );
}

Map<String, T> _newestById<T>(
  Iterable<T> items,
  String Function(T) id,
  DateTime Function(T) updatedAt,
) {
  final out = <String, T>{};
  for (final it in items) {
    final cur = out[id(it)];
    if (cur == null || updatedAt(it).isAfter(updatedAt(cur))) out[id(it)] = it;
  }
  return out;
}

LibrarySnapshot _finish({
  required Map<String, Source> sources,
  required Map<String, Note> notes,
  required List<Tombstone> incomingTombstones,
  required int masterGeneration,
  required DateTime now,
  required bool gcEnabled,
  required int gcDays,
}) {
  // Waisen-Notizen (Buch weg) verwerfen.
  final liveNotes = notes.values
      .where((n) => sources.containsKey(n.sourceId))
      .toList();

  // Jüngsten Grabstein je ID behalten, aber nur solange der Eintrag nicht
  // (wieder) lebt.
  final tombs = <String, Tombstone>{};
  for (final t in incomingTombstones) {
    final cur = tombs[t.entityId];
    if (cur == null || t.deletedAt.isAfter(cur.deletedAt)) {
      tombs[t.entityId] = t;
    }
  }
  final liveNoteIds = liveNotes.map((n) => n.id).toSet();
  var tombstones = tombs.values
      .where(
        (t) =>
            !sources.containsKey(t.entityId) &&
            !liveNoteIds.contains(t.entityId),
      )
      .toList();

  if (gcEnabled) {
    final cutoffMs =
        now.toUtc().millisecondsSinceEpoch -
        Duration(days: gcDays).inMilliseconds;
    tombstones = tombstones
        .where((t) => t.deletedAt.toUtc().millisecondsSinceEpoch >= cutoffMs)
        .toList();
  }

  return LibrarySnapshot(
    sources: sources.values.toList(),
    notes: liveNotes,
    tombstones: tombstones,
    masterGeneration: masterGeneration,
  );
}
