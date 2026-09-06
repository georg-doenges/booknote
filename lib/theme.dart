import 'package:flutter/material.dart';

/// Zentrales Erscheinungsbild von Booknote.
///
/// Design-Grundsatz (PROJECT.md, HANDOFF.md): klar, ruhig, lesbar, Material 3,
/// ein Seed-Farbton, funktionierender Dark Mode. Der Aufnahme-Button ist das
/// wichtigste Element. Anpassungen am Look gehören hierher – nicht als
/// Einzelstyling in die einzelnen Screens.
abstract final class BooknoteTheme {
  /// Warmes Braun (Papier, Einband) als einziger Seed für hell und dunkel.
  static const Color seed = Color(0xFF6D4C41);

  // Einheitliche Abstände. In Screens diese Konstanten statt roher Zahlen
  // verwenden, damit die App überall gleich atmet.
  static const double gap4 = 4;
  static const double gap8 = 8;
  static const double gap12 = 12;
  static const double gap16 = 16;
  static const double gap24 = 24;

  /// Standard-Innenabstand für scrollbare Screen-Inhalte.
  static const EdgeInsets screenPadding = EdgeInsets.all(gap16);

  /// Zusätzlicher unterer Scroll-Abstand, damit ein FAB den letzten
  /// Listeneintrag nicht verdeckt. Zur System-Navigationsleiste kommt
  /// `MediaQuery.paddingOf(context).bottom` obendrauf.
  static const double fabSafeBottom = 88;

  /// Kantenradius für Karten und Cover-Kacheln.
  static const double cardRadius = 12;

  static ThemeData light() => _themeFor(Brightness.light);

  static ThemeData dark() => _themeFor(Brightness.dark);

  static ThemeData _themeFor(Brightness brightness) {
    final colors = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      scaffoldBackgroundColor: colors.surface,
      // AppBar ruhig halten: linksbündig, flache Fläche, dezente Kante beim
      // Scrollen.
      appBarTheme: AppBarThemeData(
        centerTitle: false,
        backgroundColor: colors.surface,
        scrolledUnderElevation: 2,
      ),
      // Flache, dezent gefüllte Karten statt schwebender Schatten.
      cardTheme: CardThemeData(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        color: colors.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
      ),
      // Alle Eingabefelder einheitlich mit Rahmen.
      inputDecorationTheme: const InputDecorationThemeData(
        border: OutlineInputBorder(),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: const DividerThemeData(space: 1, thickness: 1),
    );
  }
}
