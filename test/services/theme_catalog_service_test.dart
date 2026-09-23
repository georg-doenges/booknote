import 'dart:convert';

import 'package:booknote/services/services.dart';
import 'package:flutter/widgets.dart' show Brightness, Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _goodEntry = <String, Object?>{
  'id': 'blue_gold',
  'name': 'Blue Gold',
  'brightness': 'dark',
  'revision': 2,
  'file': 'blue_gold.json',
  'description': 'Nachtblau mit Gold.',
  'swatch': {'surface': '#0E1A2C', 'primary': '#C6A052'},
  'logo': 'previews/blue_gold.png',
};

String _index(
  List<Object?> themes, {
  int formatVersion = 1,
  String format = 'booknote-theme-index',
}) => jsonEncode({
  'format': format,
  'formatVersion': formatVersion,
  'themes': themes,
});

String _themeFile({String id = 'blue_gold', String name = 'Blue Gold'}) =>
    jsonEncode({
      'format': 'booknote-theme',
      'formatVersion': 1,
      'id': id,
      'name': name,
      'brightness': 'dark',
      'seed': '#C6A052',
      'colors': {'surface': '#0E1A2C', 'primary': '#C6A052'},
    });

ThemeCatalogService _service(
  Future<http.Response> Function(http.Request) handler, {
  List<Uri>? requests,
}) => ThemeCatalogService(
  client: MockClient((r) {
    requests?.add(r.url);
    return handler(r);
  }),
);

Matcher _catalogError(Pattern message) => throwsA(
  isA<ThemeCatalogException>().having(
    (e) => e.message,
    'message',
    contains(message),
  ),
);

