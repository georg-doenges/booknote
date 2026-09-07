import 'package:flutter/material.dart';

import '../models/models.dart';

/// Kompakter Sprach-Umschalter für die AppBar: zeigt den aktuellen Code
/// („DE"/„EN") und öffnet ein Menü mit allen [AppLanguage]-Werten. Bewusst kein
/// Kippschalter, damit später weitere Sprachen dazukommen können.
class LanguageMenuButton extends StatelessWidget {
  const LanguageMenuButton({
    super.key,
    required this.value,
    required this.onSelected,
    this.tooltip = 'Sprache',
  });

  final AppLanguage value;
  final ValueChanged<AppLanguage> onSelected;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<AppLanguage>(
      tooltip: tooltip,
      initialValue: value,
      onSelected: onSelected,
      itemBuilder: (_) => [
        for (final l in AppLanguage.values)
          PopupMenuItem(value: l, child: Text(l.label)),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.translate, size: 20),
            const SizedBox(width: 4),
            Text(value.code.toUpperCase()),
            const Icon(Icons.arrow_drop_down, size: 20),
          ],
        ),
      ),
    );
  }
}
