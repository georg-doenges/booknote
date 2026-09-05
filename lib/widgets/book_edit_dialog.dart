import 'package:flutter/material.dart';

import '../models/models.dart';

/// Titel und Autor eines Buchs bearbeiten. Gibt das geänderte Buch zurück
/// oder `null` bei Abbruch.
Future<Book?> showBookEditDialog(BuildContext context, Book book) {
  return showDialog<Book>(
    context: context,
    builder: (_) => _BookEditDialog(book: book),
  );
}

class _BookEditDialog extends StatefulWidget {
  const _BookEditDialog({required this.book});
  final Book book;

  @override
  State<_BookEditDialog> createState() => _BookEditDialogState();
}

class _BookEditDialogState extends State<_BookEditDialog> {
  late final _title = TextEditingController(text: widget.book.title);
  late final _author = TextEditingController(text: widget.book.author ?? '');

  @override
  void dispose() {
    _title.dispose();
    _author.dispose();
    super.dispose();
  }

  void _save() {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    final author = _author.text.trim();
    Navigator.of(context).pop(
      widget.book.copyWith(
        title: title,
        author: author.isEmpty ? null : author,
        clearAuthor: author.isEmpty,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Buch bearbeiten'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _title,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Titel'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _author,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Autor (optional)'),
            onSubmitted: (_) => _save(),
          ),
        ],
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
