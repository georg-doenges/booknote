import 'dart:convert';
import 'dart:io';

import 'package:booknote/models/models.dart';
import 'package:booknote/services/services.dart';
import 'package:flutter/widgets.dart' show Brightness, Color, HSLColor;
import 'package:flutter_test/flutter_test.dart';

import '../tool/build_theme_index.dart';

/// WCAG-Kontrastverhältnis zweier Farben (1 … 21).
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (la > lb ? la + 0.05 : lb + 0.05) / (la > lb ? lb + 0.05 : la + 0.05);
}

/// Prüft den echten Katalog im Repo (`themes/`), den die App per GitHub lädt.
void main() {
  final dir = Directory('themes');

  CustomTheme load(String id) =>
      CustomTheme.parse(File('themes/$id.json').readAsStringSync());

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

  test('Clean Slate, Sundown, Book Cloth und Graphite sind da', () {
    final slate = load('clean_slate');
    expect(slate.name, 'Clean Slate');
    expect(slate.brightness, Brightness.light);
    expect(
      slate.overrides['surface'],
      const Color(0xFFFFFFFF),
      reason: 'Clean Slate steht auf reinem Weiß',
    );
    expect(slate.background, isNull);

    expect(load('sundown').brightness, Brightness.dark);
    expect(load('graphite').brightness, Brightness.dark);

    final cloth = load('book_cloth');
    expect(cloth.brightness, Brightness.dark);
    expect(cloth.background?.hasImage, isTrue, reason: 'Leinen-Kachel');
    expect(cloth.background?.tile, isTrue);
    expect(cloth.background?.opacity, 1);
    expect(cloth.background?.dim, 0);

    for (final id in ['clean_slate', 'sundown', 'book_cloth', 'graphite']) {
      expect(
        load(id).logoBytes,
        isNotNull,
        reason: '$id: Logo für die Vorschau',
      );
      expect(load(id).fontFamily, isNull, reason: '$id: nur Systemschrift');
    }
  });

  test('Blue Gold: mattes Altgold, nicht grelles Gelb', () {
    final gold = load('blue_gold');
    expect(gold.revision, greaterThanOrEqualTo(3));
    expect(gold.fontFamily, 'Tinos', reason: 'Serifenschrift wie Old Library');
    final primary = gold.overrides['primary']!;
    final hsl = HSLColor.fromColor(primary);
    // Vorher #C6A052: Sättigung 50 %. Matter heißt: deutlich weniger Sättigung,
    // aber weiter ein warmer Goldton (kein graues Khaki).
    expect(hsl.saturation, inInclusiveRange(0.33, 0.46));
    expect(hsl.hue, inInclusiveRange(34, 44));
  });

  test('Textfarben sind auf allen Flächen jedes Katalog-Themes gut lesbar', () {
    // (Vordergrund, Hintergrund, Mindestkontrast)
    const pairs = [
      ('onSurface', 'surface', 7.0),
      ('onSurface', 'surfaceContainerLow', 4.5),
      ('onSurface', 'surfaceContainerHighest', 4.5),
      ('onSurfaceVariant', 'surface', 4.5),
      ('onSurfaceVariant', 'surfaceContainerLow', 4.5),
      ('onPrimary', 'primary', 4.5),
      ('primary', 'surface', 4.5),
      ('primary', 'surfaceContainerLow', 4.5),
      ('onPrimaryContainer', 'primaryContainer', 4.5),
      ('onSecondaryContainer', 'secondaryContainer', 4.5),
      ('onTertiaryContainer', 'tertiaryContainer', 4.5),
      ('onError', 'error', 4.5),
      ('error', 'surface', 4.5),
      ('onErrorContainer', 'errorContainer', 4.5),
      ('onInverseSurface', 'inverseSurface', 4.5),
    ];
    for (final f in themeFiles()) {
      final t = CustomTheme.parse(f.readAsStringSync());
      for (final (fg, bg, minimum) in pairs) {
        final a = t.overrides[fg];
        final b = t.overrides[bg];
        expect(a, isNotNull, reason: '${t.id}: $fg fehlt');
        expect(b, isNotNull, reason: '${t.id}: $bg fehlt');
        expect(
          _contrast(a!, b!),
          greaterThanOrEqualTo(minimum),
          reason: '${t.id}: $fg auf $bg',
        );
      }
    }
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

  test('Katalog bleibt für ältere Apps lesbar: „description" ist ein Text', () {
    // Bis 0.1.0+26 las die App `description` nur als einfachen Text; ein
    // Sprach-Objekt dort würde den Katalog auf diesen Geräten unbrauchbar
    // machen. Die Sprachen stehen deshalb zusätzlich unter `descriptions`.
    final index = jsonDecode(
      File('themes/index.json').readAsStringSync(),
    ) as Map<String, Object?>;
    for (final raw in index['themes'] as List) {
      final e = raw as Map<String, Object?>;
      expect(e['description'], isA<String>(), reason: '${e['id']}');
      final byLanguage = e['descriptions'] as Map<String, Object?>?;
      expect(byLanguage?.keys, containsAll(['de', 'en', 'fr']));
      expect(e['description'], byLanguage!['de']);
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
