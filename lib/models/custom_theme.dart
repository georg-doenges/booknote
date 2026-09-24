import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';

/// Ein importierbares Farbschema (siehe THEMES.md).
///
/// Format: eine portable JSON-Datei mit `name`, `brightness`, `seed`,
/// optionalen Farb-Overrides einzelner Material-Rollen und einem optionalen
/// `background` (Bild als data-URI eingebettet). Ein Custom-Theme ist **ein
/// fester Look** – es folgt nicht Hell/Dunkel des Systems.
class CustomTheme {
  const CustomTheme({
    required this.id,
    required this.name,
    required this.brightness,
    required this.seed,
    this.overrides = const {},
    this.background,
    this.logoBytes,
    this.fontFamily,
    this.revision = 1,
  });

  final String id;
  final String name;
  final Brightness brightness;

  /// Basis-Farbton; daraus wird das Schema erzeugt, dann [overrides] angewandt.
  final Color seed;

  /// Rolle (z.B. `primary`, `surface`, `onSurface`) → Farbe. Nur diese werden
  /// überschrieben.
  final Map<String, Color> overrides;

  final ThemeBackground? background;

  /// Optionales, zum Schema passend eingefärbtes App-Logo (aus einem
  /// data-URI dekodiert), z.B. für die Vorschau in den Einstellungen. `null` =
  /// die abstrakte Farbkachel wird gezeigt. Ändert nichts am App-Icon selbst –
  /// Android kann das nicht pro Theme umschalten.
  final Uint8List? logoBytes;

  /// Optionale Schriftfamilie (z.B. `"Tinos"`). Anders als [logoBytes]/
  /// [background] wird keine Schrift-Datei eingebettet – es zählt nur ein
  /// Name, den die App bereits mitbringt (siehe `pubspec.yaml` → `fonts:`).
  /// Unbekannter Name → Flutter fällt lautlos auf die Systemschrift zurück.
  final String? fontFamily;

  /// Stand des Inhalts (ab 1), vom Autor bei jeder Änderung hochgezählt. Der
  /// Theme-Katalog vergleicht ihn mit dem Katalogeintrag und bietet dann
  /// „Aktualisieren" an. Nicht zu verwechseln mit [formatVersion] (Dateiformat).
  final int revision;

  static const formatId = 'booknote-theme';
  static const formatVersion = 1;

  /// Rollen, die ein Theme-File setzen darf.
  static const roleNames = {
    'primary',
    'onPrimary',
    'primaryContainer',
    'onPrimaryContainer',
    'secondary',
    'onSecondary',
    'secondaryContainer',
    'onSecondaryContainer',
    'tertiary',
    'onTertiary',
    'tertiaryContainer',
    'onTertiaryContainer',
    'error',
    'onError',
    'errorContainer',
    'onErrorContainer',
    'surface',
    'onSurface',
    'onSurfaceVariant',
    'surfaceContainerLowest',
    'surfaceContainerLow',
    'surfaceContainer',
    'surfaceContainerHigh',
    'surfaceContainerHighest',
    'outline',
    'outlineVariant',
    'inverseSurface',
    'onInverseSurface',
    'inversePrimary',
    'shadow',
    'scrim',
  };

  // ---- JSON ----

