import 'package:flutter/material.dart';

import '../models/models.dart';

/// Fragt beim Anlegen eines Buchs die Default-Sprache für Aufnahmen ab.
/// Deutsch ist vorgewählt; gibt `null` zurück, wenn abgebrochen wird.
Future<AppLanguage?> showBookLanguageDialog(BuildContext context) {
  return showDialog<AppLanguage>(
    context: context,
    builder: (_) => const _BookLanguageDialog(),
  );
}

class _BookLanguageDialog extends StatefulWidget {
  const _BookLanguageDialog();

  @override
  State<_BookLanguageDialog> createState() => _BookLanguageDialogState();
}

class _BookLanguageDialogState extends State<_BookLanguageDialog> {
  AppLanguage _selected = AppLanguage.german;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sprache dieses Buchs'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gilt als Vorgabe für Aufnahmen zu diesem Buch – lässt sich bei '
            'einzelnen Aufnahmen trotzdem übersteuern.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          RadioGroup<AppLanguage>(
            groupValue: _selected,
            onChanged: (l) => setState(() => _selected = l ?? _selected),
            child: Column(
              children: [
                for (final l in AppLanguage.values)
                  RadioListTile<AppLanguage>(value: l, title: Text(l.label)),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          child: const Text('Buch anlegen'),
        ),
      ],
    );
  }
}
