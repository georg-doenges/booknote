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
      throw const CustomThemeException('Die Datei ist kein gültiges JSON.');
    }
    if (decoded is! Map<String, Object?>) {
      throw const CustomThemeException('Unerwarteter Dateiaufbau.');
    }
    if (decoded['format'] != formatId) {
      throw const CustomThemeException('Das ist keine Booknote-Theme-Datei.');
    }
    final version = decoded['formatVersion'];
    if (version is! int || version > formatVersion) {
      throw const CustomThemeException(
        'Die Datei stammt aus einer neueren App-Version.',
      );
    }
    try {
      final name = (decoded['name'] as String?)?.trim();
      if (name == null || name.isEmpty) {
        throw const CustomThemeException('Dem Theme fehlt ein Name.');
      }
      final rawColors =
          (decoded['colors'] as Map?)?.cast<String, Object?>() ?? const {};
      final overrides = <String, Color>{
        for (final e in rawColors.entries)
          if (roleNames.contains(e.key)) e.key: _color(e.value as String),
      };
      return CustomTheme(
        id: (decoded['id'] as String?)?.trim().isNotEmpty == true
            ? decoded['id'] as String
            : _slug(name),
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
      );
    } on CustomThemeException {
      rethrow;
    } catch (e) {
      throw CustomThemeException('Die Theme-Datei ist beschädigt: $e');
    }
  }

  static Color _color(String hex) {
    var s = hex.trim().replaceFirst('#', '');
    if (s.length == 6) s = 'FF$s';
    final v = int.tryParse(s, radix: 16);
    if (v == null || s.length != 8) {
      throw CustomThemeException('Ungültige Farbe „$hex".');
    }
    return Color(v);
  }

  static String _slug(String name) => name
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
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
    Uint8List? bytes;
    final img = j['image'];
    if (img is String && img.isNotEmpty) {
      final comma = img.indexOf(',');
      final b64 = comma >= 0 ? img.substring(comma + 1) : img;
      bytes = base64Decode(b64.trim());
    }
    return ThemeBackground(
      imageBytes: bytes,
      tile: j['fit'] == 'tile' || j['tile'] == true,
      opacity: ((j['opacity'] as num?)?.toDouble() ?? 1).clamp(0.0, 1.0),
      dim: ((j['dim'] as num?)?.toDouble() ?? 0).clamp(0.0, 1.0),
    );
  }
}

class CustomThemeException implements Exception {
  const CustomThemeException(this.message);
  final String message;
  @override
  String toString() => 'CustomThemeException: $message';
}
