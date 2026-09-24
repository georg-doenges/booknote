import 'package:flutter/material.dart';

import '../models/models.dart';

/// Sprache des Buchs wählen: alle [AppLanguage]-Werte als Auswahl-Chips mit
/// dem Eigennamen („Deutsch", „English", „Français"). Immer sichtbar statt
/// hinter einem Menü, bricht bei weiteren Sprachen in die nächste Zeile um.
///
/// Gehört in den Inhalt einer Seite – mit einer Überschrift, die den Bezug
/// nennt („Sprache dieses Buchs"), nie in die AppBar.
class LanguageChoice extends StatelessWidget {
  const LanguageChoice({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final AppLanguage value;
  final ValueChanged<AppLanguage> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final language in AppLanguage.values)
          ChoiceChip(
            label: Text(language.label),
            selected: language == value,
            onSelected: (_) => onChanged(language),
          ),
      ],
    );
  }
}
