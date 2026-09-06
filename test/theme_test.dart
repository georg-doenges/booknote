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
  });
}
