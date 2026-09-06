import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../services/services.dart';

/// Mikrofon-Knopf für ein Textfeld: tippen → aufnehmen → nochmal tippen →
/// transkribieren → [onResult] mit dem Rohtext (kein Notiz-Parsing).
///
/// Nutzt denselben [TranscriptionService] wie der Aufnahme-Flow. Als eigenes
/// Widget, damit es später auch an anderen Feldern hängen kann.
class VoiceInputButton extends StatefulWidget {
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
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

enum _Phase { idle, recording, transcribing }

class _VoiceInputButtonState extends State<VoiceInputButton> {
  final _recorder = NoteRecorder();
  _Phase _phase = _Phase.idle;
  String? _audioPath;

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    switch (_phase) {
      case _Phase.idle:
        await _start();
      case _Phase.recording:
        await _stopAndTranscribe();
      case _Phase.transcribing:
        break;
    }
  }

  Future<void> _start() async {
    if (!await _recorder.hasPermission()) {
      _snack(
        'Mikrofon-Berechtigung fehlt. Bitte in den System-Einstellungen '
        'erlauben.',
      );
      return;
    }
    try {
      _audioPath = await _recorder.start();
    } catch (e) {
      _snack('Aufnahme konnte nicht starten: $e');
      return;
    }
    if (!mounted) return;
    setState(() => _phase = _Phase.recording);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Aufnahme läuft – Mikrofon erneut tippen zum Beenden'),
          duration: Duration(minutes: 5),
        ),
      );
  }

  Future<void> _stopAndTranscribe() async {
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    final transcription = AppScope.of(context).transcription;
    final path = await _recorder.stop() ?? _audioPath;
    _audioPath = path;
    if (!mounted) return;
    if (path == null) {
      setState(() => _phase = _Phase.idle);
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
      setState(() => _phase = _Phase.idle);
      final text = raw.trim();
      if (text.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Nichts verstanden. Nochmal versuchen.'),
          ),
        );
        return;
      }
      widget.onResult(text);
    } on TranscriptionException catch (e) {
      await NoteRecorder.discard(path);
      _audioPath = null;
      if (!mounted) return;
      setState(() => _phase = _Phase.idle);
      final needsKey =
          e.kind == TranscriptionErrorKind.missingApiKey ||
          e.kind == TranscriptionErrorKind.unauthorized;
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.message),
          action: needsKey && widget.onOpenSettings != null
              ? SnackBarAction(
                  label: 'Einstellungen',
                  onPressed: widget.onOpenSettings!,
                )
              : null,
        ),
      );
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return switch (_phase) {
      _Phase.transcribing => const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      _Phase.recording => IconButton(
        icon: const Icon(Icons.stop),
        color: scheme.error,
        tooltip: 'Aufnahme beenden',
        onPressed: _toggle,
      ),
      _Phase.idle => IconButton(
        icon: const Icon(Icons.mic_none),
        tooltip: widget.tooltip,
        onPressed: _toggle,
      ),
    };
  }
}
