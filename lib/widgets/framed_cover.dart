import 'package:flutter/material.dart';

import '../theme.dart';

/// Ein Buchcover in einem Rahmen, das **nie beschnitten** wird: Es wird ganz
/// gezeigt (`BoxFit.contain`). Der Rahmen umschließt immer dieselbe Fläche, die
/// in einer ruhigen Kartenfarbe gefüllt ist – so liest sich jede Kachel als
/// gleich großes Rechteck, auch wenn das Cover selbst niedriger oder schmaler
/// ist (Google-Books-Cover haben sehr verschiedene Seitenverhältnisse). Der
/// Rahmen hat die Schriftfarbe (schwach durchscheinend) und passt sich so jedem
/// Farbschema an.
///
/// Ohne [image] oder wenn das Laden scheitert, füllt [fallback] die Fläche.
/// Die Größe bestimmt der Aufrufer (füllt den verfügbaren Platz).
class FramedCover extends StatelessWidget {
  const FramedCover({
    super.key,
    required this.image,
    required this.fallback,
    this.radius = BooknoteTheme.cardRadius,
    this.padding = 4,
  });

  final ImageProvider? image;
  final Widget fallback;
  final double radius;

  /// Luft zwischen Rahmen und Cover.
  final double padding;

  /// Rahmenfarbe: Schriftfarbe des Schemas, gut sichtbar, aber nicht hart.
  static Color borderColor(ColorScheme scheme) =>
      scheme.onSurface.withValues(alpha: 0.3);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final provider = image;
    return Container(
      decoration: BoxDecoration(
        // Die Fläche hinter dem Cover (Kartenfarbe des Schemas).
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor(scheme)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - 1),
        child: SizedBox.expand(
          child: provider == null
              ? fallback
              : Image(
                  image: provider,
                  fit: BoxFit.contain,
                  frameBuilder: (context, child, frame, syncLoaded) {
                    if (syncLoaded || frame != null) {
                      return Padding(
                        padding: EdgeInsets.all(padding),
                        child: child,
                      );
                    }
                    return const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                  errorBuilder: (_, _, _) => SizedBox.expand(child: fallback),
                ),
        ),
      ),
    );
  }
}
