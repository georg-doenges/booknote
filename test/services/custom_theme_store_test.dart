import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:booknote/models/models.dart';
import 'package:booknote/services/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;
  late CustomThemeStore store;

  Uint8List file({
    String id = 'blue_gold',
    String name = 'Blue Gold',
    int revision = 1,
    String? rawId,
  }) => Uint8List.fromList(
    utf8.encode(
      jsonEncode({
        'format': 'booknote-theme',
        'formatVersion': 1,
        'id': rawId ?? id,
        'name': name,
        'revision': revision,
        'brightness': 'dark',
        'seed': '#C6A052',
        'colors': {'surface': '#0E1A2C', 'primary': '#C6A052'},
      }),
    ),
  );

  setUp(() {
    dir = Directory.systemTemp.createTempSync('booknote_themes_test_');
    store = CustomThemeStore(directory: () async => dir);
  });

  tearDown(() => dir.deleteSync(recursive: true));

  test('startet leer', () async {
    await store.refresh();
    expect(store.themes, isEmpty);
    expect(store.byId('blue_gold'), isNull);
    expect(store.byId(null), isNull);
  });

  test(
    'import speichert die Datei, listet das Theme und meldet Änderung',
    () async {
      var notified = 0;
      store.addListener(() => notified++);

      final theme = await store.import(file());

      expect(theme.id, 'blue_gold');
      expect(File('${dir.path}/blue_gold.json').existsSync(), isTrue);
      expect(store.byId('blue_gold')?.name, 'Blue Gold');
      expect(store.themes, hasLength(1));
      expect(notified, greaterThan(0));
    },
  );

  test('gleiche ID überschreibt (Update auf neue revision)', () async {
    await store.import(file(revision: 1));
    await store.import(file(revision: 2));
    expect(store.themes, hasLength(1));
    expect(store.byId('blue_gold')?.revision, 2);
  });

  test('Umlaute im Namen überstehen import und Neu-Einlesen', () async {
    final theme = await store.import(
      file(id: 'naechtlich', name: 'Nächtliche Bücherei'),
    );
    expect(theme.name, 'Nächtliche Bücherei');

    final fresh = CustomThemeStore(directory: () async => dir);
    await fresh.refresh();
    expect(fresh.byId('naechtlich')?.name, 'Nächtliche Bücherei');
  });

  test('kaputte Datei wirft und hinterlässt nichts', () async {
    await expectLater(
      store.import(Uint8List.fromList(utf8.encode('kein json'))),
      throwsA(isA<CustomThemeException>()),
    );
    await expectLater(
      store.import(Uint8List.fromList([0xFF, 0xFE, 0xFD])),
      throwsA(isA<CustomThemeException>()),
    );
    expect(dir.listSync(), isEmpty);
  });

  test('Pfadtrick in der ID: Datei landet trotzdem im Theme-Ordner', () async {
    final theme = await store.import(file(rawId: '../../evil', name: 'Evil'));
    expect(theme.id, 'evil');
    expect(dir.listSync().map((e) => e.uri.pathSegments.last), ['evil.json']);
  });

  test('delete entfernt Datei und Eintrag', () async {
    await store.import(file());
    await store.delete('blue_gold');
    expect(store.themes, isEmpty);
    expect(dir.listSync(), isEmpty);
    // Löschen eines nicht vorhandenen Themes ist kein Fehler.
    await store.delete('gibt_es_nicht');
  });

  test('refresh überspringt kaputte Dateien und liest den Rest', () async {
    File('${dir.path}/gut.json').writeAsBytesSync(file(id: 'gut', name: 'Gut'));
    File('${dir.path}/kaputt.json').writeAsStringSync('{ nope');
    File('${dir.path}/.initialized')
        .writeAsStringSync('Marker aus alter Version');
    await store.refresh();
    expect(store.themes.map((t) => t.id), ['gut']);
  });
}
