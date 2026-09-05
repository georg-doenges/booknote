import 'dart:convert';

import 'package:booknote/services/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _Fixed implements CoverService {
  _Fixed(this.result, {this.error});
  final List<CoverCandidate> result;
  final CoverSearchException? error;
  int calls = 0;

  @override
  Future<List<CoverCandidate>> search(String query) async {
    calls++;
    if (error != null) throw error!;
    return result;
  }
}

const _c = CoverCandidate(title: 'T', provider: 'x');

void main() {
  group('FallbackCoverService', () {
    test('nimmt Primärquelle, wenn sie Treffer hat', () async {
      final p = _Fixed([_c]);
      final f = _Fixed([_c, _c]);
      final r = await FallbackCoverService(primary: p, fallback: f).search('q');
      expect(r.length, 1);
      expect(f.calls, 0);
    });

    test('fällt bei leerem Ergebnis zurück', () async {
      final p = _Fixed([]);
      final f = _Fixed([_c]);
      final r = await FallbackCoverService(primary: p, fallback: f).search('q');
      expect(r.length, 1);
    });

    test('fällt bei Fehler der Primärquelle zurück', () async {
      final p = _Fixed([], error: const CoverSearchException('down'));
      final f = _Fixed([_c]);
      final r = await FallbackCoverService(primary: p, fallback: f).search('q');
      expect(r.length, 1);
    });

    test('beide fehlerhaft → Fehler der Primärquelle', () async {
      final p = _Fixed([], error: const CoverSearchException('primary'));
      final f = _Fixed([], error: const CoverSearchException('fallback'));
      expect(
        () => FallbackCoverService(primary: p, fallback: f).search('q'),
        throwsA(
          isA<CoverSearchException>().having((e) => e.message, 'm', 'primary'),
        ),
      );
    });
  });

  group('GoogleBooksCoverService', () {
    test('parst Treffer, https + zoom, hängt Key an', () async {
      late http.Request captured;
      final s = GoogleBooksCoverService(
        apiKeys: InMemoryApiKeyStore(googleBooksKey: 'gk'),
        client: MockClient((req) async {
          captured = req;
          return http.Response(
            jsonEncode({
              'items': [
                {
                  'volumeInfo': {
                    'title': 'Der Zauberberg',
                    'authors': ['Thomas Mann'],
                    'imageLinks': {
                      'thumbnail': 'http://books.google.com/books/content?id=1&zoom=5&edge=curl&source=gbs_api',
                    },
                  },
                },
                {
                  'volumeInfo': {
                    'title': 'Ohne Bild',
                    'subtitle': 'Ein Untertitel',
                  },
                },
                {'volumeInfo': {}},
              ],
            }),
            200,
          );
        }),
      );

      final r = await s.search('Zauberberg');

      expect(captured.url.queryParameters['q'], 'Zauberberg');
      expect(captured.url.queryParameters['key'], 'gk');
      expect(r.length, 2);
      expect(r[0].title, 'Der Zauberberg');
      expect(r[0].author, 'Thomas Mann');
      expect(r[0].coverUrl, startsWith('https://'));
      expect(r[0].coverUrl, contains('zoom=1'));
      expect(r[0].coverUrl, isNot(contains('edge=curl')));
      expect(r[0].provider, 'Google Books');
      expect(r[1].title, 'Ohne Bild: Ein Untertitel');
      expect(r[1].author, isNull);
      expect(r[1].coverUrl, isNull);
    });

    test('ohne Key kein key-Parameter; keine items → leer', () async {
      late http.Request captured;
      final s = GoogleBooksCoverService(
        apiKeys: InMemoryApiKeyStore(),
        client: MockClient((req) async {
          captured = req;
          return http.Response('{}', 200);
        }),
      );
      expect(await s.search('x'), isEmpty);
      expect(captured.url.queryParameters.containsKey('key'), isFalse);
    });

    test('HTTP-Fehler → CoverSearchException', () async {
      final s = GoogleBooksCoverService(
        apiKeys: InMemoryApiKeyStore(),
        client: MockClient((_) async => http.Response('nope', 429)),
      );
      expect(() => s.search('x'), throwsA(isA<CoverSearchException>()));
    });

    test('leere Anfrage → keine Anfrage', () async {
      var called = false;
      final s = GoogleBooksCoverService(
        apiKeys: InMemoryApiKeyStore(),
        client: MockClient((_) async {
          called = true;
          return http.Response('{}', 200);
        }),
      );
      expect(await s.search('   '), isEmpty);
      expect(called, isFalse);
    });
  });

  group('OpenLibraryCoverService', () {
    test('parst docs und baut Cover-URL', () async {
      final s = OpenLibraryCoverService(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'docs': [
                {
                  'title': 'Buddenbrooks',
                  'author_name': ['Thomas Mann'],
                  'cover_i': 12345,
                },
                {'title': 'Kein Cover'},
                {
                  'author_name': ['Ohne Titel'],
                },
              ],
            }),
            200,
          ),
        ),
      );
      final r = await s.search('Buddenbrooks');
      expect(r.length, 2);
      expect(r[0].coverUrl, 'https://covers.openlibrary.org/b/id/12345-M.jpg');
      expect(r[0].author, 'Thomas Mann');
      expect(r[0].provider, 'Open Library');
      expect(r[1].coverUrl, isNull);
    });

    test('HTTP-Fehler → CoverSearchException', () async {
      final s = OpenLibraryCoverService(
        client: MockClient((_) async => http.Response('', 500)),
      );
      expect(() => s.search('x'), throwsA(isA<CoverSearchException>()));
    });
  });
}
