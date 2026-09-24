import 'package:booknote/models/models.dart';
import 'package:booknote/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BooknoteTheme', () {
    test('light theme: Material 3, helles Schema aus dem Seed', () {
      final theme = BooknoteTheme.light();
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.brightness, Brightness.light);
    });

    test('dark theme: Material 3, dunkles Schema aus demselben Seed', () {
      final theme = BooknoteTheme.dark();
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.brightness, Brightness.dark);
    });

    test('Eingabefelder haben appweit einen Rahmen', () {
      expect(
        BooknoteTheme.light().inputDecorationTheme.border,
        isA<OutlineInputBorder>(),
      );
    });

    test('MaterialApp nimmt beide Themes und folgt dem System', () async {
      final theme = BooknoteTheme.light();
      final dark = BooknoteTheme.dark();
      // Baut ohne Fehler mit beiden Themes verdrahtet.
      final app = MaterialApp(
        theme: theme,
        darkTheme: dark,
        themeMode: ThemeMode.system,
        home: const SizedBox.shrink(),
      );
      expect(app.themeMode, ThemeMode.system);
      expect(app.darkTheme, same(dark));
    });

    test('Custom-Theme ohne font-Feld nutzt die Default-Schrift', () {
      const t = CustomTheme(
        id: 'x',
        name: 'X',
        brightness: Brightness.light,
        seed: Color(0xFF6D4C41),
      );
      expect(
        BooknoteTheme.custom(t).textTheme.bodyMedium?.fontFamily,
        BooknoteTheme.light().textTheme.bodyMedium?.fontFamily,
      );
    });

    test('Custom-Theme mit font-Feld reicht die Schriftfamilie durch', () {
      const t = CustomTheme(
        id: 'old_library',
        name: 'Old Library',
        brightness: Brightness.light,
        seed: Color(0xFF9C4B3A),
        fontFamily: 'Tinos',
      );
      expect(BooknoteTheme.custom(t).textTheme.bodyMedium?.fontFamily, 'Tinos');
    });
  });
}
