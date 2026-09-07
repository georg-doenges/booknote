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

  test('das mitgelieferte Blue-Gold-Asset ist gültig', () {
    final json = File('assets/themes/blue_gold.json').readAsStringSync();
    final t = CustomTheme.parse(json, builtIn: true);
    expect(t.id, 'blue_gold');
    expect(t.builtIn, isTrue);
    expect(t.overrides['surface'], isNotNull);
    expect(t.overrides['primary'], isNotNull);
  });
}
