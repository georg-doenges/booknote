import 'dart:convert';
import 'dart:io';

import 'package:booknote/models/models.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String file({
    String name = 'Blue Gold',
    String brightness = 'dark',
    Map<String, Object?> extra = const {},
  }) => jsonEncode({
    'format': 'booknote-theme',
    'formatVersion': 1,
    'name': name,
    'brightness': brightness,
    'seed': '#C6A052',
    'colors': {'primary': '#C6A052', 'surface': '#0E1A2C'},
    ...extra,
  });

  test('parst Pflichtfelder + Overrides', () {
    final t = CustomTheme.parse(file());
    expect(t.name, 'Blue Gold');
    expect(t.id, 'blue_gold');
    expect(t.brightness, Brightness.dark);
    expect(t.seed, const Color(0xFFC6A052));
    expect(t.overrides['surface'], const Color(0xFF0E1A2C));
    expect(t.background, isNull);
  });

  test('unbekannte Farb-Rollen werden ignoriert', () {
    final t = CustomTheme.parse(
      file(
        extra: {
          'colors': {'primary': '#FFFFFF', 'quatsch': '#000000'},
        },
      ),
    );
    expect(t.overrides.containsKey('quatsch'), isFalse);
    expect(t.overrides['primary'], const Color(0xFFFFFFFF));
  });

  test('background mit eingebettetem Bild', () {
    final bytes = utf8.encode('PNGDATA');
    final t = CustomTheme.parse(
      file(
        extra: {
          'background': {
            'image': 'data:image/png;base64,${base64Encode(bytes)}',
            'fit': 'tile',
            'dim': 0.2,
          },
        },
      ),
    );
    expect(t.background!.hasImage, isTrue);
    expect(t.background!.tile, isTrue);
    expect(t.background!.dim, 0.2);
    expect(utf8.decode(t.background!.imageBytes!), 'PNGDATA');
  });

  test('logo wird aus data-URI dekodiert, fehlt sonst', () {
    expect(CustomTheme.parse(file()).logoBytes, isNull);

    final bytes = utf8.encode('LOGODATA');
    final t = CustomTheme.parse(
      file(extra: {'logo': 'data:image/png;base64,${base64Encode(bytes)}'}),
    );
    expect(utf8.decode(t.logoBytes!), 'LOGODATA');
  });

  test('font-Feld wird übernommen, fehlt sonst', () {
    expect(CustomTheme.parse(file()).fontFamily, isNull);
    expect(
      CustomTheme.parse(file(extra: {'font': 'Tinos'})).fontFamily,
      'Tinos',
    );
    expect(
      CustomTheme.parse(file(extra: {'font': ''})).fontFamily,
      isNull,
      reason: 'leerer Name zählt wie kein Feld',
    );
  });

  test('falsches Format / kaputte Farbe wirft', () {
    expect(
      () => CustomTheme.parse('{"format":"x"}'),
      throwsA(isA<CustomThemeException>()),
    );
    expect(
      () => CustomTheme.parse(
        file(
          extra: {
            'colors': {'primary': 'nope'},
          },
        ),
      ),
      throwsA(isA<CustomThemeException>()),
    );
  });

  test('alle mitgelieferten Theme-Assets sind gültig', () {
    final dir = Directory('assets/themes');
    final files =
        dir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.toLowerCase().endsWith('.json'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    expect(files, isNotEmpty);
    for (final f in files) {
      final t = CustomTheme.parse(f.readAsStringSync());
      expect(t.name, isNotEmpty, reason: f.path);
      expect(t.overrides['surface'], isNotNull, reason: f.path);
      expect(t.overrides['primary'], isNotNull, reason: f.path);
    }
  });

  test('das mitgelieferte Blue-Gold-Asset ist gültig', () {
    final json = File('assets/themes/blue_gold.json').readAsStringSync();
    final t = CustomTheme.parse(json);
    expect(t.id, 'blue_gold');
    expect(t.name, 'Blue Gold');
    expect(t.brightness, Brightness.dark);
    expect(t.logoBytes, isNotNull);
  });

  test('das mitgelieferte Old-Library-Asset ist gültig', () {
    final json = File('assets/themes/old_library.json').readAsStringSync();
    final t = CustomTheme.parse(json);
    expect(t.id, 'old_library');
    expect(t.name, 'Old Library');
    expect(t.brightness, Brightness.light);
    expect(t.logoBytes, isNotNull);
    expect(t.fontFamily, 'Tinos');
  });
}
