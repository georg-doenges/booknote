import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../theme.dart';

/// Bottom-Sheet für die **Bibliotheksdatei** (nicht zu verwechseln mit dem
/// Abzug/Export): sichern und zwischen Geräten abgleichen. Siehe
/// `SYNC_DESIGN.md`.
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
  LibrarySyncMerged? _result;

  LibrarySync get _sync => AppScope.of(context).librarySync;

  Future<void> _save() async {
    setState(() => _phase = _Phase.working);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _sync.save();
      if (mounted) setState(() => _phase = _Phase.idle);
    } catch (e) {
      if (mounted) setState(() => _phase = _Phase.idle);
      messenger.showSnackBar(
        SnackBar(content: Text('Sichern fehlgeschlagen: $e')),
      );
    }
  }

  Future<void> _merge() async {
    setState(() => _phase = _Phase.working);
    try {
      final result = await _sync.pickAndMerge();
      if (!mounted) return;
      switch (result) {
        case LibrarySyncCancelled():
          setState(() => _phase = _Phase.idle);
        case LibrarySyncMerged():
          setState(() {
            _phase = _Phase.merged;
            _result = result;
          });
      }
    } on LibraryFileException catch (e) {
      if (mounted) {
        setState(() {
          _phase = _Phase.error;
          _message = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _phase = _Phase.error;
          _message = 'Abgleich fehlgeschlagen: $e';
        });
      }
    }
  }

  Future<void> _shareMerged() async {
    final merged = _result?.merged;
    if (merged == null) return;
    setState(() => _phase = _Phase.working);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _sync.shareSnapshot(merged);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Sichern fehlgeschlagen: $e')),
      );
    }
    if (mounted) setState(() => _phase = _Phase.merged);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final busy = _phase == _Phase.working;

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
            Text('Bibliothek sichern / abgleichen', style: text.titleMedium),
            const SizedBox(height: BooknoteTheme.gap4),
            Text(
              'Die Bibliotheksdatei enthält alle Bücher und Notizen. Lege sie '
              'z.B. in Google Drive ab und gleiche sie auf dem anderen Gerät '
              'darüber ab – nichts geht verloren, gelöschte Einträge bleiben '
              'gelöscht.',
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: BooknoteTheme.gap16),
            if (_phase == _Phase.merged && _result != null)
              _mergedView(text, scheme)
            else if (_phase == _Phase.error)
              _errorView(text, scheme)
            else
              _actions(busy),
          ],
        ),
      ),
    );
  }

  Widget _actions(bool busy) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FilledButton.icon(
        onPressed: busy ? null : _save,
        icon: const Icon(Icons.save_outlined),
        label: const Text('Sichern (Datei erstellen)'),
      ),
      const SizedBox(height: BooknoteTheme.gap8),
      OutlinedButton.icon(
        onPressed: busy ? null : _merge,
        icon: busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.sync),
        label: const Text('Aus Datei abgleichen'),
      ),
    ],
  );

  Widget _mergedView(TextTheme text, ColorScheme scheme) {
    final r = _result!;
    String line(String label, int after, int added) =>
        '$label: $after${added > 0 ? '  (+$added)' : ''}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.check_circle_outline, color: scheme.primary),
            const SizedBox(width: BooknoteTheme.gap8),
            Text('Abgeglichen', style: text.titleSmall),
          ],
        ),
        const SizedBox(height: BooknoteTheme.gap8),
        Text(
          line('Bücher', r.booksAfter, r.booksAdded),
          style: text.bodyMedium,
        ),
        Text(
          line('Notizen', r.notesAfter, r.notesAdded),
          style: text.bodyMedium,
        ),
        const SizedBox(height: BooknoteTheme.gap16),
        FilledButton.icon(
          onPressed: _phase == _Phase.working ? null : _shareMerged,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Aktualisierte Datei sichern'),
        ),
        const SizedBox(height: BooknoteTheme.gap8),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fertig'),
        ),
      ],
    );
  }

  Widget _errorView(TextTheme text, ColorScheme scheme) => Column(
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
        child: const Text('Zurück'),
      ),
    ],
  );
}
