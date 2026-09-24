import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../l10n/l10n.dart';
import '../models/models.dart';
import '../theme.dart';
import 'language_choice.dart';

/// Titel, Autor und Sprache eines Buchs bearbeiten. Gibt das geänderte Buch
/// zurück oder `null` bei Abbruch.
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
  late AppLanguage _language = widget.book.language;

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
        language: _language,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.bookEditTitle),
      // Mit Tastatur wird es eng: der Inhalt darf scrollen.
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _title,
            // Ohne Autofokus: Die Tastatur würde sonst gleich beim Öffnen die
            // Sprachwahl unten im Dialog verdecken.
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: l.bookEditTitleField),
          ),
          const SizedBox(height: BooknoteTheme.gap12),
          TextField(
            controller: _author,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: l.bookEditAuthorField),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: BooknoteTheme.gap16),
          Text(
            l.bookLanguageLabel,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: BooknoteTheme.gap4),
          LanguageChoice(
            value: _language,
            onChanged: (language) => setState(() => _language = language),
          ),
          Explanation(
            child: Text(
              l.bookLanguageHintEdit,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.commonCancel),
        ),
        FilledButton(onPressed: _save, child: Text(l.commonSave)),
      ],
    );
  }
}
