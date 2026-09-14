import 'dart:async';

import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../theme.dart';
import '../widgets/book_edit_dialog.dart';
import '../widgets/language_menu_button.dart';
import '../widgets/note_edit_dialog.dart';
import '../widgets/note_tile.dart';
import '../widgets/record_button.dart';
import 'book_detail_screen.dart';
import 'settings_screen.dart';

enum _Phase { idle, recording, transcribing, error }

/// Aufnahmen unter dieser Länge sind meist ein Versehen → Rückfrage.
const _minNoteRecording = Duration(seconds: 1);

/// Ab hier ein dezenter Hinweis, dass die Aufnahme lang wird.
const _longRecordingHint = Duration(seconds: 90);

/// Der wichtigste Screen: großer Aufnahme-Button, tap-to-start / tap-to-stop.
/// Nach dem Speichern bleibt man hier und kann sofort weiter aufnehmen.
class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key, required this.book});

  final Book book;

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  final _recorder = NoteRecorder();

  /// Anfangs `widget.book`; nach „Titel bearbeiten" der aktualisierte Stand.
  late Book _book = widget.book;

  /// Sprache dieser Aufnahme-Sitzung. Start ist immer die Buch-Vorgabe
  /// (`_book.language`); das Menü hier übersteuert nur diese eine Sitzung,
  /// ohne die Buch-Vorgabe zu ändern – beim nächsten Öffnen gilt wieder sie.
  late AppLanguage _language = _book.language;

  _Phase _phase = _Phase.idle;
  String? _pendingAudio; // bleibt bei Fehlern erhalten → „Erneut versuchen"
  TranscriptionException? _error;
  Duration _elapsed = Duration.zero;
  DateTime? _recordStartedAt;
  Timer? _ticker;

  /// In dieser Sitzung gespeicherte Notizen, neueste zuerst.
  final List<Note> _session = [];

  @override
  void dispose() {
    _ticker?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    switch (_phase) {
      case _Phase.idle:
      case _Phase.error:
        await _start();
      case _Phase.recording:
        await _stopAndTranscribe();
      case _Phase.transcribing:
        break;
    }
  }

  Future<void> _start() async {
    if (!await _recorder.hasPermission()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Mikrofon-Berechtigung fehlt. Bitte in den '
            'System-Einstellungen erlauben.',
          ),
        ),
      );
      return;
    }
    await NoteRecorder.discard(_pendingAudio);
    _pendingAudio = null;
    try {
      await _recorder.start();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Aufnahme konnte nicht starten: $e')),
      );
      return;
    }
    if (!mounted) return;
    _recordStartedAt = DateTime.now();
    _elapsed = Duration.zero;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
    });
    setState(() {
      _phase = _Phase.recording;
      _error = null;
    });
    Haptics.recordStart();
  }

  Future<void> _stopAndTranscribe() async {
    _ticker?.cancel();
    Haptics.recordStop();
    final startedAt = _recordStartedAt;
    final path = await _recorder.stop();
    if (path == null) {
      if (mounted) setState(() => _phase = _Phase.idle);
      return;
    }
    final duration = startedAt == null
        ? Duration.zero
        : DateTime.now().difference(startedAt);
    if (duration < _minNoteRecording) {
      final send = mounted ? await _confirmVeryShort() : false;
      if (send != true) {
        await NoteRecorder.discard(path);
        if (mounted) setState(() => _phase = _Phase.idle);
        return;
      }
    }
    _pendingAudio = path;
    await _transcribe();
  }

  Future<bool?> _confirmVeryShort() => showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Sehr kurze Aufnahme'),
      content: const Text(
        'Die Aufnahme war unter einer Sekunde. Trotzdem transkribieren?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Verwerfen'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Transkribieren'),
        ),
      ],
    ),
  );

  Future<void> _transcribe() async {
    final path = _pendingAudio;
    if (path == null) return;
    setState(() {
      _phase = _Phase.transcribing;
      _error = null;
    });

    final scope = AppScope.of(context);
    try {
      final raw = await scope.transcription.transcribe(
        path,
        language: _language.code,
      );
      final parsed = scope.parser.parse(raw, language: _language);
      final note = await scope.notes.create(
        sourceId: _book.id,
        page: parsed.page,
        position: parsed.position,
        text: parsed.text,
        rawTranscript: parsed.rawTranscript,
        language: _language,
      );
      await NoteRecorder.discard(path);
      _pendingAudio = null;
      if (!mounted) return;
      setState(() {
        _session.insert(0, note);
        _phase = _Phase.idle;
      });
      Haptics.saved();
    } on TranscriptionException catch (e) {
      // Audio bleibt in _pendingAudio → Nutzer kann es erneut versuchen.
      if (!mounted) return;
      setState(() {
        _error = e;
        _phase = _Phase.error;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = TranscriptionException(
          TranscriptionErrorKind.server,
          'Unerwarteter Fehler: $e',
        );
        _phase = _Phase.error;
      });
    }
  }

  Future<void> _discardPending() async {
    await NoteRecorder.discard(_pendingAudio);
    _pendingAudio = null;
    setState(() {
      _phase = _Phase.idle;
      _error = null;
    });
  }

  /// Titel/Autor korrigieren (langer Druck auf den Titel) – selten gebraucht,
  /// deshalb unauffällig.
  Future<void> _editBook() async {
    final edited = await showBookEditDialog(context, _book);
    if (edited == null || !mounted) return;
    await AppScope.of(context).books.update(edited);
    if (!mounted) return;
    setState(() => _book = edited);
  }

  /// Notiz aus der Sitzungsliste direkt hier bearbeiten (statt Umweg über die
  /// Notizübersicht).
  Future<void> _editSessionNote(int index) async {
    final edited = await showNoteEditDialog(context, _session[index]);
    if (edited == null || !mounted) return;
    await AppScope.of(context).notes.update(edited);
    if (!mounted) return;
    setState(() => _session[index] = edited);
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final muted = scheme.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onLongPress: _editBook,
          child: Text(_book.title),
        ),
        actions: [
          LanguageMenuButton(
            value: _language,
            tooltip:
                'Sprache dieser Aufnahme (Buch-Vorgabe: '
                '${_book.language.label})',
            onSelected: (l) => setState(() => _language = l),
          ),
        ],
      ),
      // SafeArea unten: sonst verdeckt die System-Navigationsleiste die
      // Aktionen der Fehlerkarte („Erneut versuchen").
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: LayoutBuilder(
                builder: (context, c) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: c.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: BooknoteTheme.gap8),
                          RecordButton(
                            state: switch (_phase) {
                              _Phase.recording => RecordButtonState.recording,
                              _Phase.transcribing => RecordButtonState.busy,
                              _Phase.idle ||
                              _Phase.error => RecordButtonState.idle,
                            },
                            onPressed: _toggle,
                          ),
                          const SizedBox(height: BooknoteTheme.gap24),
                          Text(_statusLine(), style: text.titleMedium),
                          if (_phase == _Phase.recording) ...[
                            Padding(
                              padding: const EdgeInsets.only(
                                top: BooknoteTheme.gap4,
                              ),
                              child: Text(
                                _fmt(_elapsed),
                                style: text.headlineSmall?.copyWith(
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ),
                            if (_elapsed >= _longRecordingHint)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  BooknoteTheme.gap24,
                                  BooknoteTheme.gap4,
                                  BooknoteTheme.gap24,
                                  0,
                                ),
                                child: Text(
                                  'Lange Aufnahme – Whisper transkribiert alles am '
                                  'Stück.',
                                  textAlign: TextAlign.center,
                                  style: text.bodySmall?.copyWith(
                                    color: scheme.tertiary,
                                  ),
                                ),
                              ),
                          ],
                          if (_phase == _Phase.idle && _session.isEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                BooknoteTheme.gap24,
                                BooknoteTheme.gap12,
                                BooknoteTheme.gap24,
                                0,
                              ),
                              child: Text(
                                'Sprich z.B.: „Seite 47 oben, hier argumentiert der '
                                'Autor, dass …"',
                                textAlign: TextAlign.center,
                                style: text.bodyMedium?.copyWith(color: muted),
                              ),
                            ),
                          if (_phase == _Phase.idle || _phase == _Phase.error)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: BooknoteTheme.gap24,
                              ),
                              child: _AllNotesButton(bookId: _book.id),
                            ),
                          const SizedBox(height: BooknoteTheme.gap8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_phase == _Phase.error && _error != null)
              _ErrorCard(
                error: _error!,
                onRetry: _transcribe,
                onDiscard: _discardPending,
                onSettings: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
            if (_session.isNotEmpty)
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        BooknoteTheme.gap16,
                        BooknoteTheme.gap8,
                        BooknoteTheme.gap16,
                        BooknoteTheme.gap4,
                      ),
                      child: Text(
                        'Diese Sitzung (${_session.length})',
                        style: text.labelLarge?.copyWith(color: muted),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _session.length,
                        itemBuilder: (_, i) => NoteTile(
                          note: _session[i],
                          highlight: i == 0,
                          onTap: () => _editSessionNote(i),
                        ),
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

  String _statusLine() => switch (_phase) {
    _Phase.idle => 'Tippen zum Aufnehmen',
    _Phase.recording => 'Aufnahme läuft – tippen zum Beenden',
    _Phase.transcribing => 'Wird transkribiert …',
    _Phase.error => 'Transkription fehlgeschlagen',
  };
}

