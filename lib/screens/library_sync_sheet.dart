import 'package:flutter/material.dart';

import '../app_scope.dart';
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

  Future<void> _save() async {
    setState(() => _phase = _Phase.working);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await _sync.save();
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Bibliotheksdatei gesichert.')),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _phase = _Phase.error;
          _message = 'Sichern fehlgeschlagen: $e';
        });
      }
    }
  }

  Future<void> _merge() async {
    setState(() => _phase = _Phase.working);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await _sync.pickAndMerge();
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
                    ? 'Harte Vorlage übernommen: exakt ${result.books} Bücher, '
                          '${result.notes} Notizen.'
                    : 'Weiche Vorlage übernommen: ${result.books} Bücher, '
                          '${result.notes} Notizen.',
              ),
            ),
          );
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
    final merged = _mergeResult?.merged;
    if (merged == null) return;
    setState(() => _phase = _Phase.working);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await _sync.shareSnapshot(merged);
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Aktualisierte Bibliotheksdatei gesichert.'),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _phase = _Phase.merged);
        _snack('Sichern fehlgeschlagen: $e');
      }
    }
  }

  Future<void> _setAsMaster() async {
    var hard = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Als Vorlage (Master) setzen'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Der aktuelle Stand dieses Geräts wird zur Vorlage. Andere '
                  'Geräte richten sich beim nächsten Abgleich danach – nur so '
                  'werden Löschungen übertragen.',
                ),
                const SizedBox(height: BooknoteTheme.gap8),
                RadioGroup<bool>(
                  groupValue: hard,
                  onChanged: (v) => setDialogState(() => hard = v ?? false),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RadioListTile<bool>(
                        value: false,
                        contentPadding: EdgeInsets.zero,
                        title: Text('Weich'),
                        subtitle: Text(
                          'Andere Geräte übernehmen den Stand samt Löschungen, '
                          'behalten aber Einträge, die dort ganz neu sind.',
                        ),
                      ),
                      RadioListTile<bool>(
                        value: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text('Hart'),
                        subtitle: Text(
                          'Andere Geräte werden exakt auf diesen Stand gesetzt '
                          '– alles andere dort wird gelöscht.',
                        ),
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
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Setzen'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _phase = _Phase.working);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await _sync.setAsMaster(hard: hard);
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            hard
                ? 'Als harte Vorlage gesichert. Andere Geräte werden exakt '
                      'darauf gesetzt.'
                : 'Als weiche Vorlage gesichert. Andere Geräte gleichen sich '
                      'an.',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _phase = _Phase.error;
          _message = 'Fehlgeschlagen: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

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
            Text('Bibliothek abgleichen', style: text.titleMedium),
            const SizedBox(height: BooknoteTheme.gap4),
            Text(
              'Die Bibliotheksdatei enthält alle Bücher und Notizen. Lege sie '
              'z.B. in Google Drive ab und gleiche darüber zwischen deinen '
              'Geräten ab.',
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
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
    final busy = _phase == _Phase.working;
    Widget hint(String s) => Padding(
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
        FilledButton.tonalIcon(
          onPressed: busy ? null : _save,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Sichern (Datei erstellen)'),
        ),
        hint('Schreibt eine Datei mit dem aktuellen Stand.'),
        FilledButton.icon(
          onPressed: busy ? null : _merge,
          icon: busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.merge),
          label: const Text('Abgleichen (zusammenführen)'),
        ),
        hint(
          'Vereint Datei und App. Alles, was auf einer Seite noch da ist, '
          'bleibt – Löschungen werden hier nicht übertragen.',
        ),
        OutlinedButton.icon(
          onPressed: busy ? null : _setAsMaster,
          icon: const Icon(Icons.flag_outlined),
          label: const Text('Als Vorlage (Master) setzen'),
        ),
        hint(
          'Der einzige Weg, Löschungen zu übertragen. Beim Setzen wählst du '
          'weich (lokal Neues bleibt) oder hart (exakt überschreiben).',
        ),
      ],
    );
  }

  Widget _mergedView(TextTheme text, ColorScheme scheme) {
    final r = _mergeResult!;
    String line(String label, int after, int added) =>
        '$label: $after${added > 0 ? '  (+$added)' : ''}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.merge, color: scheme.primary),
            const SizedBox(width: BooknoteTheme.gap8),
            Text('Zusammengeführt', style: text.titleSmall),
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
