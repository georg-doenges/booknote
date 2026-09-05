import 'package:flutter/material.dart';

import '../models/models.dart';

/// Dialog zum Bearbeiten von Seite, Position und Text einer Notiz.
/// Gibt die geänderte Notiz zurück oder `null` bei Abbruch.
Future<Note?> showNoteEditDialog(BuildContext context, Note note) {
  return showDialog<Note>(
    context: context,
    builder: (_) => _NoteEditDialog(note: note),
  );
}

class _NoteEditDialog extends StatefulWidget {
  const _NoteEditDialog({required this.note});
  final Note note;

  @override
  State<_NoteEditDialog> createState() => _NoteEditDialogState();
}

class _NoteEditDialogState extends State<_NoteEditDialog> {
  late final _page = TextEditingController(text: widget.note.page ?? '');
  late final _position = TextEditingController(
    text: widget.note.position ?? '',
  );
  late final _text = TextEditingController(text: widget.note.text);

  @override
  void dispose() {
    _page.dispose();
    _position.dispose();
    _text.dispose();
    super.dispose();
  }

  void _save() {
    final page = _page.text.trim();
    final position = _position.text.trim();
    Navigator.of(context).pop(
      widget.note.copyWith(
        page: page.isEmpty ? null : page,
        clearPage: page.isEmpty,
        position: position.isEmpty ? null : position,
        clearPosition: position.isEmpty,
        text: _text.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Notiz bearbeiten'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _page,
                    decoration: const InputDecoration(
                      labelText: 'Seite',
                      hintText: '47 oder 88f.',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _position,
                    decoration: const InputDecoration(
                      labelText: 'Position',
                      hintText: 'oben / Zeile 10',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _text,
              autofocus: true,
              minLines: 3,
              maxLines: 8,
              decoration: const InputDecoration(labelText: 'Text'),
            ),
            const SizedBox(height: 12),
            ExpansionTile(
              title: Text(
                'Original-Transkript',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              tilePadding: EdgeInsets.zero,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: SelectableText(
                    widget.note.rawTranscript,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton(onPressed: _save, child: const Text('Speichern')),
      ],
    );
  }
}