  static CustomTheme parse(String text) {
    final Object? decoded;
    try {
      decoded = jsonDecode(text);
    } catch (_) {
      throw const CustomThemeException(CustomThemeErrorKind.notJson);
    }
    if (decoded is! Map<String, Object?>) {
      throw const CustomThemeException(
        CustomThemeErrorKind.unexpectedStructure,
      );
    }
    if (decoded['format'] != formatId) {
      throw const CustomThemeException(CustomThemeErrorKind.notATheme);
    }
    final version = decoded['formatVersion'];
    if (version is! int || version > formatVersion) {
      throw const CustomThemeException(CustomThemeErrorKind.newerVersion);
    }
    try {
      final name = (decoded['name'] as String?)?.trim();
      if (name == null || name.isEmpty) {
        throw const CustomThemeException(CustomThemeErrorKind.missingName);
      }
      final rawColors =
          (decoded['colors'] as Map?)?.cast<String, Object?>() ?? const {};
      final overrides = <String, Color>{
        for (final e in rawColors.entries)
          if (roleNames.contains(e.key)) e.key: _color(e.value as String),
      };
      return CustomTheme(
        id: _idFor(decoded['id'], name),
        name: name,
        brightness: decoded['brightness'] == 'light'
            ? Brightness.light
            : Brightness.dark,
        seed: _color(decoded['seed'] as String? ?? '#6D4C41'),
        overrides: overrides,
        background: decoded['background'] is Map
            ? ThemeBackground.fromJson(
                (decoded['background'] as Map).cast<String, Object?>(),
              )
            : null,
        logoBytes: decodeDataUri(decoded['logo']),
        fontFamily: (decoded['font'] as String?)?.trim().isNotEmpty == true
            ? (decoded['font'] as String).trim()
            : null,
        revision: switch (decoded['revision']) {
          final int r when r >= 1 => r,
          _ => 1,
        },
      );
    } on CustomThemeException {
      rethrow;
    } catch (e) {
      throw CustomThemeException(CustomThemeErrorKind.corrupted, '$e');
    }
  }

  static Color _color(String hex) {
    var s = hex.trim().replaceFirst('#', '');
    if (s.length == 6) s = 'FF$s';
    final v = int.tryParse(s, radix: 16);
    if (v == null || s.length != 8) {
      throw CustomThemeException(CustomThemeErrorKind.invalidColor, hex);
    }
    return Color(v);
  }

  /// Die ID wird als Dateiname benutzt – nur schlichte Zeichen zulassen, sonst
  /// aus dem Namen ableiten (verhindert Pfadtricks wie `../x` in fremden Dateien).
  static String _idFor(Object? rawId, String name) {
    final id = rawId is String ? rawId.trim() : '';
    if (RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(id)) return id;
    final slug = _slug(name);
    return slug.isEmpty ? 'theme' : slug;
  }

  static String _slug(String name) => name
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
}

/// Dekodiert ein Bild aus einem `data:image/...;base64,...`-URI (oder reinem
/// Base64). `null`/leer/kein String → `null`.
Uint8List? decodeDataUri(Object? value) {
  if (value is! String || value.isEmpty) return null;
  final comma = value.indexOf(',');
  final b64 = comma >= 0 ? value.substring(comma + 1) : value;
  return base64Decode(b64.trim());
}

/// Hintergrund eines [CustomTheme]. Liegt hinter den großen Flächen der App,
/// AppBar und System-Leisten bleiben davon unberührt.
class ThemeBackground {
  const ThemeBackground({
    this.imageBytes,
    this.tile = false,
    this.opacity = 1,
    this.dim = 0,
  });

  /// Bilddaten (aus einem data-URI dekodiert). `null` = kein Bild.
  final Uint8List? imageBytes;

  /// `true` = kacheln, `false` = formatfüllend (cover).
  final bool tile;

  /// Deckkraft des Bildes (0..1).
  final double opacity;

  /// Zusätzlicher dunkler Schleier über dem Bild für besseren Kontrast (0..1).
  final double dim;

  bool get hasImage => imageBytes != null && imageBytes!.isNotEmpty;

  static ThemeBackground fromJson(Map<String, Object?> j) {
    return ThemeBackground(
      imageBytes: decodeDataUri(j['image']),
      tile: j['fit'] == 'tile' || j['tile'] == true,
      opacity: ((j['opacity'] as num?)?.toDouble() ?? 1).clamp(0.0, 1.0),
      dim: ((j['dim'] as num?)?.toDouble() ?? 0).clamp(0.0, 1.0),
    );
  }
}

/// Warum eine Theme-Datei nicht gelesen werden konnte. Die UI formuliert
/// daraus die Meldung in der Sprache der App (`customThemeErrorText`).
enum CustomThemeErrorKind {
  notJson,
  unexpectedStructure,
  notATheme,
  newerVersion,
  missingName,
  invalidColor,
  corrupted,
}

class CustomThemeException implements Exception {
  const CustomThemeException(this.kind, [this.detail]);

  final CustomThemeErrorKind kind;

  /// Der ungültige Farbwert bzw. die technische Ursache (nur zur Anzeige).
  final String? detail;

  @override
  String toString() =>
      'CustomThemeException(${kind.name}${detail == null ? '' : ': $detail'})';
}
