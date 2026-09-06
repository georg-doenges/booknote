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
  LibrarySnapshot adopt(LibrarySnapshot local, LibrarySnapshot master) =>
      adoptMaster(local, master, now: now, gcEnabled: false);

  group('mergeLibrary – rein additiv', () {
    test('Union: was auf einer Seite lebt, bleibt', () {
      final m = merge(
        snap(sources: [src('s1', updated: 1)]),
        snap(sources: [src('s2', updated: 1)]),
      );
      expect(m.sources.map((s) => s.id).toSet(), {'s1', 's2'});
    });

    test('Inhaltskonflikt: neueres updatedAt gewinnt', () {
      final a = snap(sources: [src('s1', updated: 5, title: 'alt')]);
      final b = snap(sources: [src('s1', updated: 9, title: 'neu')]);
      expect(merge(a, b).sources.single.title, 'neu');
      expect(merge(b, a).sources.single.title, 'neu');
    });

    test('Löschung wird NICHT übertragen: lebt woanders → kommt zurück', () {
      final a = snap(tombstones: [tmb('s1', TombstoneEntityType.source, 10)]);
      final b = snap(sources: [src('s1', updated: 3)]);
      final m = merge(a, b);
      expect(m.sources.single.id, 's1');
      // Eintrag lebt wieder → sein Grabstein ist weg.
      expect(m.tombstones, isEmpty);
    });

    test('Grabstein bleibt erhalten, wenn der Eintrag nirgends mehr lebt', () {
      final a = snap(tombstones: [tmb('s1', TombstoneEntityType.source, 10)]);
      final b = snap();
      expect(merge(a, b).tombstones.single.entityId, 's1');
    });

    test('Waisen-Notiz wird verworfen', () {
      final a = snap(
        sources: [src('s1', updated: 1)],
        notes: [nte('n1', 's1', updated: 1)],
      );
      final b = snap(notes: [nte('n9', 'weg', updated: 1)]);
      final m = merge(a, b);
      expect(m.notes.map((n) => n.id), ['n1']);
    });

    test('masterGeneration = Maximum', () {
      expect(
        merge(
          snap(masterGeneration: 2),
          snap(masterGeneration: 7),
        ).masterGeneration,
        7,
      );
    });
  });

  group('adoptMaster', () {
    test('Master-Grabstein wird angewendet: lokaler Eintrag fällt weg', () {
      final local = snap(
        sources: [src('s1', updated: 1), src('s2', updated: 1)],
      );
      final master = snap(
        sources: [src('s2', updated: 1)],
        tombstones: [tmb('s1', TombstoneEntityType.source, 10)],
        masterGeneration: 3,
      );
      final m = adopt(local, master);
      expect(m.sources.map((s) => s.id), ['s2']);
      expect(m.masterGeneration, 3);
    });

    test('lokal Neues (Master kennt es nicht) bleibt erhalten', () {
      final local = snap(
        sources: [src('s1', updated: 1), src('neu', updated: 5)],
        notes: [nte('nNeu', 'neu', updated: 5)],
      );
      final master = snap(
        sources: [src('s1', updated: 2)],
        tombstones: [],
        masterGeneration: 4,
      );
      final m = adopt(local, master);
      expect(m.sources.map((s) => s.id).toSet(), {'s1', 'neu'});
      expect(m.notes.map((n) => n.id), ['nNeu']);
    });

    test(
      'bei bekanntem Eintrag gewinnt der Master (auch gegen neueren lokal)',
      () {
        final local = snap(
          sources: [src('s1', updated: 99, title: 'lokal neu')],
        );
        final master = snap(
          sources: [src('s1', updated: 1, title: 'master')],
          masterGeneration: 2,
        );
        expect(adopt(local, master).sources.single.title, 'master');
      },
    );

    test('Notiz eines vom Master gelöschten Buchs wird zur Waise → weg', () {
      final local = snap(
        sources: [src('b', updated: 1)],
        notes: [nte('n', 'b', updated: 1)],
      );
      final master = snap(
        tombstones: [tmb('b', TombstoneEntityType.source, 10)],
        masterGeneration: 5,
      );
      final m = adopt(local, master);
      expect(m.sources, isEmpty);
      expect(m.notes, isEmpty);
    });
  });

  test('GC entfernt alte Grabsteine (Merge und Adopt)', () {
    final oldT = Tombstone(
      entityId: 'x',
      type: TombstoneEntityType.note,
      deletedAt: now.subtract(const Duration(days: 200)),
    );
    final freshT = Tombstone(
      entityId: 'y',
      type: TombstoneEntityType.note,
      deletedAt: now.subtract(const Duration(days: 10)),
    );
    final m = mergeLibrary(
      snap(tombstones: [oldT, freshT]),
      snap(),
      now: now,
      gcEnabled: true,
      gcDays: 120,
    );
    expect(m.tombstones.map((t) => t.entityId), ['y']);
  });
}
