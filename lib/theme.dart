import 'package:flutter/material.dart';

import 'models/models.dart';

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

  static ThemeData light() => _themeFrom(
    ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light),
  );

  static ThemeData dark() => _themeFrom(
    ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
  );

  /// Baut ein `ThemeData` aus einem importierten [CustomTheme]: Schema aus dem
  /// Seed, dann die im File gesetzten Rollen überschrieben.
  static ThemeData custom(CustomTheme t) {
    var colors = ColorScheme.fromSeed(
      seedColor: t.seed,
      brightness: t.brightness,
    );
    if (t.overrides.isNotEmpty) {
      colors = colors.copyWith(
        primary: t.overrides['primary'],
        onPrimary: t.overrides['onPrimary'],
        primaryContainer: t.overrides['primaryContainer'],
        onPrimaryContainer: t.overrides['onPrimaryContainer'],
        secondary: t.overrides['secondary'],
        onSecondary: t.overrides['onSecondary'],
        secondaryContainer: t.overrides['secondaryContainer'],
        onSecondaryContainer: t.overrides['onSecondaryContainer'],
        tertiary: t.overrides['tertiary'],
        onTertiary: t.overrides['onTertiary'],
        tertiaryContainer: t.overrides['tertiaryContainer'],
        onTertiaryContainer: t.overrides['onTertiaryContainer'],
        error: t.overrides['error'],
        onError: t.overrides['onError'],
        errorContainer: t.overrides['errorContainer'],
        onErrorContainer: t.overrides['onErrorContainer'],
        surface: t.overrides['surface'],
        onSurface: t.overrides['onSurface'],
        onSurfaceVariant: t.overrides['onSurfaceVariant'],
        surfaceContainerLowest: t.overrides['surfaceContainerLowest'],
        surfaceContainerLow: t.overrides['surfaceContainerLow'],
        surfaceContainer: t.overrides['surfaceContainer'],
        surfaceContainerHigh: t.overrides['surfaceContainerHigh'],
        surfaceContainerHighest: t.overrides['surfaceContainerHighest'],
        outline: t.overrides['outline'],
        outlineVariant: t.overrides['outlineVariant'],
        inverseSurface: t.overrides['inverseSurface'],
        onInverseSurface: t.overrides['onInverseSurface'],
        inversePrimary: t.overrides['inversePrimary'],
        shadow: t.overrides['shadow'],
        scrim: t.overrides['scrim'],
      );
    }
    // Hat das Theme ein Hintergrundbild, muss die Scaffold-Fläche durchsichtig
    // sein, damit das Bild hinter den Inhalten sichtbar wird.
    return _themeFrom(
      colors,
      transparentScaffold: t.background?.hasImage ?? false,
    );
  }

  static ThemeData _themeFrom(
    ColorScheme colors, {
    bool transparentScaffold = false,
  }) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      scaffoldBackgroundColor: transparentScaffold
          ? Colors.transparent
          : colors.surface,
      // AppBar ruhig halten: linksbündig, flache Fläche (bleibt undurchsichtig,
      // auch über einem Hintergrundbild), dezente Kante beim Scrollen.
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
