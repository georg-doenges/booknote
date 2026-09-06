import '../models/models.dart';

/// Führt zwei Bibliotheks-Stände zusammen (`SYNC_DESIGN.md` §4.2).
///
/// Regel: pro Eintrags-ID gewinnt der **neueste Fakt** – eine lebende Version
/// (Zeitstempel = `updatedAt`) oder ein Grabstein (Zeitstempel = `deletedAt`).
/// Bei exaktem Gleichstand gewinnt der Grabstein. Notizen, deren Buch nach dem
/// Merge nicht mehr lebt, fallen weg. `masterGeneration` = Maximum beider Seiten.
///
/// **Nicht** enthalten: der Master-Kurzschluss (§4.1) – der hängt an
/// geräte­lokalem Zustand und wird vom Aufrufer entschieden.
///
/// Reine Funktion, damit sie ohne DB/IO testbar ist.
LibrarySnapshot mergeLibrary(
  LibrarySnapshot a,
  LibrarySnapshot b, {
  required DateTime now,
  bool gcEnabled = true,
  int gcDays = 120,
}) {
  int ms(DateTime d) => d.toUtc().millisecondsSinceEpoch;

  final winningTs = <String, int>{};
  final liveSources = <String, Source>{};
  final liveNotes = <String, Note>{};
  final tombs = <String, Tombstone>{};

  /// `true`, wenn der neue Fakt den bisher besten für [id] schlägt.
  bool wins(String id, int t, {required bool isTomb}) {
    final cur = winningTs[id];
    if (cur == null || t > cur) return true;
    return t == cur && isTomb; // Löschung gewinnt Gleichstand
  }

  void takeSource(Source s) {
    final t = ms(s.updatedAt);
    if (!wins(s.id, t, isTomb: false)) return;
    winningTs[s.id] = t;
    liveSources[s.id] = s;
    liveNotes.remove(s.id);
    tombs.remove(s.id);
  }

  void takeNote(Note n) {
    final t = ms(n.updatedAt);
    if (!wins(n.id, t, isTomb: false)) return;
    winningTs[n.id] = t;
    liveNotes[n.id] = n;
    liveSources.remove(n.id);
    tombs.remove(n.id);
  }

  void takeTomb(Tombstone tomb) {
    final t = ms(tomb.deletedAt);
    if (!wins(tomb.entityId, t, isTomb: true)) return;
    winningTs[tomb.entityId] = t;
    tombs[tomb.entityId] = tomb;
    liveSources.remove(tomb.entityId);
    liveNotes.remove(tomb.entityId);
  }

  for (final s in a.sources) {
    takeSource(s);
  }
  for (final s in b.sources) {
    takeSource(s);
  }
  for (final n in a.notes) {
    takeNote(n);
  }
  for (final n in b.notes) {
    takeNote(n);
  }
  for (final tomb in a.tombstones) {
    takeTomb(tomb);
  }
  for (final tomb in b.tombstones) {
    takeTomb(tomb);
  }

  // Waisen-Notizen (Buch weg) verwerfen.
  final notes = liveNotes.values
      .where((n) => liveSources.containsKey(n.sourceId))
      .toList();

  var tombstones = tombs.values.toList();
  if (gcEnabled) {
    final cutoff = ms(now) - Duration(days: gcDays).inMilliseconds;
    tombstones = tombstones.where((t) => ms(t.deletedAt) >= cutoff).toList();
  }

  return LibrarySnapshot(
    sources: liveSources.values.toList(),
    notes: notes,
    tombstones: tombstones,
    masterGeneration: a.masterGeneration > b.masterGeneration
        ? a.masterGeneration
        : b.masterGeneration,
  );
}