void main() {
  group('fetchIndex', () {
    test('liest die Einträge und fragt <Katalog>/index.json an', () async {
      final requests = <Uri>[];
      final entries = await _service(
        (_) async => http.Response(_index([_goodEntry]), 200),
        requests: requests,
      ).fetchIndex();

      expect(
        requests.single,
        ThemeCatalogService.defaultBaseUrl.resolve('index.json'),
      );
      expect(requests.single.host, 'raw.githubusercontent.com');
      final e = entries.single;
      expect(e.id, 'blue_gold');
      expect(e.name, 'Blue Gold');
      expect(e.brightness, Brightness.dark);
      expect(e.revision, 2);
      expect(e.file, 'blue_gold.json');
      expect(e.description, 'Nachtblau mit Gold.');
      expect(e.swatchSurface, const Color(0xFF0E1A2C));
      expect(e.swatchPrimary, const Color(0xFFC6A052));
      expect(e.logoFile, 'previews/blue_gold.png');
    });

    test('Umlaute im UTF-8-Katalog bleiben erhalten', () async {
      final body = _index([
        {..._goodEntry, 'name': 'Nächtliche Bücherei'},
      ]);
      final entries = await _service(
        (_) async => http.Response.bytes(utf8.encode(body), 200),
      ).fetchIndex();
      expect(entries.single.name, 'Nächtliche Bücherei');
    });

    test('kaputte oder unsichere Einträge werden übersprungen', () async {
      final body = _index([
        _goodEntry,
        {..._goodEntry, 'id': 'ohne/slash', 'file': 'a.json'},
        {..._goodEntry, 'id': 'traversal', 'file': '../geheim.json'},
        {..._goodEntry, 'id': 'fremd', 'file': 'https://evil.example/x.json'},
        {..._goodEntry, 'id': 'absolut', 'file': '/etc/x.json'},
        {..._goodEntry, 'id': 'kein_json', 'file': 'x.png'},
        {..._goodEntry, 'id': 'ohne_name', 'name': ' '},
        'kein Objekt',
        42,
      ]);
      final entries = await _service((_) async => http.Response(body, 200))
          .fetchIndex();
      expect(entries.map((e) => e.id), ['blue_gold']);
    });

    test('unsicheres Logo wird ignoriert, der Eintrag bleibt', () async {
      final body = _index([
        {..._goodEntry, 'logo': 'https://evil.example/l.png'},
      ]);
      final e = (await _service(
        (_) async => http.Response(body, 200),
      ).fetchIndex()).single;
      expect(e.logoFile, isNull);
    });

    test('Defaults: revision 1, dunkel, ohne Beschreibung/Vorschau', () async {
      final body = _index([
        {'id': 'x', 'name': 'X', 'file': 'x.json'},
      ]);
      final e = (await _service(
        (_) async => http.Response(body, 200),
      ).fetchIndex()).single;
      expect(e.revision, 1);
      expect(e.brightness, Brightness.dark);
      expect(e.description, isNull);
      expect(e.swatchSurface, isNull);
      expect(e.logoFile, isNull);
    });

    test('leerer Katalog ist kein Fehler', () async {
      final entries = await _service(
        (_) async => http.Response(_index([]), 200),
      ).fetchIndex();
      expect(entries, isEmpty);
    });

    test('HTTP-Status ≠ 200 → verständlicher Fehler', () async {
      await expectLater(
        _service((_) async => http.Response('nope', 404)).fetchIndex(),
        _catalogError('Status 404'),
      );
    });

    test('Netzwerkfehler → „Keine Verbindung"', () async {
      await expectLater(
        _service((_) async => throw http.ClientException('offline'))
            .fetchIndex(),
        _catalogError('Keine Verbindung'),
      );
    });

    test('Timeout → „Keine Verbindung"', () async {
      final service = ThemeCatalogService(
        client: MockClient(
          (_) => Future.delayed(
            const Duration(seconds: 1),
            () => http.Response('', 200),
          ),
        ),
        timeout: const Duration(milliseconds: 20),
      );
      await expectLater(
        service.fetchIndex(),
        _catalogError('Keine Verbindung'),
      );
    });

    test('Antwort ist kein Katalog (z.B. HTML) → Fehler', () async {
      await expectLater(
        _service((_) async => http.Response('<html>Hallo</html>', 200))
            .fetchIndex(),
        _catalogError('Unerwartete Antwort'),
      );
      await expectLater(
        _service(
          (_) async => http.Response(_index([], format: 'was-anderes'), 200),
        ).fetchIndex(),
        _catalogError('Unerwartete Antwort'),
      );
    });

    test('Katalog aus neuerer Version → Update-Hinweis', () async {
      await expectLater(
        _service((_) async => http.Response(_index([], formatVersion: 99), 200))
            .fetchIndex(),
        _catalogError('neuere Booknote-Version'),
      );
    });

    test('zu große Antwort wird abgelehnt', () async {
      final huge = 'x' * (ThemeCatalogService.maxIndexBytes + 1);
      await expectLater(
        _service((_) async => http.Response(huge, 200)).fetchIndex(),
        _catalogError('ungewöhnlich groß'),
      );
    });
  });

  group('fetchTheme', () {
    ThemeCatalogEntry entry({
      String id = 'blue_gold',
      String file = 'blue_gold.json',
    }) => ThemeCatalogEntry.fromJson({..._goodEntry, 'id': id, 'file': file});

    test('liefert die Datei-Bytes und fragt <Katalog>/<file> an', () async {
      final requests = <Uri>[];
      final body = utf8.encode(_themeFile());
      final bytes = await _service(
        (_) async => http.Response.bytes(body, 200),
        requests: requests,
      ).fetchTheme(entry());
      expect(bytes, body);
      expect(requests.single.path, endsWith('/themes/blue_gold.json'));
    });

    test('ID in der Datei ≠ ID im Katalog → Fehler', () async {
      await expectLater(
        _service((_) async => http.Response(_themeFile(id: 'anderes'), 200))
            .fetchTheme(entry()),
        _catalogError('passt nicht zu seiner Datei'),
      );
    });

    test('kaputte Theme-Datei → Fehler mit Grund', () async {
      await expectLater(
        _service((_) async => http.Response('{"format":"x"}', 200))
            .fetchTheme(entry()),
        _catalogError('Booknote-Theme'),
      );
      await expectLater(
        _service((_) async => http.Response('kein json', 200))
            .fetchTheme(entry()),
        _catalogError('kein gültiges JSON'),
      );
    });

    test('kein gültiges UTF-8 → Fehler statt Absturz', () async {
      await expectLater(
        _service((_) async => http.Response.bytes([0xFF, 0xFE, 0xFD], 200))
            .fetchTheme(entry()),
        _catalogError('beschädigt'),
      );
    });

    test('HTTP-Fehler / Netzwerk wie beim Katalog', () async {
      await expectLater(
        _service((_) async => http.Response('', 500)).fetchTheme(entry()),
        _catalogError('Status 500'),
      );
      await expectLater(
        _service((_) async => throw http.ClientException('offline'))
            .fetchTheme(entry()),
        _catalogError('Keine Verbindung'),
      );
    });
  });

  group('urlFor', () {
    test('löst Pfade unterhalb des Katalog-Ordners auf', () {
      final s = ThemeCatalogService(
        baseUrl: Uri.parse('https://example.org/repo/themes/'),
      );
      expect(
        s.urlFor('a.json').toString(),
        'https://example.org/repo/themes/a.json',
      );
      expect(
        s.urlFor('previews/a.png').toString(),
        'https://example.org/repo/themes/previews/a.png',
      );
    });
  });
}
