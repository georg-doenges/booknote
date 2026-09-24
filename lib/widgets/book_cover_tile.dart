import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../models/models.dart';
import '../theme.dart';
import 'framed_cover.dart';

/// Cover-Kachel für das Bibliotheks-Grid. Ohne Cover: Platzhalter mit Titel.
/// [noteCount] > 0 zeigt oben rechts eine kleine Zahl. Das Cover wird nie
/// beschnitten (siehe [FramedCover]); das passende Raster ist
/// [CoverGridDelegate].
class BookCoverTile extends StatelessWidget {
  const BookCoverTile({
    super.key,
    required this.book,
    this.noteCount = 0,
    this.onTap,
    this.onLongPress,
  });

  final Book book;
  final int noteCount;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  static const _textGap = 6.0;

  /// Höhe des Textblocks unter dem Cover (Titel bis 2 Zeilen + Autor), passend
  /// zur Schriftgröße des Geräts – das Raster braucht sie für die Zellhöhe.
  static double textBlockHeight(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scaler = MediaQuery.textScalerOf(context);
    double line(TextStyle? style, double fallbackSize) =>
        scaler.scale(style?.fontSize ?? fallbackSize) * (style?.height ?? 1.4);
    // + 4: kleine Reserve für abweichende Schrift-Metriken.
    return _textGap +
        2 * line(textTheme.bodySmall, 12) +
        line(textTheme.labelSmall, 11) +
        4;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final url = book.coverUrl;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(BooknoteTheme.cardRadius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  FramedCover(
                    image: url == null ? null : CachedNetworkImageProvider(url),
                    fallback: _Placeholder(title: book.title),
                  ),
                  if (noteCount > 0)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: _CountBadge(count: noteCount),
                    ),
                ],
              ),
            ),
            const SizedBox(height: _textGap),
            Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            if (book.author != null)
              Text(
                book.author!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}

/// Raster für [BookCoverTile]: Die Cover-Fläche hat in jeder Zelle dasselbe
/// Hochformat [coverAspectRatio], darunter bleibt [textHeight] für Titel und
/// Autor. Alle Kacheln sind gleich hoch – mit oder ohne Cover, mit oder ohne
/// Autor. Spalten wie bei
/// `SliverGridDelegateWithMaxCrossAxisExtent`.
class CoverGridDelegate extends SliverGridDelegate {
  const CoverGridDelegate({
    required this.textHeight,
    this.maxCrossAxisExtent = 140,
    this.mainAxisSpacing = BooknoteTheme.gap16,
    this.crossAxisSpacing = BooknoteTheme.gap12,
  });

  /// Breite : Höhe der Cover-Fläche. 3:4 statt der klassischen 2:3: etwas
  /// niedriger, dadurch bleibt bei Covern mit anderem Seitenverhältnis weniger
  /// ungenutzter Platz, und es passen mehr Bücher auf den Bildschirm.
  static const coverAspectRatio = 3 / 4;

  final double textHeight;
  final double maxCrossAxisExtent;
  final double mainAxisSpacing;
  final double crossAxisSpacing;

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    final count = math.max(
      1,
      (constraints.crossAxisExtent / (maxCrossAxisExtent + crossAxisSpacing))
          .ceil(),
    );
    final usable = math.max(
      0.0,
      constraints.crossAxisExtent - crossAxisSpacing * (count - 1),
    );
    final cellWidth = usable / count;
    final cellHeight = cellWidth / coverAspectRatio + textHeight;
    return SliverGridRegularTileLayout(
      crossAxisCount: count,
      mainAxisStride: cellHeight + mainAxisSpacing,
      crossAxisStride: cellWidth + crossAxisSpacing,
      childMainAxisExtent: cellHeight,
      childCrossAxisExtent: cellWidth,
      reverseCrossAxis: axisDirectionIsReversed(constraints.crossAxisDirection),
    );
  }

  @override
  bool shouldRelayout(CoverGridDelegate old) =>
      old.textHeight != textHeight ||
      old.maxCrossAxisExtent != maxCrossAxisExtent ||
      old.mainAxisSpacing != mainAxisSpacing ||
      old.crossAxisSpacing != crossAxisSpacing;
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: scheme.onPrimary, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primaryContainer, scheme.tertiaryContainer],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book, color: scheme.onPrimaryContainer, size: 26),
          const SizedBox(height: 6),
          // Flexible: ein sehr langer Titel darf nie die Kachel sprengen.
          Flexible(
            child: Text(
              title,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              // Klein gehalten: Der Titel steht ohnehin unter der Kachel.
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: scheme.onPrimaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}
