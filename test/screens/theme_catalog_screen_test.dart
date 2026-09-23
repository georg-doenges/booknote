import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:booknote/screens/theme_catalog_screen.dart';
import 'package:booknote/services/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

String _themeJson(String id, String name, {int revision = 1}) => jsonEncode({
  'format': 'booknote-theme',
  'formatVersion': 1,
  'id': id,
  'name': name,
  'revision': revision,
  'brightness': 'dark',
  'seed': '#C6A052',
  'colors': {'surface': '#0E1A2C', 'primary': '#C6A052'},
});

Map<String, Object?> _entry(String id, String name, int revision) => {
  'id': id,
  'name': name,
  'brightness': 'dark',
  'revision': revision,
  'file': '$id.json',
  'description': 'Beschreibung von $name.',
};

void main() {
  late Directory dir;
  late CustomThemeStore store;
  late AppSettings settings;

  /// Steuerbare Gegenstelle des Katalogs.
  var indexStatus = 200;
  var themeStatus = 200;

  final catalog = [
    _entry('aurora', 'Aurora', 1),
    _entry('blue_gold', 'Blue Gold', 2),
    _entry('old_library', 'Old Library', 2),
  ];

  http.Response handle(http.Request r) {
    final file = r.url.pathSegments.last;
    if (file == 'index.json') {
      if (indexStatus != 200) return http.Response('', indexStatus);
      return http.Response(
        jsonEncode({
          'format': 'booknote-theme-index',
          'formatVersion': 1,
          'themes': catalog,
        }),
        200,
      );
    }
    if (themeStatus != 200) return http.Response('', themeStatus);
    final id = file.replaceAll('.json', '');
    final e = catalog.firstWhere((c) => c['id'] == id);
    return http.Response.bytes(
      utf8.encode(
        _themeJson(id, e['name']! as String, revision: e['revision']! as int),
      ),
      200,
    );
  }

  setUp(() async {
    indexStatus = 200;
    themeStatus = 200;
    dir = Directory.systemTemp.createTempSync('booknote_catalog_test_');
    store = CustomThemeStore(directory: () async => dir);
    settings = await AppSettings.load(InMemoryAppSettingsStore());
  });

  tearDown(() {
    // Unter Windows hält der Datei-Zugriff aus dem Test kurz nach; der
    // Temp-Ordner ist nicht testrelevant, das Aufräumen darf still scheitern.
    try {
      dir.deleteSync(recursive: true);
    } on FileSystemException {
      // ignorieren
    }
  });

  /// Echte Datei-Zugriffe laufen im Widget-Test außerhalb der Fake-Zeit.
  ///
  /// Jeder Schritt der Kette (anlegen, schreiben, neu einlesen) braucht eine
  /// Runde echte Zeit plus einen Pump; es wird gewartet, bis der Lade-Kreisel
  /// des Eintrags wieder weg ist.
  Future<void> settleIo(WidgetTester tester) async {
    for (var i = 0; i < 200; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump(const Duration(milliseconds: 20));
      if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
    }
    await tester.pumpAndSettle();
  }

  Future<void> preinstall(
    WidgetTester tester,
    String id,
    String name,
    int rev,
  ) async {
    await tester.runAsync(
      () => store.import(
        Uint8List.fromList(utf8.encode(_themeJson(id, name, revision: rev))),
      ),
    );
  }

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ThemeCatalogScreen(
          service: ThemeCatalogService(
            client: MockClient((r) async => handle(r)),
          ),
          store: store,
          settings: settings,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('zeigt je Eintrag: Installieren / Aktualisieren / Installiert', (
    tester,
  ) async {
    await preinstall(tester, 'blue_gold', 'Blue Gold', 1); // Katalog: 2
    await preinstall(tester, 'old_library', 'Old Library', 2); // Katalog: 2
    await open(tester);

    expect(find.text('Aurora'), findsOneWidget);
    expect(find.text('Blue Gold'), findsOneWidget);
    expect(find.text('Old Library'), findsOneWidget);
    expect(find.textContaining('Beschreibung von Aurora.'), findsOneWidget);
    expect(find.text('Installieren'), findsOneWidget);
    expect(find.text('Aktualisieren'), findsOneWidget);
    expect(find.text('Installiert'), findsOneWidget);
  });

  testWidgets('Installieren lädt, speichert und schaltet das Schema ein', (
    tester,
  ) async {
    await open(tester);
    expect(settings.activeCustomThemeId, isNull);

    await tester.tap(find.text('Installieren').first);
    await settleIo(tester);

    expect(store.byId('aurora')?.name, 'Aurora');
    expect(settings.activeCustomThemeId, 'aurora');
    expect(
      find.text('„Aurora" installiert und eingeschaltet.'),
      findsOneWidget,
    );
    // Aurora zeigt jetzt „Installiert", die zwei anderen bleiben offen.
    expect(find.text('Installiert'), findsOneWidget);
    expect(find.text('Installieren'), findsNWidgets(2));
  });

  testWidgets(
    'Aktualisieren ersetzt die Datei, ohne das aktive Schema zu wechseln',
    (tester) async {
      await preinstall(tester, 'blue_gold', 'Blue Gold', 1);
      await preinstall(tester, 'old_library', 'Old Library', 2);
      await settings.setActiveCustomTheme('old_library');
      await open(tester);

      await tester.tap(find.text('Aktualisieren'));
      await settleIo(tester);

      expect(store.byId('blue_gold')?.revision, 2);
      expect(settings.activeCustomThemeId, 'old_library');
      expect(find.text('„Blue Gold" aktualisiert.'), findsOneWidget);
      expect(find.text('Aktualisieren'), findsNothing);
    },
  );

  testWidgets('Katalog nicht erreichbar: Fehlertext, dann „Erneut versuchen"', (
    tester,
  ) async {
    indexStatus = 500;
    await open(tester);
    expect(find.text('Der Katalog antwortete mit Status 500.'), findsOneWidget);
    expect(find.text('Installieren'), findsNothing);

    indexStatus = 200;
    await tester.tap(find.text('Erneut versuchen'));
    await tester.pumpAndSettle();
    expect(find.text('Aurora'), findsOneWidget);
    expect(find.text('Erneut versuchen'), findsNothing);
  });

  testWidgets('Fehler beim Laden eines Themes: Meldung, nichts installiert', (
    tester,
  ) async {
    await open(tester);
    themeStatus = 404;

    await tester.tap(find.text('Installieren').first);
    await settleIo(tester);

    expect(find.text('Der Katalog antwortete mit Status 404.'), findsOneWidget);
    expect(store.themes, isEmpty);
    expect(settings.activeCustomThemeId, isNull);
    // Knopf ist wieder frei.
    expect(find.text('Installieren'), findsNWidgets(3));
  });
}
