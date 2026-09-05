import 'package:booknote/repositories/repositories.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ein Paar zusammengehöriger Repositories plus Aufräum-Hook.
class RepositoryPair {
  RepositoryPair(this.books, this.notes, {this.dispose});
  final BookRepository books;
  final NoteRepository notes;
  final Future<void> Function()? dispose;
}

/// Vertragstest: Jede Implementierung von [BookRepository]/[NoteRepository]
/// (In-Memory, SQLite, später Supabase) muss diese Tests bestehen.
///
/// [create] liefert pro Test ein frisches, leeres Repository-Paar.
void runRepositoryContract(
  String name,
  Future<RepositoryPair> Function() create,
) {
  group('$name – Vertrag', () {
    late RepositoryPair r;

    setUp(() async => r = await create());
    tearDown(() async => r.dispose?.call());

    group('BookRepository', () {
      test('leer am Anfang', () async {
        expect(await r.books.getAll(), isEmpty);
      });

      test(
        'create vergibt ID und Zeitstempel, getAll neueste zuerst',
        () async {
          final a = await r.books.create(title: 'A');
          await Future<void>.delayed(const Duration(milliseconds: 2));
          final b = await r.books.create(title: 'B', coverUrl: 'http://c');

          expect(a.id, isNotEmpty);
          expect(a.id, isNot(b.id));
          expect(b.coverUrl, 'http://c');
          expect(a.createdAt, a.updatedAt);

          final all = await r.books.getAll();
          expect(all.map((x) => x.title), ['B', 'A']);
        },
      );

      test('getById', () async {
        final a = await r.books.create(title: 'A');
        expect(await r.books.getById(a.id), a);
        expect(await r.books.getById('nope'), isNull);
      });

      test('update ändert Titel/Cover und updatedAt', () async {
        final a = await r.books.create(title: 'A', coverUrl: 'x');
        await Future<void>.delayed(const Duration(milliseconds: 2));
        await r.books.update(a.copyWith(title: 'A2', clearCoverUrl: true));

        final got = (await r.books.getById(a.id))!;
        expect(got.title, 'A2');
        expect(got.coverUrl, isNull);
        expect(got.createdAt, a.createdAt);
        expect(got.updatedAt.isAfter(a.updatedAt), isTrue);
      });

      test(
        'update/delete unbekannter ID wirft EntityNotFoundException',
        () async {
          final a = await r.books.create(title: 'A');
          await r.books.delete(a.id);
          expect(
            () => r.books.update(a),
            throwsA(isA<EntityNotFoundException>()),
          );
          expect(
            () => r.books.delete(a.id),
            throwsA(isA<EntityNotFoundException>()),
          );
        },
      );

      test('delete löscht Notizen mit', () async {
        final a = await r.books.create(title: 'A');
        final n = await r.notes.create(
          sourceId: a.id,
          text: 't',
          rawTranscript: 'raw',
        );
        await r.books.delete(a.id);
        expect(await r.books.getAll(), isEmpty);
        expect(await r.notes.getById(n.id), isNull);
        expect(await r.notes.countBySource(a.id), 0);
      });

      test('watchAll liefert Startwert und Änderungen', () async {
        final events = <List<String>>[];
        final sub = r.books.watchAll().listen(
          (l) => events.add(l.map((b) => b.title).toList()),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await r.books.create(title: 'A');
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await sub.cancel();
        expect(events.first, isEmpty);
        expect(events.last, ['A']);
      });
    });

    group('NoteRepository', () {
      test('create braucht existierende Quelle', () async {
        expect(
          () => r.notes.create(sourceId: 'nope', text: 't', rawTranscript: 'r'),
          throwsA(isA<EntityNotFoundException>()),
        );
      });

      test('create/getBySource/count', () async {
        final a = await r.books.create(title: 'A');
        final b = await r.books.create(title: 'B');
        final n1 = await r.notes.create(
          sourceId: a.id,
          page: '47',
          position: 'oben',
          text: 'eins',
          rawTranscript: 'Seite 47 oben eins',
        );
        await r.notes.create(sourceId: b.id, text: 'fremd', rawTranscript: 'x');

        expect(n1.id, isNotEmpty);
        expect(n1.page, '47');
        expect(n1.position, 'oben');
        expect(n1.rawTranscript, 'Seite 47 oben eins');

        final list = await r.notes.getBySource(a.id);
        expect(list.map((n) => n.text), ['eins']);
        expect(await r.notes.countBySource(a.id), 1);
        expect(await r.notes.countBySource(b.id), 1);
      });

      test('Sortierung nach createdAt und nach Seite', () async {
        final a = await r.books.create(title: 'A');
        Future<void> add(String? page, String text) async {
          await r.notes.create(
            sourceId: a.id,
            page: page,
            text: text,
            rawTranscript: text,
          );
          await Future<void>.delayed(const Duration(milliseconds: 2));
        }

        await add('88f.', 'c');
        await add(null, 'ohne');
        await add('12', 'a');
        await add('47', 'b');

        final chrono = await r.notes.getBySource(a.id);
        expect(chrono.map((n) => n.text), ['c', 'ohne', 'a', 'b']);

        final byPage = await r.notes.getBySource(a.id, sort: NoteSort.page);
        expect(byPage.map((n) => n.text), ['a', 'b', 'c', 'ohne']);
      });

      test('update ändert Felder, rawTranscript bleibt', () async {
        final a = await r.books.create(title: 'A');
        final n = await r.notes.create(
          sourceId: a.id,
          page: '1',
          text: 't',
          rawTranscript: 'raw',
        );
        await Future<void>.delayed(const Duration(milliseconds: 2));
        await r.notes.update(
          n.copyWith(text: 't2', clearPage: true, position: 'unten'),
        );

        final got = (await r.notes.getById(n.id))!;
        expect(got.text, 't2');
        expect(got.page, isNull);
        expect(got.position, 'unten');
        expect(got.rawTranscript, 'raw');
        expect(got.updatedAt.isAfter(n.updatedAt), isTrue);
      });

      test('delete + Fehler bei unbekannter ID', () async {
        final a = await r.books.create(title: 'A');
        final n = await r.notes.create(
          sourceId: a.id,
          text: 't',
          rawTranscript: 'r',
        );
        await r.notes.delete(n.id);
        expect(await r.notes.getById(n.id), isNull);
        expect(
          () => r.notes.delete(n.id),
          throwsA(isA<EntityNotFoundException>()),
        );
        expect(
          () => r.notes.update(n),
          throwsA(isA<EntityNotFoundException>()),
        );
      });

      test('watchBySource reagiert nur auf die eigene Quelle', () async {
        final a = await r.books.create(title: 'A');
        final b = await r.books.create(title: 'B');
        final events = <int>[];
        final sub = r.notes
            .watchBySource(a.id)
            .listen((l) => events.add(l.length));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await r.notes.create(sourceId: b.id, text: 'x', rawTranscript: 'x');
        await r.notes.create(sourceId: a.id, text: 'y', rawTranscript: 'y');
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await sub.cancel();
        expect(events.first, 0);
        expect(events.last, 1);
      });
    });
  });
}
