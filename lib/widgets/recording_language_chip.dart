import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../l10n/l10n.dart';
import '../models/models.dart';

/// Sprache der laufenden Aufnahmen – als beschriftete Schaltfläche im Inhalt
/// des Aufnahme-Bildschirms („Aufnahmesprache: Deutsch"), nicht als Symbol in
/// der AppBar.
///
/// Sie übersteuert die Sprache des Buchs ([bookLanguage]) nur für jetzt; das
/// Menü sagt das ausdrücklich und nennt die Sprache des Buchs. Weicht die Wahl
/// von ihr ab, ist die Schaltfläche hervorgehoben.
class RecordingLanguageChip extends StatelessWidget {
  const RecordingLanguageChip({
    super.key,
    required this.value,
    required this.bookLanguage,
    required this.onSelected,
    this.enabled = true,
  });

  final AppLanguage value;
  final AppLanguage bookLanguage;
  final ValueChanged<AppLanguage> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final differs = value != bookLanguage;
    final clean = context.cleanMode;
    final foreground = differs ? scheme.onTertiaryContainer : scheme.onSurface;
    final label = l.recLanguageChip(value.label);

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      // Das Material trägt Farbe und Form; der Wirkungsring des Menüs liegt
      // darüber und wird von der Form beschnitten.
      child: Material(
        color: differs ? scheme.tertiaryContainer : scheme.surfaceContainerHigh,
        shape: StadiumBorder(side: BorderSide(color: scheme.outlineVariant)),
        clipBehavior: Clip.antiAlias,
        child: PopupMenuButton<AppLanguage>(
          enabled: enabled,
          tooltip: label,
          onSelected: onSelected,
          itemBuilder: (context) => [
            // Clean Mode: ohne die Erklärung „Nur für jetzt …".
            if (!clean) ...[
              PopupMenuItem<AppLanguage>(
                enabled: false,
                child: Text(
                  l.recLanguageMenuNote(bookLanguage.label),
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
              const PopupMenuDivider(),
            ],
            for (final language in AppLanguage.values)
              CheckedPopupMenuItem<AppLanguage>(
                value: language,
                checked: language == value,
                child: Text(language.label),
              ),
          ],
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.translate, size: 18, color: foreground),
                const SizedBox(width: 8),
                // Flexible: bei großer Systemschrift kürzen statt überlaufen.
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge
                        ?.copyWith(color: foreground),
                  ),
                ),
                Icon(Icons.arrow_drop_down, size: 20, color: foreground),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
