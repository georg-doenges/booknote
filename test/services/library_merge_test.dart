import 'package:booknote/models/models.dart';
import 'package:booknote/services/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final base = DateTime.utc(2026, 1, 1);
  DateTime at(int min) => base.add(Duration(minutes: min));

  Source src(String id, {required int updated, String title = 'T'}) => Source(
    id: id,
    sourceType: SourceType.book,
    title: title,
    createdAt: base,
    updatedAt: at(updated),
  );
  Note nte(
    String id,
    String sourceId, {
    required int updated,
    String text = 't',
  }) => Note(
    id: id,
    sourceId: sourceId,
    text: text,
    rawTranscript: 'r',
    createdAt: base,
    updatedAt: at(updated),
  );
  Tombstone tmb(String id, TombstoneEntityType type, int deleted) =>
      Tombstone(entityId: id, type: type, deletedAt: at(deleted));

  LibrarySnapshot snap({
    List<Source> sources = const [],
    List<Note> notes = const [],
    List<Tombstone> tombstones = const [],
    int masterGeneration = 0,
  }) => LibrarySnapshot(
    sources: sources,
    notes: notes,
    tombstones: tombstones,
    masterGeneration: masterGeneration,
  );

  final now = at(1000);
  LibrarySnapshot merge(LibrarySnapshot a, LibrarySnapshot b) =>
      mergeLibrary(a, b, now: now, gcEnabled: false);

  test('Union: Eintrag nur auf einer Seite bleibt', () {
    final a = snap(sources: [src('s1', updated: 1)]);
    final b = snap(sources: [src('s2', updated: 1)]);
    final m = merge(a, b);
    expect(m.sources.map((s) => s.id).toSet(), {'s1', 's2'});
  });

  test('gemeinsamer Eintrag: neueres updatedAt gewinnt', () {
    final a = snap(sources: [src('s1', updated: 5, title: 'alt')]);
    final b = snap(sources: [src('s1', updated: 9, title: 'neu')]);
    expect(merge(a, b).sources.single.title, 'neu');
    expect(merge(b, a).sources.single.title, 'neu');
  });

  test('auf A gelöscht, auf B unangetastet → überall weg', () {
    final a = snap(tombstones: [tmb('s1', TombstoneEntityType.source, 10)]);
    final b = snap(sources: [src('s1', updated: 3)]);
    final m = merge(a, b);
    expect(m.sources, isEmpty);
    expect(m.tombstones.single.entityId, 's1');
  });

  test('auf A gelöscht, danach auf B bearbeitet → kommt zurück', () {
    final a = snap(tombstones: [tmb('s1', TombstoneEntityType.source, 10)]);
    final b = snap(sources: [src('s1', updated: 20)]);
    final m = merge(a, b);
    expect(m.sources.single.id, 's1');
    expect(m.tombstones, isEmpty);
  });

  test('Gleichstand: Löschung gewinnt', () {
    final a = snap(sources: [src('s1', updated: 10)]);
    final b = snap(tombstones: [tmb('s1', TombstoneEntityType.source, 10)]);
    expect(merge(a, b).sources, isEmpty);
    expect(merge(b, a).sources, isEmpty);
  });

  test('Waisen-Notiz (Buch gelöscht) fällt weg', () {
    final a = snap(
      sources: [src('s1', updated: 1)],
      notes: [nte('n1', 's1', updated: 1)],
    );
    final b = snap(tombstones: [tmb('s1', TombstoneEntityType.source, 10)]);
    final m = merge(a, b);
    expect(m.sources, isEmpty);
    expect(m.notes, isEmpty);
  });

  test('einzeln gelöschte Notiz bleibt gelöscht, Buch bleibt', () {
    final a = snap(
      sources: [src('s1', updated: 1)],
      tombstones: [tmb('n1', TombstoneEntityType.note, 10)],
    );
    final b = snap(
      sources: [src('s1', updated: 1)],
      notes: [nte('n1', 's1', updated: 2), nte('n2', 's1', updated: 2)],
    );
    final m = merge(a, b);
    expect(m.sources.single.id, 's1');
    expect(m.notes.map((n) => n.id), ['n2']);
  });

  test('masterGeneration = Maximum beider Seiten', () {
    expect(
      merge(
        snap(masterGeneration: 2),
        snap(masterGeneration: 7),
      ).masterGeneration,
      7,
    );
  });

  test('GC entfernt Grabsteine älter als gcDays', () {
    final old = Tombstone(
      entityId: 'x',
      type: TombstoneEntityType.note,
      deletedAt: now.subtract(const Duration(days: 200)),
    );
    final fresh = Tombstone(
      entityId: 'y',
      type: TombstoneEntityType.note,
      deletedAt: now.subtract(const Duration(days: 10)),
    );
    final m = mergeLibrary(
      snap(tombstones: [old, fresh]),
      snap(),
      now: now,
      gcEnabled: true,
      gcDays: 120,
    );
    expect(m.tombstones.map((t) => t.entityId), ['y']);
  });

  test('GC aus: alte Grabsteine bleiben', () {
    final old = Tombstone(
      entityId: 'x',
      type: TombstoneEntityType.note,
      deletedAt: now.subtract(const Duration(days: 200)),
    );
    final m = mergeLibrary(
      snap(tombstones: [old]),
      snap(),
      now: now,
      gcEnabled: false,
    );
    expect(m.tombstones, hasLength(1));
  });
}
