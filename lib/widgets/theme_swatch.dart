import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/models.dart';

/// Vorschau-Kachel eines Farbschemas: das zum Schema eingefärbte Logo, wenn es
/// eines gibt – sonst eine abstrakte Farbkachel (Fläche + Primärfarbe). Die
/// Liste der installierten Schemata und der Katalog benutzen dieselbe Kachel,
/// damit beide gleich aussehen.
class ThemeSwatch extends StatelessWidget {
  const ThemeSwatch({
    super.key,
    this.logoBytes,
    this.logoUrl,
    required this.surface,
    required this.primary,
  });

  /// Vorschau eines installierten Schemas.
  factory ThemeSwatch.fromTheme(CustomTheme theme, {Key? key}) => ThemeSwatch(
    key: key,
    logoBytes: theme.logoBytes,
    surface: theme.overrides['surface'] ?? defaultSurface(theme.brightness),
    primary: theme.overrides['primary'] ?? theme.seed,
  );

  static const size = 34.0;

  /// Flächenfarbe, wenn ein Schema keine `surface`-Rolle setzt.
  static Color defaultSurface(Brightness brightness) =>
      brightness == Brightness.dark
      ? const Color(0xFF121212)
      : const Color(0xFFFDFDFD);

  final Uint8List? logoBytes;

  /// Logo aus dem Netz (Katalog); solange es lädt oder falls es fehlschlägt,
  /// steht die Farbkachel da.
  final String? logoUrl;
  final Color surface;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final chip = _ColorChip(surface: surface, primary: primary);
    final Widget content;
    if (logoBytes != null) {
      content = Image.memory(
        logoBytes!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => chip,
      );
    } else if (logoUrl != null) {
      content = CachedNetworkImage(
        imageUrl: logoUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, _) => chip,
        errorWidget: (_, _, _) => chip,
      );
    } else {
      content = chip;
    }
    return ClipRRect(borderRadius: BorderRadius.circular(8), child: content);
  }
}

class _ColorChip extends StatelessWidget {
  const _ColorChip({required this.surface, required this.primary});

  final Color surface;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ThemeSwatch.size,
      height: ThemeSwatch.size,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
      ),
    );
  }
}