/// Wichtige sekundäre Option auf dem Aufnahme-Screen: zur Notizübersicht des
/// Buchs. Zeigt die aktuelle Notizzahl (inkl. der gerade aufgenommenen).
class _AllNotesButton extends StatelessWidget {
  const _AllNotesButton({required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context) {
    final notes = AppScope.of(context).notes;
    return StreamBuilder<List<Note>>(
      stream: notes.watchBySource(bookId),
      builder: (context, snap) {
        final count = snap.data?.length;
        final label = count == null
            ? 'Notizen zu diesem Buch'
            : count == 1
            ? '1 Notiz zu diesem Buch'
            : '$count Notizen zu diesem Buch';
        return OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => BookDetailScreen(bookId: bookId)),
          ),
          icon: const Icon(Icons.menu_book_outlined),
          label: Text(label),
        );
      },
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.error,
    required this.onRetry,
    required this.onDiscard,
    required this.onSettings,
  });

  final TranscriptionException error;
  final VoidCallback onRetry;
  final VoidCallback onDiscard;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final needsKey =
        error.kind == TranscriptionErrorKind.missingApiKey ||
        error.kind == TranscriptionErrorKind.unauthorized;
    return Card(
      margin: const EdgeInsets.all(BooknoteTheme.gap12),
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(BooknoteTheme.gap16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              error.message,
              style: TextStyle(color: scheme.onErrorContainer),
            ),
            if (error.cause != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${error.cause}',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: scheme.onErrorContainer),
                ),
              ),
            const SizedBox(height: 4),
            Text(
              'Die Aufnahme ist noch da.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: scheme.onErrorContainer),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if (needsKey)
                  FilledButton.tonalIcon(
                    onPressed: onSettings,
                    icon: const Icon(Icons.key),
                    label: const Text('API-Key eingeben'),
                  ),
                FilledButton.tonalIcon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Erneut versuchen'),
                ),
                TextButton(
                  onPressed: onDiscard,
                  child: const Text('Verwerfen'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
