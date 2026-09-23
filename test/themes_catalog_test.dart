import 'dart:convert';
import 'dart:io';

import 'package:booknote/models/models.dart';
import 'package:booknote/services/services.dart';
import 'package:flutter/widgets.dart' show Brightness;
import 'package:flutter_test/flutter_test.dart';

import '../tool/build_theme_index.dart';

/// Prüft den echten Katalog im Repo (`themes/`), den die App per GitHub lädt.
void main() {
  final dir = Directory('themes');

  List<File> themeFiles() =>
      dir
          .listSync()
          .whereType<File>()
          .where(
            (f) =>
                f.path.toLowerCase().endsWith('.json') &&
                !f.path.endsWith('index.json'),
          )
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  test('alle Theme-Dateien im Katalog sind gültige Themes', () {
    final files = themeFiles();
    expect(files, isNotEmpty);
    for (final f in files) {
      final t = CustomTheme.parse(f.readAsStringSync());
      expect(t.name, isNotEmpty, reason: f.path);
      expect(t.overrides['surface'], isNotNull, reason: f.path);
      expect(t.overrides['primary'], isNotNull, reason: f.path);
      expect(f.uri.pathSegments.last, '${t.id}.json', reason: f.path);
    }
  });

  test('Blue Gold und Old Library sind da und wie erwartet', () {
    final gold = CustomTheme.parse(
      File('themes/blue_gold.json').readAsStringSync(),
    );
    expect(gold.id, 'blue_gold');
    expect(gold.name, 'Blue Gold');
    expect(gold.brightness, Brightness.dark);
    expect(gold.logoBytes, isNotNull);

    final library = CustomTheme.parse(
      File('themes/old_library.json').readAsStringSync(),
    );
    expect(library.id, 'old_library');
    expect(library.name, 'Old Library');
    expect(library.brightness, Brightness.light);
    expect(library.logoBytes, isNotNull);
    expect(library.fontFamily, 'Tinos');
  });

  test('index.json ist aktuell (sonst: dart run tool/build_theme_index.dart)', () {
    final build = buildThemeIndex(dir);
    final onDisk = jsonDecode(File('themes/index.json').readAsStringSync());
    expect(
      onDisk,
      build.index,
      reason:
          'themes/index.json ist veraltet – '
          '`dart run tool/build_theme_index.dart` ausführen und mit committen.',
    );
    for (final e in build.previews.entries) {
      final f = File('themes/${e.key}');
      expect(f.existsSync(), isTrue, reason: '${e.key} fehlt');
      expect(f.readAsBytesSync(), e.value, reason: '${e.key} veraltet');
    }
  });

  test('jeder Katalogeintrag ist für die App lesbar und vollständig', () {
    final index = jsonDecode(
      File('themes/index.json').readAsStringSync(),
    ) as Map<String, Object?>;
    final themes = index['themes'] as List;
    expect(themes, isNotEmpty);
    for (final raw in themes) {
      final e = ThemeCatalogEntry.fromJson(raw as Map<String, Object?>);
      expect(File('themes/${e.file}').existsSync(), isTrue, reason: e.file);
      final logo = e.logoFile;
      if (logo != null) {
        expect(File('themes/$logo').existsSync(), isTrue, reason: logo);
      }
    }
  });

  test('Schriften der Themes sind im APK deklariert (pubspec.yaml)', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final f in themeFiles()) {
      final font = CustomTheme.parse(f.readAsStringSync()).fontFamily;
      if (font == null) continue;
      expect(
        pubspec,
        contains('family: $font'),
        reason:
            '${f.path} nennt die Schrift "$font", die nicht im APK steckt – '
            'sie würde still auf die Systemschrift zurückfallen.',
      );
    }
  });
}
