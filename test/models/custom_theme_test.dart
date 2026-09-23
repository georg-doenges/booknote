import 'dart:convert';

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

  test('revision: Zahl ab 1, sonst 1', () {
    expect(CustomTheme.parse(file()).revision, 1);
    expect(CustomTheme.parse(file(extra: {'revision': 3})).revision, 3);
    expect(CustomTheme.parse(file(extra: {'revision': 0})).revision, 1);
    expect(CustomTheme.parse(file(extra: {'revision': 'x'})).revision, 1);
  });

  test('ID wird als Dateiname benutzt: nur schlichte Zeichen', () {
    expect(
      CustomTheme.parse(file(extra: {'id': 'old_library'})).id,
      'old_library',
    );
    // Pfadtricks aus fremden Dateien werden durch den Namens-Slug ersetzt.
    expect(
      CustomTheme.parse(file(extra: {'id': '../../evil'})).id,
      'blue_gold',
    );
    expect(CustomTheme.parse(file(extra: {'id': 'a/b'})).id, 'blue_gold');
    expect(CustomTheme.parse(file(extra: {'id': '  '})).id, 'blue_gold');
    expect(CustomTheme.parse(file(name: '###')).id, 'theme');
  });
}
