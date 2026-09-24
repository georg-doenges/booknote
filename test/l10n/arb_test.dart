import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Die drei Übersetzungsdateien müssen zueinander passen: gleiche Schlüssel,
/// gleiche Platzhalter, keine Stolperfallen der ICU-Syntax.
void main() {
  Map<String, Object?> load(String lang) =>
      jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync())
          as Map<String, Object?>;

  final de = load('de');
  final en = load('en');
  final fr = load('fr');

  /// Nur die Übersetzungen (ohne `@@locale` und `@key`-Metadaten).
  Map<String, String> texts(Map<String, Object?> arb) => {
    for (final e in arb.entries)
      if (!e.key.startsWith('@')) e.key: e.value! as String,
  };

  final tde = texts(de);
  final ten = texts(en);
  final tfr = texts(fr);

  Set<String> placeholdersIn(String message) => {
    for (final m in RegExp(r'\{(\w+)(?:,|\})').allMatches(message)) m.group(1)!,
  };

  test('Locale-Kennung stimmt zum Dateinamen', () {
    expect(de['@@locale'], 'de');
    expect(en['@@locale'], 'en');
    expect(fr['@@locale'], 'fr');
  });

  test('alle drei Dateien haben genau dieselben Schlüssel', () {
    expect(ten.keys.toSet(), tde.keys.toSet(), reason: 'English vs. Deutsch');
    expect(tfr.keys.toSet(), tde.keys.toSet(), reason: 'Français vs. Deutsch');
    expect(tde, isNotEmpty);
  });

  test('kein Text ist leer', () {
    for (final t in [tde, ten, tfr]) {
      for (final e in t.entries) {
        expect(e.value.trim(), isNotEmpty, reason: e.key);
      }
    }
  });

  test('jede Übersetzung nutzt genau die Platzhalter der Vorlage', () {
    for (final key in tde.keys) {
      final meta = de['@$key'] as Map<String, Object?>?;
      final expected = {
        ...?((meta?['placeholders'] as Map<String, Object?>?)?.keys),
      };
      for (final entry in {'de': tde, 'en': ten, 'fr': tfr}.entries) {
        expect(
          placeholdersIn(entry.value[key]!),
          expected,
          reason: '$key (${entry.key}): Platzhalter',
        );
      }
    }
  });

  test('keine Vorlagen-Metadaten ohne zugehörigen Text', () {
    for (final key in de.keys.where(
      (k) => k.startsWith('@') && k != '@@locale',
    )) {
      expect(tde.containsKey(key.substring(1)), isTrue, reason: key);
    }
  });

  test('kein ASCII-Apostroph (in ICU ein Escape-Zeichen) und kein doppeltes Leerzeichen', () {
    for (final entry in {'de': tde, 'en': ten, 'fr': tfr}.entries) {
      for (final e in entry.value.entries) {
        expect(
          e.value,
          isNot(contains("'")),
          reason: '${e.key} (${entry.key})',
        );
        // zwei Leerzeichen kommen nur in den Zählzeilen des Abgleichs vor
        if (!e.key.startsWith('syncCountLine')) {
          expect(
            e.value,
            isNot(contains('  ')),
            reason: '${e.key} (${entry.key})',
          );
        }
      }
    }
  });

  test(
    'Französisch: geschütztes Leerzeichen vor : ; ? ! und in Guillemets',
    () {
      for (final e in tfr.entries) {
        expect(e.value, isNot(matches(RegExp(r'[^ ] [:;?!]'))), reason: e.key);
        expect(e.value, isNot(contains('« ')), reason: e.key);
        expect(e.value, isNot(contains(' »')), reason: e.key);
      }
    },
  );

  test('Sprachen unterscheiden sich wirklich (nichts blieb unübersetzt)', () {
    // Erlaubte Gleichheit: Eigennamen, Fachwörter, gleiche Schreibweise.
    const allowSameAsGerman = {
      'settingsOpenAiLabel',
      'settingsGoogleLabel',
      'noteEditPosition',
      'noteEditPage',
      'settingsVibration',
      'syncNotes',
      'exportLabelNotes',
      'commonCancel', // Fehlalarm-Schutz
      'exportFormatText',
      'noteEditText',
      'settingsThemeSystem',
      'searchFieldLabel',
    };
    var identicalToGerman = 0;
    for (final key in tde.keys) {
      if (allowSameAsGerman.contains(key)) continue;
      if (ten[key] == tde[key]) identicalToGerman++;
    }
    expect(identicalToGerman, lessThan(3), reason: 'English ≈ Deutsch?');
  });
}
