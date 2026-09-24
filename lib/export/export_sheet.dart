import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../l10n/l10n.dart';
import '../models/models.dart';
import '../theme.dart';
import 'export_labels.dart';
import 'exporter.dart';
import 'share_export.dart';

/// Auf welcher Ebene exportiert wird.
enum ExportScope { book, author, library }

/// Zeigt ein Bottom-Sheet mit Ebenen-Auswahl (dieses Buch / alle eines Autors /
/// ganze Bibliothek) und Format-Auswahl (Markdown / Text) und teilt das
/// Ergebnis über den System-Share-Sheet.
///
/// [initialScope] ist die Vorauswahl – aufrufende Screens setzen sie auf die
/// Ebene, auf der der Nutzer gerade ist. [book] / [author] liefern den Kontext
/// für die jeweilige Ebene.
Future<void> showExportSheet(
  BuildContext context, {
  required ExportScope initialScope,
  Book? book,
  String? author,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) =>
        _ExportSheet(initialScope: initialScope, book: book, author: author),
  );
}

class _ExportSheet extends StatefulWidget {
  const _ExportSheet({required this.initialScope, this.book, this.author});

  final ExportScope initialScope;
  final Book? book;
  final String? author;

  @override
  State<_ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends State<_ExportSheet> {
  late ExportScope _scope = widget.initialScope;
  late Exporter _exporter = AppScope.of(context).exporters.first;
  bool _busy = false;

  Future<void> _run({required bool toFile}) async {
    setState(() => _busy = true);
    final scope = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final l = context.l10n;
    final languageCode = Localizations.localeOf(context).languageCode;
    try {
      final request = await _buildRequest(
        scope,
        exportLabelsFor(l, languageCode),
      );
      if (request.books.isEmpty) {
        messenger.showSnackBar(SnackBar(content: Text(l.exportNothing)));
        if (mounted) setState(() => _busy = false);
        return;
      }
      final result = _exporter.export(request);
      navigator.pop();
      final ok = toFile
          ? await saveExportToFile(result, dialogTitle: l.dialogSaveAs)
          : await shareExport(result);
      if (ok) {
        final format = _formatLabel(l, _exporter);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              toFile
                  ? l.exportSavedFile(format, result.fileName)
                  : l.exportDone(format, result.fileName),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(content: Text(l.exportFailed('$e'))));
    }
  }

  /// „Markdown" ist überall gleich; „Text" heißt auf Französisch „Texte".
  String _formatLabel(AppLocalizations l, Exporter e) =>
      e.fileExtension == 'txt' ? l.exportFormatText : e.formatName;

  Future<ExportRequest> _buildRequest(
    AppScope scope,
    ExportLabels labels,
  ) async {
    switch (_scope) {
      case ExportScope.book:
        final notes = await scope.notes.getBySource(widget.book!.id);
        return ExportRequest.single(widget.book!, notes, labels: labels);
      case ExportScope.author:
        final books = await _sortedByTitle(
          scope,
          (b) => b.author == widget.author,
        );
        return ExportRequest(
          books: books,
          collectionTitle: widget.author!,
          labels: labels,
        );
      case ExportScope.library:
        final books = await _sortedByTitle(scope, (_) => true);
        return ExportRequest(
          books: books,
          collectionTitle: labels.library,
          labels: labels,
        );
    }
  }

  Future<List<ExportBook>> _sortedByTitle(
    AppScope scope,
    bool Function(Book) keep,
  ) async {
    final all = (await scope.books.getAll()).where(keep).toList()
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return [
      for (final b in all) ExportBook(b, await scope.notes.getBySource(b.id)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final exporters = AppScope.of(context).exporters;
    final l = context.l10n;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          BooknoteTheme.gap8,
          BooknoteTheme.gap12,
          BooknoteTheme.gap8,
          BooknoteTheme.gap16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: BooknoteTheme.gap12),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: BooknoteTheme.gap12,
              ),
              child: Text(
                l.exportTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: BooknoteTheme.gap8),
            RadioGroup<ExportScope>(
              groupValue: _scope,
              onChanged: (v) => setState(() => _scope = v ?? _scope),
              child: Column(
                children: [
                  if (widget.book != null)
                    RadioListTile(
                      value: ExportScope.book,
                      title: Text(l.exportThisBook),
                      subtitle: Text(
                        widget.book!.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (widget.author != null)
                    RadioListTile(
                      value: ExportScope.author,
                      title: Text(l.exportAuthorBooks),
                      subtitle: Text(
                        widget.author!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  RadioListTile(
                    value: ExportScope.library,
                    title: Text(l.exportWholeLibrary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: BooknoteTheme.gap12),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: BooknoteTheme.gap12,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SegmentedButton<Exporter>(
                  segments: [
                    for (final e in exporters)
                      ButtonSegment(value: e, label: Text(_formatLabel(l, e))),
                  ],
                  selected: {_exporter},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) =>
                      setState(() => _exporter = s.first),
                ),
              ),
            ),
            const SizedBox(height: BooknoteTheme.gap16),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: BooknoteTheme.gap12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: _busy ? null : () => _run(toFile: false),
                      icon: const Icon(Icons.ios_share),
                      label: Text(l.commonShare),
                    ),
                  ),
                  const SizedBox(width: BooknoteTheme.gap8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _busy ? null : () => _run(toFile: true),
                      icon: _busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_alt),
                      label: Text(l.commonSave),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
