import 'dart:async';

import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../services/services.dart';
import '../theme.dart';
import 'record_button.dart';

/// Kleines Mikrofon-Icon für ein Textfeld. Tippen öffnet ein Bottom-Sheet mit
/// einem großen Aufnahme-Button (wie im Notiz-Flow): sprechen → der Button
/// pulsiert → er stoppt nach kurzer Stille von selbst oder auf Tippen →
/// transkribieren → [onResult] mit dem Rohtext (kein Notiz-Parsing).
///
/// Nutzt denselben [TranscriptionService] wie der Aufnahme-Flow. Eigenes
/// Widget, damit es auch an anderen Feldern hängen kann.
class VoiceInputButton extends StatelessWidget {
  const VoiceInputButton({
    super.key,
    required this.onResult,
    this.onOpenSettings,
    this.tooltip = 'Per Sprache eingeben',
    this.language = 'de',
  });

  final ValueChanged<String> onResult;

  /// Wird angeboten, wenn der API-Key fehlt oder abgelehnt wurde.
  final VoidCallback? onOpenSettings;

  final String tooltip;
  final String language;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.mic_none),
      tooltip: tooltip,
      onPressed: () async {
        FocusScope.of(context).unfocus();
        final text = await showModalBottomSheet<String>(
          context: context,
          isScrollControlled: true,
          builder: (_) => _VoiceInputSheet(
            language: language,
            onOpenSettings: onOpenSettings,
          ),
        );
        if (text != null && text.trim().isNotEmpty) onResult(text.trim());
      },
    );
  }
}

enum _Phase { starting, recording, transcribing, error }

class _VoiceInputSheet extends StatefulWidget {
  const _VoiceInputSheet({required this.language, this.onOpenSettings});

  final String language;
  final VoidCallback? onOpenSettings;

  @override
  State<_VoiceInputSheet> createState() => _VoiceInputSheetState();
}

class _VoiceInputSheetState extends State<_VoiceInputSheet>
    with SingleTickerProviderStateMixin {
  static const _maxRecording = Duration(seconds: 20);

  final _recorder = NoteRecorder();
  final _silence = SilenceDetector();
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final Animation<double> _pulseScale = _pulse.drive(
    Tween(begin: 1.0, end: 1.06).chain(CurveTween(curve: Curves.easeInOut)),
  );

  _Phase _phase = _Phase.starting;
  String? _audioPath;
  String _message = '';
  bool _needsKey = false;
  bool _finishing = false;
  DateTime? _startedAt;
  Duration _elapsed = Duration.zero;
  Timer? _ticker;
  StreamSubscription<double>? _ampSub;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _ampSub?.cancel();
    _pulse.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    _ticker?.cancel();
    await _ampSub?.cancel();
    _silence.reset();
    _finishing = false;
    _startedAt = null;
    setState(() {
      _phase = _Phase.starting;
      _message = '';
      _elapsed = Duration.zero;
    });

    if (!await _recorder.hasPermission()) {
      _fail(
        'Mikrofon-Berechtigung fehlt. Bitte in den System-Einstellungen '
        'erlauben.',
      );
      return;
    }
    try {
      _audioPath = await _recorder.start();
    } catch (e) {
      _fail('Aufnahme konnte nicht starten: $e');
      return;
    }
    if (!mounted) return;

    _startedAt = DateTime.now();
    setState(() => _phase = _Phase.recording);
    _pulse.repeat(reverse: true);
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!mounted || _startedAt == null) return;
      setState(() => _elapsed = DateTime.now().difference(_startedAt!));
      if (_elapsed >= _maxRecording) _finish();
    });
    _ampSub = _recorder.amplitudeDbfs().listen((db) {
      if (_phase != _Phase.recording || _startedAt == null) return;
      final elapsed = DateTime.now().difference(_startedAt!);
      if (_silence.update(elapsed: elapsed, db: db)) _finish();
    });
  }

  void _fail(String message) {
    _pulse.stop();
    if (!mounted) return;
    setState(() {
      _phase = _Phase.error;
      _message = message;
      _needsKey = false;
    });
  }

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;

    final navigator = Navigator.of(context);
    final transcription = AppScope.of(context).transcription;

    _ticker?.cancel();
    await _ampSub?.cancel();
    _pulse.stop();

    final path = await _recorder.stop() ?? _audioPath;
    _audioPath = path;
    if (!mounted) return;
    if (path == null) {
      navigator.pop();
      return;
    }
    setState(() => _phase = _Phase.transcribing);

    try {
      final raw = await transcription.transcribe(
        path,
        language: widget.language,
      );
      await NoteRecorder.discard(path);
      _audioPath = null;
      if (!mounted) return;
      final text = raw.trim();
      if (text.isEmpty) {
        _toError('Nichts verstanden. Nochmal versuchen.', needsKey: false);
        return;
      }
      navigator.pop(text);
    } on TranscriptionException catch (e) {
      await NoteRecorder.discard(path);
      _audioPath = null;
      if (!mounted) return;
      _toError(
        e.message,
        needsKey:
            e.kind == TranscriptionErrorKind.missingApiKey ||
            e.kind == TranscriptionErrorKind.unauthorized,
      );
    }
  }

  void _toError(String message, {required bool needsKey}) {
    _finishing = false;
    _silence.reset();
    setState(() {
      _phase = _Phase.error;
      _message = message;
      _needsKey = needsKey;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
          children: [
            Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.onSurfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: BooknoteTheme.gap24),
            if (_phase == _Phase.error)
              _error(scheme, textTheme)
            else
              _live(scheme, textTheme),
          ],
        ),
      ),
    );
  }

  Widget _live(ColorScheme scheme, TextTheme textTheme) {
    final state = switch (_phase) {
      _Phase.recording => RecordButtonState.recording,
      _Phase.transcribing => RecordButtonState.busy,
      _ => RecordButtonState.idle,
    };
    return Column(
      children: [
        ScaleTransition(
          scale: _pulseScale,
          child: RecordButton(
            state: state,
            size: 156,
            onPressed: _phase == _Phase.recording ? _finish : null,
          ),
        ),
        const SizedBox(height: BooknoteTheme.gap16),
        Text(switch (_phase) {
          _Phase.starting => 'Mikrofon startet …',
          _Phase.recording => 'Sprich den Titel …',
          _Phase.transcribing => 'Wird erkannt …',
          _Phase.error => '',
        }, style: textTheme.titleMedium),
        const SizedBox(height: BooknoteTheme.gap4),
        Text(
          _phase == _Phase.recording
              ? 'stoppt nach kurzer Stille von selbst – oder tippen'
              : ' ',
          style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _error(ColorScheme scheme, TextTheme textTheme) {
    return Column(
      children: [
        Icon(Icons.error_outline, color: scheme.error, size: 40),
        const SizedBox(height: BooknoteTheme.gap12),
        Text(_message, textAlign: TextAlign.center),
        const SizedBox(height: BooknoteTheme.gap16),
        Wrap(
          spacing: BooknoteTheme.gap8,
          alignment: WrapAlignment.center,
          children: [
            if (_needsKey && widget.onOpenSettings != null)
              FilledButton.tonal(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onOpenSettings!();
                },
                child: const Text('Einstellungen'),
              ),
            FilledButton.tonal(onPressed: _start, child: const Text('Nochmal')),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Abbrechen'),
            ),
          ],
        ),
      ],
    );
  }
}
