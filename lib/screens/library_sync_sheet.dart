import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../l10n/l10n.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../theme.dart';

/// Bottom-Sheet für die **Bibliotheksdatei** (nicht der Abzug/Export):
/// sichern, abgleichen (Merge), oder zur Vorlage (Master) erklären.
/// Siehe `SYNC_DESIGN.md`.
Future<void> showLibrarySyncSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _LibrarySyncSheet(),
  );
}

enum _Phase { idle, working, merged, error }

class _LibrarySyncSheet extends StatefulWidget {
  const _LibrarySyncSheet();

  @override
  State<_LibrarySyncSheet> createState() => _LibrarySyncSheetState();
}

class _LibrarySyncSheetState extends State<_LibrarySyncSheet> {
  _Phase _phase = _Phase.idle;
  String _message = '';
  LibrarySyncMerged? _mergeResult;

  LibrarySync get _sync => AppScope.of(context).librarySync;

  void _snack(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _save({required bool toFile}) async {
    setState(() => _phase = _Phase.working);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final l = context.l10n;
    try {
      final ok = toFile
          ? await _sync.saveToFile(dialogTitle: l.dialogSaveAs)
          : await _sync.save();
      navigator.pop();
      if (ok) {
        messenger.showSnackBar(SnackBar(content: Text(l.syncSaved)));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _phase = _Phase.error;
          _message = l.syncSaveFailed('$e');
        });
      }
    }
  }

  Future<void> _merge() async {
    setState(() => _phase = _Phase.working);
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l10n;
    try {
      final result = await _sync.pickAndMerge(
        dialogTitle: l.dialogPickLibraryFile,
      );
      if (!mounted) return;
      switch (result) {
        case LibrarySyncCancelled():
          setState(() => _phase = _Phase.idle);
        case LibrarySyncMerged():
          setState(() {
            _phase = _Phase.merged;
            _mergeResult = result;
          });
        case LibrarySyncAdoptedMaster():
          Navigator.of(context).pop();
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                result.hard
                    ? l.syncAdoptedHard(result.books, result.notes)
                    : l.syncAdoptedSoft(result.books, result.notes),
              ),
            ),
          );
      }
    } on LibraryFileException catch (e) {
      if (mounted) {
        setState(() {
          _phase = _Phase.error;
          _message = libraryFileErrorText(l, e);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _phase = _Phase.error;
          _message = l.syncMergeFailed('$e');
        });
      }
    }
  }

  Future<void> _shareMerged() async {
    final merged = _mergeResult?.merged;
    if (merged == null) return;
    setState(() => _phase = _Phase.working);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final l = context.l10n;
    try {
      await _sync.shareSnapshot(merged);
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(l.syncUpdatedSaved)));
    } catch (e) {
      if (mounted) {
        setState(() => _phase = _Phase.merged);
        _snack(l.syncSaveFailed('$e'));
      }
    }
  }

  Future<void> _setAsMaster() async {
    var hard = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(ctx.l10n.syncMaster),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(ctx.l10n.syncMasterBody),
                const SizedBox(height: BooknoteTheme.gap8),
                RadioGroup<bool>(
                  groupValue: hard,
                  onChanged: (v) => setDialogState(() => hard = v ?? false),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RadioListTile<bool>(
                        value: false,
                        contentPadding: EdgeInsets.zero,
                        title: Text(ctx.l10n.syncSoft),
                        subtitle: Text(ctx.l10n.syncSoftBody),
                      ),
                      RadioListTile<bool>(
                        value: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(ctx.l10n.syncHard),
                        subtitle: Text(ctx.l10n.syncHardBody),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(ctx.l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(ctx.l10n.syncSet),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _phase = _Phase.working);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final l = context.l10n;
    try {
      await _sync.setAsMaster(hard: hard);
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(hard ? l.syncMasterSavedHard : l.syncMasterSavedSoft),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _phase = _Phase.error;
          _message = l.syncFailed('$e');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final l = context.l10n;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          BooknoteTheme.gap24,
          BooknoteTheme.gap12,
          BooknoteTheme.gap24,
          BooknoteTheme.gap24,
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
                  color: scheme.onSurfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: BooknoteTheme.gap16),
            Text(l.syncTitle, style: text.titleMedium),
            Explanation(
              child: Padding(
                padding: const EdgeInsets.only(top: BooknoteTheme.gap4),
                child: Text(
                  l.syncIntro,
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(height: BooknoteTheme.gap16),
            if (_phase == _Phase.merged && _mergeResult != null)
              _mergedView(text, scheme)
            else if (_phase == _Phase.error)
              _errorView(text, scheme)
            else
              _actions(text, scheme),
          ],
        ),
      ),
    );
  }

  Widget _actions(TextTheme text, ColorScheme scheme) {
    final l = context.l10n;
    final busy = _phase == _Phase.working;
    // Clean Mode: nur der Abstand zwischen den Knöpfen, ohne Erklärtext.
    Widget hint(String s) => context.cleanMode
        ? const SizedBox(height: BooknoteTheme.gap12)
        : Padding(
            padding: const EdgeInsets.only(
              top: BooknoteTheme.gap4,
              bottom: BooknoteTheme.gap12,
            ),
            child: Text(
              s,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: busy ? null : () => _save(toFile: false),
                icon: const Icon(Icons.ios_share),
                label: Text(l.commonShare),
              ),
            ),
            const SizedBox(width: BooknoteTheme.gap8),
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: busy ? null : () => _save(toFile: true),
                icon: const Icon(Icons.save_alt),
                label: Text(l.commonSave),
              ),
            ),
          ],
        ),
        hint(l.syncFileHint),
        FilledButton.icon(
          onPressed: busy ? null : _merge,
          icon: busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.merge),
          label: Text(l.syncMerge),
        ),
        hint(l.syncMergeHint),
        OutlinedButton.icon(
          onPressed: busy ? null : _setAsMaster,
          icon: const Icon(Icons.flag_outlined),
          label: Text(l.syncMaster),
        ),
        hint(l.syncMasterHint),
      ],
    );
  }

  Widget _mergedView(TextTheme text, ColorScheme scheme) {
    final r = _mergeResult!;
    final l = context.l10n;
    String line(String label, int after, int added) => added > 0
        ? l.syncCountLineAdded(label, after, added)
        : l.syncCountLine(label, after);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.merge, color: scheme.primary),
            const SizedBox(width: BooknoteTheme.gap8),
            Text(l.syncMergedTitle, style: text.titleSmall),
          ],
        ),
        const SizedBox(height: BooknoteTheme.gap8),
        Text(
          line(l.syncBooks, r.booksAfter, r.booksAdded),
          style: text.bodyMedium,
        ),
        Text(
          line(l.syncNotes, r.notesAfter, r.notesAdded),
          style: text.bodyMedium,
        ),
        const SizedBox(height: BooknoteTheme.gap16),
        FilledButton.icon(
          onPressed: _phase == _Phase.working ? null : _shareMerged,
          icon: const Icon(Icons.save_outlined),
          label: Text(l.syncSaveUpdated),
        ),
        const SizedBox(height: BooknoteTheme.gap8),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.commonDone),
        ),
      ],
    );
  }

  Widget _errorView(TextTheme text, ColorScheme scheme) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.error_outline, color: scheme.error),
            const SizedBox(width: BooknoteTheme.gap8),
            Expanded(child: Text(_message, style: text.bodyMedium)),
          ],
        ),
        const SizedBox(height: BooknoteTheme.gap16),
        OutlinedButton(
          onPressed: () => setState(() => _phase = _Phase.idle),
          child: Text(l.commonBack),
        ),
      ],
    );
  }
}
