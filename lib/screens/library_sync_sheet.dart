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

enum _Phase { idle, working, done, error }

class _LibrarySyncSheet extends StatefulWidget {
  const _LibrarySyncSheet();

  @override
  State<_LibrarySyncSheet> createState() => _LibrarySyncSheetState();
}

class _LibrarySyncSheetState extends State<_LibrarySyncSheet> {
  _Phase _phase = _Phase.idle;
  String _message = '';
  Widget? _resultBody;

  LibrarySync get _sync => AppScope.of(context).librarySync;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _phase = _Phase.working);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        setState(() {
          _phase = _Phase.error;
          _message = e is LibraryFileException
              ? e.message
              : 'Fehlgeschlagen: $e';
        });
      }
    }
  }

  Future<void> _save() => _run(() async {
    await _sync.save();
    if (mounted) setState(() => _phase = _Phase.idle);
  });

  Future<void> _merge() => _run(() async {
    final result = await _sync.pickAndMerge();
    if (!mounted) return;
    switch (result) {
      case LibrarySyncCancelled():
        setState(() => _phase = _Phase.idle);
      case LibrarySyncMerged():
        setState(() {
          _phase = _Phase.done;
          _resultBody = _mergedResult(result);
        });
      case LibrarySyncAdoptedMaster():
        setState(() {
          _phase = _Phase.done;
          _resultBody = _adoptedResult(result);
        });
    }
  });

  Future<void> _setAsMaster() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Als Vorlage (Master) setzen?'),
        content: const Text(
          'Der aktuelle Stand dieses Geräts wird zur verbindlichen Vorlage. '
          'Andere Geräte übernehmen ihn beim nächsten Abgleich vollständig – '
          'auch dort neu Hinzugefügtes wird dann überschrieben.\n\n'
          'Nutze das nur, wenn du hier gerade alles konsolidiert hast.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Als Master sichern'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _run(() async {
      await _sync.setAsMaster();
      if (mounted) setState(() => _phase = _Phase.idle);
    });
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
            if (_phase == _Phase.done && _resultBody != null)
              _resultBody!
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
          'Vereint Datei und App. Nichts geht verloren; Löschungen, die neuer '
          'sind als die Datei, werden übernommen.',
        ),
        OutlinedButton.icon(
          onPressed: busy ? null : _setAsMaster,
          icon: const Icon(Icons.flag_outlined),
          label: const Text('Als Vorlage (Master) setzen'),
        ),
        hint(
          'Erklärt diesen Stand zur Vorlage. Andere Geräte übernehmen ihn beim '
          'nächsten Abgleich komplett.',
        ),
      ],
    );
  }

  Widget _mergedResult(LibrarySyncMerged r) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    String line(String label, int after, int added) =>
        '$label: $after${added > 0 ? '  (+$added)' : ''}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _resultHeader(Icons.merge, 'Zusammengeführt', scheme.primary),
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
          onPressed: _phase == _Phase.working ? null : _shareMerged(r),
          icon: const Icon(Icons.save_outlined),
          label: const Text('Aktualisierte Datei sichern'),
        ),
        const SizedBox(height: BooknoteTheme.gap8),
        _doneButton(),
      ],
    );
  }

  Widget _adoptedResult(LibrarySyncAdoptedMaster r) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _resultHeader(Icons.flag, 'Vorlage übernommen', scheme.tertiary),
        const SizedBox(height: BooknoteTheme.gap8),
        Text(
          'Die Datei war als Master markiert. Der Stand dieses Geräts wurde '
          'komplett daran angeglichen.',
          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: BooknoteTheme.gap8),
        Text('Bücher: ${r.books}', style: text.bodyMedium),
        Text('Notizen: ${r.notes}', style: text.bodyMedium),
        const SizedBox(height: BooknoteTheme.gap16),
        _doneButton(),
      ],
    );
  }

  VoidCallback _shareMerged(LibrarySyncMerged r) => () async {
    setState(() => _phase = _Phase.working);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _sync.shareSnapshot(r.merged);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Sichern fehlgeschlagen: $e')),
      );
    }
    if (mounted) setState(() => _phase = _Phase.done);
  };

  Widget _resultHeader(IconData icon, String label, Color color) => Row(
    children: [
      Icon(icon, color: color),
      const SizedBox(width: BooknoteTheme.gap8),
      Text(label, style: Theme.of(context).textTheme.titleSmall),
    ],
  );

  Widget _doneButton() => TextButton(
    onPressed: () => Navigator.of(context).pop(),
    child: const Text('Fertig'),
  );

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
